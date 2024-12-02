const std = @import("std");

pub fn readFileToBuffer(filePath: []const u8, buffer: []u8) !usize {
    const file = try std.fs.cwd().openFile(filePath, .{});
    defer file.close();

    return try file.reader().readAll(buffer);
}
