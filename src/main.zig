const std = @import("std");
const day_one = @import("./day_one/day_one.zig");
const day_two = @import("./day_two/day_two.zig");
const day_three = @import("./day_three/day_three.zig");
const day_four = @import("./day_four/day_four.zig");
const day_five = @import("./day_five/day_five.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    try day_one.run(allocator);
    try day_two.run(allocator);
    try day_three.run(allocator);
    try day_four.run(allocator);
    try day_five.run(allocator);
}
