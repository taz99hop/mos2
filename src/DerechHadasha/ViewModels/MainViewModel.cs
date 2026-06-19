using System.Collections.ObjectModel;
using System.Globalization;
using System.Windows;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using DerechHadasha.Models;
using DerechHadasha.Services;
using Microsoft.Win32;

namespace DerechHadasha.ViewModels;

public partial class MainViewModel : ObservableObject
{
    private readonly DatabaseService _database = DatabaseService.Instance;
    private readonly PdfReportService _pdf = new();
    private readonly ThemeService _theme = new();

    [ObservableProperty] private DashboardSummary summary = new();
    [ObservableProperty] private ObservableCollection<WorkEntry> entries = new();
    [ObservableProperty] private ObservableCollection<WorkEntry> recentEntries = new();
    [ObservableProperty] private ObservableCollection<ChartPoint> monthlyChart = new();
    [ObservableProperty] private ObservableCollection<ChartPoint> yearlyChart = new();
    [ObservableProperty] private WorkEntry currentEntry = new();
    [ObservableProperty] private WorkEntry? selectedEntry;
    [ObservableProperty] private string searchKeyword = string.Empty;
    [ObservableProperty] private DateTime? searchFromDate;
    [ObservableProperty] private DateTime? searchToDate;
    [ObservableProperty] private string selectedSearchShift = "הכול";
    [ObservableProperty] private DateTime reportFromDate = DateTime.Today;
    [ObservableProperty] private DateTime reportToDate = DateTime.Today;
    [ObservableProperty] private string statusMessage = "מוכן לעבודה";

    public IReadOnlyList<string> ShiftTypes { get; } = new[] { "בוקר", "לילה", "בוקר ולילה" };
    public IReadOnlyList<string> SearchShiftTypes { get; } = new[] { "הכול", "בוקר", "לילה", "בוקר ולילה" };

    public string TodayIncomeText => Summary.TodayIncome.ToString("C", CultureInfo.GetCultureInfo("he-IL"));
    public string WeekIncomeText => Summary.WeekIncome.ToString("C", CultureInfo.GetCultureInfo("he-IL"));
    public string MonthIncomeText => Summary.MonthIncome.ToString("C", CultureInfo.GetCultureInfo("he-IL"));
    public string YearIncomeText => Summary.YearIncome.ToString("C", CultureInfo.GetCultureInfo("he-IL"));
    public string AverageShiftText => Summary.AverageIncomePerShift.ToString("C", CultureInfo.GetCultureInfo("he-IL"));
    public string AverageDayText => Summary.AverageIncomePerDay.ToString("C", CultureInfo.GetCultureInfo("he-IL"));

    public async Task InitializeAsync() => await RefreshAsync();

    [RelayCommand]
    public async Task SaveEntryAsync()
    {
        if (CurrentEntry.IncomeAmount < 0 || CurrentEntry.HoursWorked < 0)
        {
            Show("הכנסה ושעות עבודה חייבות להיות חיוביות.", true);
            return;
        }
        await _database.SaveEntryAsync(CurrentEntry);
        CurrentEntry = new WorkEntry();
        SelectedEntry = null;
        Show("הרשומה נשמרה בהצלחה.");
        await RefreshAsync();
    }

    [RelayCommand]
    public void EditSelected()
    {
        if (SelectedEntry is null) return;
        CurrentEntry = new WorkEntry
        {
            Id = SelectedEntry.Id,
            WorkerName = SelectedEntry.WorkerName,
            Date = SelectedEntry.Date,
            ShiftType = SelectedEntry.ShiftType,
            IncomeAmount = SelectedEntry.IncomeAmount,
            HoursWorked = SelectedEntry.HoursWorked,
            Description = SelectedEntry.Description,
            Notes = SelectedEntry.Notes,
            ImagePath = SelectedEntry.ImagePath,
            CreatedAt = SelectedEntry.CreatedAt,
            UpdatedAt = SelectedEntry.UpdatedAt
        };
    }

