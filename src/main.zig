const std = @import("std");
const day_one = @import("./day_one/day_one.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    try day_one.run(allocator);
}
