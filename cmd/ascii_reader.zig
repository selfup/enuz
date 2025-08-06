const std = @import("std");

const LINE_DELIMITER: u8 = '\n';
const FIELD_DELIMITER: u8 = ',';
const CSV_FILE: []const u8 = "data/ascii.csv";

const AsciiEntry = struct {
    dec: []const u8,
    hex: []const u8,
    binary: []const u8,
    html: []const u8,
    char: []const u8,
    description: []const u8,
};

fn readCsv(allocator: std.mem.Allocator) ![]u8 {
    const file = try std.fs.cwd().openFile(CSV_FILE, .{});
    defer file.close();

    const file_stat = try file.stat();
    const file_size = file_stat.size;

    return try file.readToEndAlloc(allocator, file_size);
}

fn parseCsv(allocator: std.mem.Allocator, file_content: []const u8) !std.ArrayList(AsciiEntry) {
    var entries = std.ArrayList(AsciiEntry).init(allocator);
    errdefer entries.deinit();

    var lines = std.mem.tokenizeScalar(u8, file_content, LINE_DELIMITER);

    // skip header line
    _ = lines.next();

    while (lines.next()) |line| {
        var fields = std.ArrayList([]const u8).init(allocator);
        defer fields.deinit();

        var field_iter = std.mem.tokenizeScalar(u8, line, FIELD_DELIMITER);
        while (field_iter.next()) |field| {
            try fields.append(field);
        }

        if (fields.items.len == 6) {
            const entry = AsciiEntry{
                .dec = fields.items[0],
                .hex = fields.items[1],
                .binary = fields.items[2],
                .html = fields.items[3],
                .char = fields.items[4],
                .description = fields.items[5],
            };

            try entries.append(entry);
        }
    }

    return entries;
}

fn printAsciiTable(entries: std.ArrayList(AsciiEntry)) !void {
    const stdout = std.io.getStdOut().writer();

    try stdout.print("ASCII Table - Dec and Description\n", .{});
    try stdout.print("==================================\n", .{});

    for (entries.items) |entry| {
        try stdout.print("Dec: {s:3} - Description: {s}\n", .{ entry.dec, entry.description });
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    const file_content = try readCsv(allocator);
    defer allocator.free(file_content);

    var entries = try parseCsv(allocator, file_content);
    defer entries.deinit();

    try printAsciiTable(entries);
}
