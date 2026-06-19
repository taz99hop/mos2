using System.Diagnostics;
using System.Globalization;
using DerechHadasha.Models;
using PdfSharpCore.Drawing;
using PdfSharpCore.Pdf;

namespace DerechHadasha.Services;

public sealed class PdfReportService
{
    private const string CompanyName = "דרך חדשה";
    private const string Footer = "נוצר על ידי חמודה חאלד";
    public void ExportReport(string filePath, string title, IReadOnlyList<WorkEntry> entries, DateTime from, DateTime to)
    {
        using var document = new PdfDocument();
        document.Info.Title = title;
        var page = document.AddPage();
        var gfx = XGraphics.FromPdfPage(page);
        var fonts = new Fonts();
        var y = DrawHeader(gfx, page, fonts, title, from, to);
        DrawSummary(gfx, page, fonts, entries, ref y);
        DrawTableHeader(gfx, page, fonts, ref y);

        foreach (var entry in entries)
        {
            if (y > page.Height - 90)
            {
                DrawFooter(gfx, page, fonts, document.PageCount);
                page = document.AddPage();
                gfx = XGraphics.FromPdfPage(page);
                y = DrawHeader(gfx, page, fonts, title, from, to);
                DrawTableHeader(gfx, page, fonts, ref y);
            }
            DrawRow(gfx, page, fonts, entry, ref y);
        }
        DrawFooter(gfx, page, fonts, document.PageCount);
        for (var i = 0; i < document.Pages.Count; i++)
        {
            using var pageGfx = XGraphics.FromPdfPage(document.Pages[i], XGraphicsPdfPageOptions.Append);
            pageGfx.DrawString($"עמוד {i + 1} מתוך {document.Pages.Count}", fonts.Small, XBrushes.Gray, new XRect(40, page.Height - 42, page.Width - 80, 18), XStringFormats.Center);
        }
        document.Save(filePath);
    }

    public void PrintPdf(string pdfPath) => Process.Start(new ProcessStartInfo(pdfPath) { UseShellExecute = true, Verb = "print" });

    private double DrawHeader(XGraphics gfx, PdfPage page, Fonts fonts, string title, DateTime from, DateTime to)
    {
        DrawVectorLogo(gfx, page.Width - 130, 24, 80, 80);
        gfx.DrawString(CompanyName, fonts.Title, XBrushes.DarkBlue, new XRect(40, 32, page.Width - 170, 34), XStringFormats.TopRight);
        gfx.DrawString(title, fonts.Heading, XBrushes.Black, new XRect(40, 72, page.Width - 170, 30), XStringFormats.TopRight);
        gfx.DrawString($"טווח תאריכים: {from:dd/MM/yyyy} - {to:dd/MM/yyyy}", fonts.Normal, XBrushes.DimGray, new XRect(40, 108, page.Width - 80, 24), XStringFormats.TopRight);
        gfx.DrawLine(XPens.LightGray, 40, 136, page.Width - 40, 136);
        return 156;
    }

    private static void DrawVectorLogo(XGraphics gfx, double x, double y, double width, double height)
    {
        static XPen Pen(int r, int g, int b) => new(XColor.FromArgb(r, g, b), 9);
        var scaleX = width / 160d;
        var scaleY = height / 160d;
        XPoint Point(double px, double py) => new(x + px * scaleX, y + py * scaleY);

        gfx.DrawLine(Pen(255, 91, 0), Point(20, 40), Point(45, 112));
        gfx.DrawLine(Pen(251, 191, 36), Point(45, 112), Point(77, 25));
        gfx.DrawLine(Pen(0, 176, 80), Point(77, 25), Point(112, 112));
        gfx.DrawLine(Pen(14, 165, 233), Point(112, 112), Point(140, 40));
        gfx.DrawString("דרך חדשה", new XFont("Arial", 9, XFontStyle.Bold), new XSolidBrush(XColor.FromArgb(22, 33, 62)), new XRect(x, y + height - 18, width, 14), XStringFormats.Center);
    }

