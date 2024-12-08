const std = @import("std");
const day_one = @import("./day_one/day_one.zig");
const day_two = @import("./day_two/day_two.zig");
const day_three = @import("./day_three/day_three.zig");
const day_four = @import("./day_four/day_four.zig");
const day_five = @import("./day_five/day_five.zig");
const day_six = @import("./day_six/day_six.zig");
const day_seven = @import("./day_seven/day_seven.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var args_iterator = try std.process.ArgIterator.initWithAllocator(allocator);
    defer args_iterator.deinit();

    _ = args_iterator.next();
    if (args_iterator.next()) |input_arg| {
        const day_selection = std.fmt.parseInt(u8, input_arg, 10) catch {
            std.debug.print("Please input a number between 1 and 25\n", .{});
            return;
        };

        if (day_selection == 0 or day_selection > 25) {
            std.debug.print("Please input a number between 1 and 25\n", .{});
            return;
        }

        try run_day(day_selection, allocator);
    } else {
        std.debug.print("Please input a number between 1 and 25\n", .{});
    }
}

fn run_day(day: u8, allocator: std.mem.Allocator) !void {
    switch (day) {
        1 => try day_one.run(allocator),
        2 => try day_two.run(allocator),
        3 => try day_three.run(allocator),
        4 => try day_four.run(allocator),
        5 => try day_five.run(allocator),
        6 => try day_six.run(allocator),
        7 => try day_seven.run(allocator),
        else => std.debug.print("Day not implemented yet!\n", .{}),
    }
}
