const std = @import("std");
const day_one = @import("./day_one/day_one.zig");
const day_two = @import("./day_two/day_two.zig");
const day_three = @import("./day_three/day_three.zig");
const day_four = @import("./day_four/day_four.zig");
const day_five = @import("./day_five/day_five.zig");
const day_six = @import("./day_six/day_six.zig");
const day_seven = @import("./day_seven/day_seven.zig");
const day_eight = @import("./day_eight/day_eight.zig");
const day_nine = @import("./day_nine/day_nine.zig");
const day_ten = @import("./day_ten/day_ten.zig");
const day_eleven = @import("./day_eleven/day_eleven.zig");
const day_twelve = @import("./day_twelve/day_twelve.zig");
const day_thirteen = @import("./day_thirteen/day_thirteen.zig");
const day_fourteen = @import("./day_fourteen/day_fourteen.zig");
const day_fifteen = @import("./day_fifteen/day_fifteen.zig");
const day_sixteen = @import("./day_sixteen/day_sixteen.zig");
const day_seventeen = @import("./day_seventeen/day_seventeen.zig");
const day_eighteen = @import("./day_eighteen/day_eighteen.zig");
const day_nineteen = @import("./day_nineteen/day_nineteen.zig");
const day_twenty = @import("./day_twenty/day_twenty.zig");
const day_twentyone = @import("./day_twentyone/day_twentyone.zig");
const day_twentytwo = @import("./day_twentytwo/day_twentytwo.zig");
const day_twentythree = @import("./day_twentythree/day_twentythree.zig");
const day_twentyfour = @import("./day_twentyfour/day_twentyfour.zig");
const day_twentyfive = @import("./day_twentyfive/day_twentyfive.zig");

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
    std.debug.print("Running AoC Day {}...\n\n", .{day});

    switch (day) {
        1 => try day_one.run(allocator),
        2 => try day_two.run(allocator),
        3 => try day_three.run(allocator),
        4 => try day_four.run(allocator),
        5 => try day_five.run(allocator),
        6 => try day_six.run(allocator),
        7 => try day_seven.run(allocator),
        8 => try day_eight.run(allocator),
        9 => try day_nine.run(allocator),
        10 => try day_ten.run(allocator),
        11 => try day_eleven.run(allocator),
        12 => try day_twelve.run(allocator),
        13 => try day_thirteen.run(allocator),
        14 => try day_fourteen.run(allocator),
        15 => try day_fifteen.run(allocator),
        16 => try day_sixteen.run(allocator),
        17 => try day_seventeen.run(allocator),
        18 => try day_eighteen.run(allocator),
        19 => try day_nineteen.run(allocator),
        20 => try day_twenty.run(allocator),
        21 => try day_twentyone.run(allocator),
        22 => try day_twentytwo.run(allocator),
        23 => try day_twentythree.run(allocator),
        24 => try day_twentyfour.run(allocator),
        25 => try day_twentyfive.run(allocator),
        else => std.debug.print("Please input a number between 1 and 25\n", .{}),
    }
}
