using System.Windows;
using DerechHadasha.ViewModels;

namespace DerechHadasha;

public partial class MainWindow : Window
{
    private readonly MainViewModel _viewModel = new();

    public MainWindow()
    {
        InitializeComponent();
        DataContext = _viewModel;
        Loaded += async (_, _) => await _viewModel.InitializeAsync();
    }
}
