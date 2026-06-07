namespace DerechHadasha.Models;

public sealed class DashboardSummary
{
    public decimal TodayIncome { get; set; }
    public decimal WeekIncome { get; set; }
    public decimal MonthIncome { get; set; }
    public decimal YearIncome { get; set; }
    public int ShiftCount { get; set; }
    public decimal AverageIncomePerShift { get; set; }
    public decimal AverageIncomePerDay { get; set; }
}
