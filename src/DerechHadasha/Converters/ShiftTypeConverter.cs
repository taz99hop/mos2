using System.Globalization;
using System.Windows.Data;
using DerechHadasha.Models;

namespace DerechHadasha.Converters;

public sealed class ShiftTypeConverter : IValueConverter
{
    public object Convert(object value, Type targetType, object parameter, CultureInfo culture) => value is ShiftType shift ? ToHebrew(shift) : "בוקר";

    public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture) => value?.ToString() switch
    {
        "לילה" => ShiftType.Night,
        "בוקר ולילה" => ShiftType.Both,
        _ => ShiftType.Morning
    };

    private static string ToHebrew(ShiftType shift) => shift switch
    {
        ShiftType.Morning => "בוקר",
        ShiftType.Night => "לילה",
        ShiftType.Both => "בוקר ולילה",
        _ => "בוקר"
    };
}
