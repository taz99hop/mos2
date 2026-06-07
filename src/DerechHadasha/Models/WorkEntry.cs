namespace DerechHadasha.Models;

public enum ShiftType
{
    Morning,
    Night
}

public sealed class WorkEntry
{
    public int Id { get; set; }
    public DateTime Date { get; set; } = DateTime.Today;
    public ShiftType ShiftType { get; set; } = ShiftType.Morning;
    public decimal IncomeAmount { get; set; }
    public double HoursWorked { get; set; }
    public string Description { get; set; } = string.Empty;
    public string Notes { get; set; } = string.Empty;
    public string? ImagePath { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.Now;
    public DateTime UpdatedAt { get; set; } = DateTime.Now;
    public string ShiftTypeHebrew => ShiftType == ShiftType.Morning ? "בוקר" : "לילה";
}
