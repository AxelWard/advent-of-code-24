const std = @import("std");
const file = @import("../file-helpers.zig");

pub fn run(allocator: std.mem.Allocator) !void {
    const buffer = try allocator.alloc(u8, 16384);
    defer allocator.free(buffer);
    const input_length = try file.readFileToBuffer("input/day23.txt", buffer);

    var lines = std.mem.splitSequence(u8, buffer[0..input_length], "\n");

    while (lines.next()) |line| {
        if (line.len == 0) continue;
    }
}
