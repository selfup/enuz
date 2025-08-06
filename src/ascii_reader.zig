const std = @import("std");

const AsciiEntry = struct {
    dec: []const u8,
    hex: []const u8,
    binary: []const u8,
    html: []const u8,
    char: []const u8,
    description: []const u8,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const file = try std.fs.cwd().openFile("ascii.csv", .{});
    defer file.close();

    const file_stat = try file.stat();
    const file_size = file_stat.size;

    const file_content = try file.readToEndAlloc(allocator, file_size);
    defer allocator.free(file_content);

    var entries = std.ArrayList(AsciiEntry).init(allocator);
    defer entries.deinit();

    var lines = std.mem.tokenizeScalar(u8, file_content, '\n');

    // skip header line
    _ = lines.next();

    while (lines.next()) |line| {
        var fields = std.ArrayList([]const u8).init(allocator);
        defer fields.deinit();

        var field_iter = std.mem.tokenizeScalar(u8, line, ',');
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

    const stdout = std.io.getStdOut().writer();

    try stdout.print("ASCII Table - Dec and Description\n", .{});
    try stdout.print("==================================\n", .{});

    for (entries.items) |entry| {
        try stdout.print("Dec: {s:3} - Description: {s}\n", .{ entry.dec, entry.description });
    }
}
