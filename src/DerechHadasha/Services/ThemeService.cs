using System.Windows;

namespace DerechHadasha.Services;

public sealed class ThemeService
{
    public bool IsDark { get; private set; }

    public void ToggleTheme()
    {
        IsDark = !IsDark;
        var dictionary = new ResourceDictionary { Source = new Uri(IsDark ? "Themes/Dark.xaml" : "Themes/Light.xaml", UriKind.Relative) };
        Application.Current.Resources.MergedDictionaries.Clear();
        Application.Current.Resources.MergedDictionaries.Add(dictionary);
    }
}