    [RelayCommand]
    public async Task DeleteSelectedAsync()
    {
        if (SelectedEntry is null) return;
        if (MessageBox.Show("האם למחוק את הרשומה שנבחרה?", "מחיקה", MessageBoxButton.YesNo, MessageBoxImage.Question, MessageBoxResult.No, MessageBoxOptions.RtlReading | MessageBoxOptions.RightAlign) != MessageBoxResult.Yes) return;
        await _database.DeleteEntryAsync(SelectedEntry.Id);
        CurrentEntry = new WorkEntry();
        SelectedEntry = null;
        Show("הרשומה נמחקה.");
        await RefreshAsync();
    }


    [RelayCommand]
    public void SetToday()
    {
        CurrentEntry.Date = DateTime.Today;
        OnPropertyChanged(nameof(CurrentEntry));
        Show("התאריך עודכן להיום.");
    }

    [RelayCommand]
    public void SetMorningShift() => SetShift(ShiftType.Morning, "משמרת בוקר נבחרה.");

    [RelayCommand]
    public void SetNightShift() => SetShift(ShiftType.Night, "משמרת לילה נבחרה.");

    [RelayCommand]
    public void SetBothShifts() => SetShift(ShiftType.Both, "משמרת בוקר ולילה נבחרה.");

    [RelayCommand]
    public void ClearForm()
    {
        CurrentEntry = new WorkEntry();
        SelectedEntry = null;
        Show("הטופס נוקה ומוכן לרשומה חדשה.");
    }

    [RelayCommand]
    public void AttachImage()
    {
        var dialog = new OpenFileDialog { Title = "בחירת תמונה", Filter = "קבצי תמונה|*.jpg;*.jpeg;*.png;*.bmp;*.gif" };
        if (dialog.ShowDialog() == true)
        {
            CurrentEntry.ImagePath = _database.CopyAttachment(dialog.FileName);
            OnPropertyChanged(nameof(CurrentEntry));
            Show("התמונה צורפה לרשומה.");
        }
    }

    [RelayCommand]
    public async Task SearchAsync()
    {
        var shift = SelectedSearchShift switch { "בוקר" => ShiftType.Morning, "לילה" => ShiftType.Night, "בוקר ולילה" => ShiftType.Both, _ => (ShiftType?)null };
        Entries = new ObservableCollection<WorkEntry>(await _database.GetEntriesAsync(SearchFromDate, SearchToDate, SearchKeyword, shift));
        Show($"נמצאו {Entries.Count} רשומות.");
    }

    [RelayCommand]
    public async Task SetDailyReportAsync()
    {
        ReportFromDate = DateTime.Today;
        ReportToDate = DateTime.Today;
        await SearchReportRangeAsync();
    }

    [RelayCommand]
    public async Task SetWeeklyReportAsync()
    {
        ReportFromDate = DateTime.Today.AddDays(-((int)DateTime.Today.DayOfWeek));
        ReportToDate = DateTime.Today;
        await SearchReportRangeAsync();
    }

    [RelayCommand]
    public async Task SetMonthlyReportAsync()
    {
        ReportFromDate = new DateTime(DateTime.Today.Year, DateTime.Today.Month, 1);
        ReportToDate = DateTime.Today;
        await SearchReportRangeAsync();
    }

    [RelayCommand]
    public async Task SearchReportRangeAsync()
    {
        Entries = new ObservableCollection<WorkEntry>(await _database.GetEntriesAsync(ReportFromDate, ReportToDate));
        Show($"הדוח עודכן: {Entries.Count} רשומות.");
    }

    [RelayCommand]
    public async Task ExportPdfAsync()
    {
        var dialog = new SaveFileDialog { Title = "ייצוא PDF", Filter = "PDF|*.pdf", FileName = $"דוח דרך חדשה {DateTime.Now:yyyyMMdd}.pdf" };
        if (dialog.ShowDialog() == true)
        {
            var reportEntries = await _database.GetEntriesAsync(ReportFromDate, ReportToDate);
            _pdf.ExportReport(dialog.FileName, "דוח הכנסות ועבודה", reportEntries, ReportFromDate, ReportToDate);
            Show("קובץ PDF נוצר בהצלחה.");
        }
    }

