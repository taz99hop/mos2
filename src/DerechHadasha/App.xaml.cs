using System.Globalization;
using System.Windows;
using DerechHadasha.Services;

namespace DerechHadasha;

public partial class App : Application
{
    protected override async void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);
        CultureInfo.DefaultThreadCurrentCulture = new CultureInfo("he-IL");
        CultureInfo.DefaultThreadCurrentUICulture = new CultureInfo("he-IL");
        DispatcherUnhandledException += (_, args) =>
        {
            MessageBox.Show($"אירעה שגיאה בלתי צפויה:\n{args.Exception.Message}", "שגיאה", MessageBoxButton.OK, MessageBoxImage.Error, MessageBoxResult.OK, MessageBoxOptions.RtlReading | MessageBoxOptions.RightAlign);
            args.Handled = true;
        };
        await DatabaseService.Instance.InitializeAsync();
    }
}
