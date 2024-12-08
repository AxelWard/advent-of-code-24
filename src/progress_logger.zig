const std = @import("std");

pub fn logProgressStart() void {
    std.debug.print("Progress: 000.00%", .{});
}

pub fn logProgress(current: usize, total: usize) void {
    std.debug.print(
        "\x08\x08\x08\x08\x08\x08\x08{d:0>6.2}%",
        .{(@as(f32, @floatFromInt(current)) / @as(f32, @floatFromInt(total))) * 100},
    );
}