    [RelayCommand]
    public async Task PrintReportAsync()
    {
        var temp = System.IO.Path.Combine(System.IO.Path.GetTempPath(), $"derech-hadasha-{Guid.NewGuid():N}.pdf");
        var reportEntries = await _database.GetEntriesAsync(ReportFromDate, ReportToDate);
        _pdf.ExportReport(temp, "דוח הכנסות ועבודה", reportEntries, ReportFromDate, ReportToDate);
        _pdf.PrintPdf(temp);
        Show("הדוח נשלח להדפסה.");
    }

    [RelayCommand]
    public void ExportBackup()
    {
        var dialog = new SaveFileDialog { Title = "ייצוא גיבוי", Filter = "SQLite DB|*.db", FileName = $"derech_hadasha_backup_{DateTime.Now:yyyyMMdd}.db" };
        if (dialog.ShowDialog() == true)
        {
            _database.ExportBackup(dialog.FileName);
            Show("הגיבוי נשמר בהצלחה.");
        }
    }

    [RelayCommand]
    public async Task RestoreBackupAsync()
    {
        var dialog = new OpenFileDialog { Title = "שחזור גיבוי", Filter = "SQLite DB|*.db;*.sqlite" };
        if (dialog.ShowDialog() == true)
        {
            await _database.RestoreBackupAsync(dialog.FileName);
            Show("הגיבוי שוחזר בהצלחה.");
            await RefreshAsync();
        }
    }

    [RelayCommand]
    public void ToggleTheme()
    {
        _theme.ToggleTheme();
        Show(_theme.IsDark ? "מצב כהה הופעל." : "מצב בהיר הופעל.");
    }

    [RelayCommand]
    public async Task RefreshAsync()
    {
        Summary = await _database.GetDashboardSummaryAsync();
        OnPropertyChanged(nameof(TodayIncomeText));
        OnPropertyChanged(nameof(WeekIncomeText));
        OnPropertyChanged(nameof(MonthIncomeText));
        OnPropertyChanged(nameof(YearIncomeText));
        OnPropertyChanged(nameof(AverageShiftText));
        OnPropertyChanged(nameof(AverageDayText));
        Entries = new ObservableCollection<WorkEntry>(await _database.GetEntriesAsync(limit: 250));
        RecentEntries = new ObservableCollection<WorkEntry>(await _database.GetEntriesAsync(limit: 8));
        await BuildChartsAsync();
    }


    private void SetShift(ShiftType shiftType, string message)
    {
        CurrentEntry.ShiftType = shiftType;
        OnPropertyChanged(nameof(CurrentEntry));
        Show(message);
    }

    private async Task BuildChartsAsync()
    {
        var yearStart = new DateTime(DateTime.Today.Year, 1, 1);
        var entries = await _database.GetEntriesAsync(yearStart, DateTime.Today);
        MonthlyChart = new ObservableCollection<ChartPoint>(Enumerable.Range(1, 12).Select(month => new ChartPoint(new DateTime(DateTime.Today.Year, month, 1).ToString("MMM", new CultureInfo("he-IL")), (double)entries.Where(x => x.Date.Month == month).Sum(x => x.IncomeAmount))));
        var fiveYearsAgo = new DateTime(DateTime.Today.Year - 4, 1, 1);
        var years = await _database.GetEntriesAsync(fiveYearsAgo, DateTime.Today);
        YearlyChart = new ObservableCollection<ChartPoint>(Enumerable.Range(DateTime.Today.Year - 4, 5).Select(year => new ChartPoint(year.ToString(), (double)years.Where(x => x.Date.Year == year).Sum(x => x.IncomeAmount))));
    }

    private void Show(string message, bool error = false)
    {
        StatusMessage = message;
        if (error) MessageBox.Show(message, "דרך חדשה", MessageBoxButton.OK, MessageBoxImage.Warning, MessageBoxResult.OK, MessageBoxOptions.RtlReading | MessageBoxOptions.RightAlign);
    }
}

public sealed record ChartPoint(string Label, double Value);
