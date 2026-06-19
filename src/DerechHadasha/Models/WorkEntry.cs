namespace DerechHadasha.Models;

public enum ShiftType
{
    Morning,
    Night,
    Both
}

public sealed class WorkEntry
{
    public int Id { get; set; }
    public string WorkerName { get; set; } = string.Empty;
    public DateTime Date { get; set; } = DateTime.Today;
    public ShiftType ShiftType { get; set; } = ShiftType.Morning;
    public decimal IncomeAmount { get; set; }
    public double HoursWorked { get; set; }
    public string Description { get; set; } = string.Empty;
    public string Notes { get; set; } = string.Empty;
    public string? ImagePath { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.Now;
    public DateTime UpdatedAt { get; set; } = DateTime.Now;
    public int ShiftUnits => ShiftType == ShiftType.Both ? 2 : 1;

    public string ShiftTypeHebrew => ShiftType switch
    {
        ShiftType.Morning => "בוקר",
        ShiftType.Night => "לילה",
        ShiftType.Both => "בוקר ולילה",
        _ => "בוקר"
    };
}
