using System.Globalization;
using System.Windows.Data;

namespace DerechHadasha.Converters;

public sealed class NumberToHeightConverter : IValueConverter
{
    public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
    {
        var number = System.Convert.ToDouble(value, CultureInfo.InvariantCulture);
        var max = parameter is null ? 220d : System.Convert.ToDouble(parameter, CultureInfo.InvariantCulture);
        return Math.Max(4, Math.Min(max, number / 1000d * max));
    }
    public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture) => Binding.DoNothing;
}
