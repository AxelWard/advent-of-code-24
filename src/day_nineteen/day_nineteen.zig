const std = @import("std");
const file = @import("../file-helpers.zig");

// Solution:
// Create a search tree where that allows a user to search the available designs

pub fn run(allocator: std.mem.Allocator) !void {
    const buffer = try allocator.alloc(u8, 20000);
    defer allocator.free(buffer);
    const input_length = try file.readFileToBuffer("input/day19_test.txt", buffer);

    var lines = std.mem.splitSequence(u8, buffer[0 .. input_length - 1], "\n");
    var patterns = std.mem.splitSequence(u8, lines.first(), " ");

    while (patterns.next()) |pattern| {
        try addPattern(pattern);
    }

    lines.next();
    var possible: usize = 0;
    while (lines.next()) |line| {
        if (line.len == 0) continue;

        possible += 1;
    }

    std.debug.print("Possible design count (part 1): {}\n", .{possible});
}

fn addPattern(pattern: []const u8) !void {
    if (pattern.len == 0) return;
}