    private static void DrawSummary(XGraphics gfx, PdfPage page, Fonts fonts, IReadOnlyList<WorkEntry> entries, ref double y)
    {
        var total = entries.Sum(x => x.IncomeAmount);
        var hours = entries.Sum(x => x.HoursWorked);
        var shiftCount = entries.Sum(x => x.ShiftUnits);
        var avgShift = shiftCount == 0 ? 0 : total / shiftCount;
        gfx.DrawRoundedRectangle(new XSolidBrush(XColor.FromArgb(245, 247, 251)), 40, y, page.Width - 80, 72, 8, 8);
        gfx.DrawString($"סה״כ הכנסות: {total.ToString("C", CultureInfo.GetCultureInfo("he-IL"))}", fonts.Bold, XBrushes.Black, new XRect(60, y + 12, page.Width - 120, 20), XStringFormats.TopRight);
        gfx.DrawString($"מספר משמרות: {shiftCount}   |   שעות עבודה: {hours:N1}   |   ממוצע למשמרת: {avgShift.ToString("C", CultureInfo.GetCultureInfo("he-IL"))}", fonts.Normal, XBrushes.DimGray, new XRect(60, y + 40, page.Width - 120, 20), XStringFormats.TopRight);
        y += 92;
    }

    private static void DrawTableHeader(XGraphics gfx, PdfPage page, Fonts fonts, ref double y)
    {
        gfx.DrawRectangle(new XSolidBrush(XColor.FromArgb(14, 165, 233)), 40, y, page.Width - 80, 28);
        var headers = new[] { "הערות", "מה עשינו היום", "שעות", "הכנסה", "משמרת", "עובד", "תאריך" };
        var widths = new[] { 60d, 115d, 40d, 65d, 60d, 65d, 70d };
        var x = 40d;
        for (var i = 0; i < headers.Length; i++)
        {
            gfx.DrawString(headers[i], fonts.TableHeader, XBrushes.White, new XRect(x + 4, y + 6, widths[i] - 8, 18), XStringFormats.TopRight);
            x += widths[i];
        }
        y += 32;
    }

    private static void DrawRow(XGraphics gfx, PdfPage page, Fonts fonts, WorkEntry entry, ref double y)
    {
        var widths = new[] { 60d, 115d, 40d, 65d, 60d, 65d, 70d };
        var values = new[]
        {
            Truncate(entry.Notes, 20), Truncate(entry.Description, 36), entry.HoursWorked.ToString("N1"),
            entry.IncomeAmount.ToString("C0", CultureInfo.GetCultureInfo("he-IL")), entry.ShiftTypeHebrew,
            Truncate(entry.WorkerName, 18), entry.Date.ToString("dd/MM/yyyy")
        };
        gfx.DrawRectangle(XPens.LightGray, 40, y, page.Width - 80, 26);
        var x = 40d;
        for (var i = 0; i < values.Length; i++)
        {
            gfx.DrawString(values[i], fonts.Small, XBrushes.Black, new XRect(x + 4, y + 7, widths[i] - 8, 14), XStringFormats.TopRight);
            x += widths[i];
        }
        y += 26;
    }

    private static void DrawFooter(XGraphics gfx, PdfPage page, Fonts fonts, int pageNumber)
    {
        gfx.DrawLine(XPens.LightGray, 40, page.Height - 58, page.Width - 40, page.Height - 58);
        gfx.DrawString(Footer, fonts.Small, XBrushes.Gray, new XRect(40, page.Height - 28, page.Width - 80, 16), XStringFormats.Center);
    }

    private static string Truncate(string value, int length) => value.Length <= length ? value : value[..Math.Max(0, length - 1)] + "…";

    private sealed class Fonts
    {
        public XFont Title { get; } = new("Arial", 24, XFontStyle.Bold);
        public XFont Heading { get; } = new("Arial", 16, XFontStyle.Bold);
        public XFont Normal { get; } = new("Arial", 10, XFontStyle.Regular);
        public XFont Bold { get; } = new("Arial", 11, XFontStyle.Bold);
        public XFont Small { get; } = new("Arial", 8, XFontStyle.Regular);
        public XFont TableHeader { get; } = new("Arial", 9, XFontStyle.Bold);
    }
}
