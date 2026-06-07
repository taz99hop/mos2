using System.Globalization;
using System.Windows.Data;
using DerechHadasha.Models;

namespace DerechHadasha.Converters;

public sealed class ShiftTypeConverter : IValueConverter
{
    public object Convert(object value, Type targetType, object parameter, CultureInfo culture) => value is ShiftType shift && shift == ShiftType.Night ? "לילה" : "בוקר";
    public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture) => value?.ToString() == "לילה" ? ShiftType.Night : ShiftType.Morning;
}
