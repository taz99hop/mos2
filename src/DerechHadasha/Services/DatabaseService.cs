using System.IO;
using DerechHadasha.Models;
using Microsoft.Data.Sqlite;

namespace DerechHadasha.Services;

public sealed class DatabaseService
{
    public static DatabaseService Instance { get; } = new();
    public string AppFolder { get; } = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "DerechHadasha");
    public string AttachmentsFolder => Path.Combine(AppFolder, "Attachments");
    public string DatabasePath => Path.Combine(AppFolder, "derech_hadasha.db");
    private string ConnectionString => new SqliteConnectionStringBuilder { DataSource = DatabasePath }.ToString();

    private DatabaseService() { }

    public async Task InitializeAsync()
    {
        Directory.CreateDirectory(AppFolder);
        Directory.CreateDirectory(AttachmentsFolder);
        await using var connection = new SqliteConnection(ConnectionString);
        await connection.OpenAsync();
        var command = connection.CreateCommand();
        command.CommandText = """
        CREATE TABLE IF NOT EXISTS work_entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            shift_type TEXT NOT NULL CHECK(shift_type IN ('Morning','Night')),
            income_amount REAL NOT NULL DEFAULT 0,
            hours_worked REAL NOT NULL DEFAULT 0,
            description TEXT NOT NULL DEFAULT '',
            notes TEXT NOT NULL DEFAULT '',
            image_path TEXT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
        );
        CREATE INDEX IF NOT EXISTS idx_work_entries_date ON work_entries(date);
        CREATE INDEX IF NOT EXISTS idx_work_entries_shift_type ON work_entries(shift_type);
        CREATE VIRTUAL TABLE IF NOT EXISTS work_entries_fts USING fts5(description, notes, content='work_entries', content_rowid='id');
        CREATE TRIGGER IF NOT EXISTS work_entries_ai AFTER INSERT ON work_entries BEGIN
            INSERT INTO work_entries_fts(rowid, description, notes) VALUES (new.id, new.description, new.notes);
        END;
        CREATE TRIGGER IF NOT EXISTS work_entries_ad AFTER DELETE ON work_entries BEGIN
            INSERT INTO work_entries_fts(work_entries_fts, rowid, description, notes) VALUES('delete', old.id, old.description, old.notes);
        END;
        CREATE TRIGGER IF NOT EXISTS work_entries_au AFTER UPDATE ON work_entries BEGIN
            INSERT INTO work_entries_fts(work_entries_fts, rowid, description, notes) VALUES('delete', old.id, old.description, old.notes);
            INSERT INTO work_entries_fts(rowid, description, notes) VALUES (new.id, new.description, new.notes);
        END;
        """;
        await command.ExecuteNonQueryAsync();
    }

    public async Task<IReadOnlyList<WorkEntry>> GetEntriesAsync(DateTime? from = null, DateTime? to = null, string? keyword = null, ShiftType? shiftType = null, int? limit = null)
    {
        await using var connection = new SqliteConnection(ConnectionString);
        await connection.OpenAsync();
        var conditions = new List<string>();
        var command = connection.CreateCommand();
        if (from is not null) { conditions.Add("date >= $from"); command.Parameters.AddWithValue("$from", from.Value.Date.ToString("yyyy-MM-dd")); }
        if (to is not null) { conditions.Add("date <= $to"); command.Parameters.AddWithValue("$to", to.Value.Date.ToString("yyyy-MM-dd")); }
        if (shiftType is not null) { conditions.Add("shift_type = $shift"); command.Parameters.AddWithValue("$shift", shiftType.Value.ToString()); }
        if (!string.IsNullOrWhiteSpace(keyword))
        {
            conditions.Add("id IN (SELECT rowid FROM work_entries_fts WHERE work_entries_fts MATCH $keyword) OR description LIKE $like OR notes LIKE $like");
            command.Parameters.AddWithValue("$keyword", EscapeFts(keyword));
            command.Parameters.AddWithValue("$like", $"%{keyword}%");
        }
        var where = conditions.Count == 0 ? string.Empty : "WHERE " + string.Join(" AND ", conditions.Select(c => $"({c})"));
        command.CommandText = $"SELECT * FROM work_entries {where} ORDER BY date DESC, id DESC" + (limit is null ? string.Empty : " LIMIT $limit");
        if (limit is not null) command.Parameters.AddWithValue("$limit", limit.Value);
        var entries = new List<WorkEntry>();
        await using var reader = await command.ExecuteReaderAsync();
        while (await reader.ReadAsync()) entries.Add(Map(reader));
        return entries;
    }

    public async Task SaveEntryAsync(WorkEntry entry)
    {
        entry.UpdatedAt = DateTime.Now;
        await using var connection = new SqliteConnection(ConnectionString);
        await connection.OpenAsync();
        var command = connection.CreateCommand();
        if (entry.Id == 0)
        {
            entry.CreatedAt = DateTime.Now;
            command.CommandText = """
            INSERT INTO work_entries(date, shift_type, income_amount, hours_worked, description, notes, image_path, created_at, updated_at)
            VALUES($date, $shift, $income, $hours, $description, $notes, $image, $created, $updated);
            SELECT last_insert_rowid();
            """;
        }
        else
        {
            command.CommandText = """
            UPDATE work_entries SET date=$date, shift_type=$shift, income_amount=$income, hours_worked=$hours,
                description=$description, notes=$notes, image_path=$image, updated_at=$updated
            WHERE id=$id;
            SELECT $id;
            """;
            command.Parameters.AddWithValue("$id", entry.Id);
        }
        AddEntryParameters(command, entry);
        entry.Id = Convert.ToInt32(await command.ExecuteScalarAsync());
    }

    public async Task DeleteEntryAsync(int id)
    {
        await using var connection = new SqliteConnection(ConnectionString);
        await connection.OpenAsync();
        var command = connection.CreateCommand();
        command.CommandText = "DELETE FROM work_entries WHERE id=$id";
        command.Parameters.AddWithValue("$id", id);
        await command.ExecuteNonQueryAsync();
    }

    public async Task<DashboardSummary> GetDashboardSummaryAsync()
    {
        var today = DateTime.Today;
        var weekStart = today.AddDays(-((int)today.DayOfWeek));
        var monthStart = new DateTime(today.Year, today.Month, 1);
        var yearStart = new DateTime(today.Year, 1, 1);
        var all = await GetEntriesAsync(yearStart, today);
        var workDays = all.Select(x => x.Date.Date).Distinct().Count();
        return new DashboardSummary
        {
            TodayIncome = all.Where(x => x.Date.Date == today).Sum(x => x.IncomeAmount),
            WeekIncome = all.Where(x => x.Date.Date >= weekStart).Sum(x => x.IncomeAmount),
            MonthIncome = all.Where(x => x.Date.Date >= monthStart).Sum(x => x.IncomeAmount),
            YearIncome = all.Sum(x => x.IncomeAmount),
            ShiftCount = all.Count,
            AverageIncomePerShift = all.Count == 0 ? 0 : all.Sum(x => x.IncomeAmount) / all.Count,
            AverageIncomePerDay = workDays == 0 ? 0 : all.Sum(x => x.IncomeAmount) / workDays
        };
    }

    public void ExportBackup(string destinationPath) => File.Copy(DatabasePath, destinationPath, true);

    public async Task RestoreBackupAsync(string sourcePath)
    {
        await using (var connection = new SqliteConnection($"Data Source={sourcePath};Mode=ReadOnly"))
        {
            await connection.OpenAsync();
        }
        File.Copy(sourcePath, DatabasePath, true);
        await InitializeAsync();
    }

    public string CopyAttachment(string sourcePath)
    {
        Directory.CreateDirectory(AttachmentsFolder);
        var extension = Path.GetExtension(sourcePath);
        var destination = Path.Combine(AttachmentsFolder, $"{Guid.NewGuid():N}{extension}");
        File.Copy(sourcePath, destination, true);
        return destination;
    }

    private static void AddEntryParameters(SqliteCommand command, WorkEntry entry)
    {
        command.Parameters.AddWithValue("$date", entry.Date.Date.ToString("yyyy-MM-dd"));
        command.Parameters.AddWithValue("$shift", entry.ShiftType.ToString());
        command.Parameters.AddWithValue("$income", entry.IncomeAmount);
        command.Parameters.AddWithValue("$hours", entry.HoursWorked);
        command.Parameters.AddWithValue("$description", entry.Description);
        command.Parameters.AddWithValue("$notes", entry.Notes);
        command.Parameters.AddWithValue("$image", (object?)entry.ImagePath ?? DBNull.Value);
        command.Parameters.AddWithValue("$created", entry.CreatedAt.ToString("O"));
        command.Parameters.AddWithValue("$updated", entry.UpdatedAt.ToString("O"));
    }

    private static WorkEntry Map(SqliteDataReader reader) => new()
    {
        Id = reader.GetInt32(reader.GetOrdinal("id")),
        Date = DateTime.Parse(reader.GetString(reader.GetOrdinal("date"))),
        ShiftType = Enum.Parse<ShiftType>(reader.GetString(reader.GetOrdinal("shift_type"))),
        IncomeAmount = Convert.ToDecimal(reader.GetDouble(reader.GetOrdinal("income_amount"))),
        HoursWorked = reader.GetDouble(reader.GetOrdinal("hours_worked")),
        Description = reader.GetString(reader.GetOrdinal("description")),
        Notes = reader.GetString(reader.GetOrdinal("notes")),
        ImagePath = reader.IsDBNull(reader.GetOrdinal("image_path")) ? null : reader.GetString(reader.GetOrdinal("image_path")),
        CreatedAt = DateTime.Parse(reader.GetString(reader.GetOrdinal("created_at"))),
        UpdatedAt = DateTime.Parse(reader.GetString(reader.GetOrdinal("updated_at")))
    };

    private static string EscapeFts(string keyword) => string.Join(' ', keyword.Split(' ', StringSplitOptions.RemoveEmptyEntries).Select(x => $"\"{x.Replace("\"", "\"\"")}\""));
}
