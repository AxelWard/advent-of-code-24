const std = @import("std");
const file = @import("../file-helpers.zig");

pub fn run(allocator: std.mem.Allocator) !void {
    std.debug.print("Running AoC Day 1...\n\n", .{});

    const buffer = try allocator.alloc(u8, 16384);
    defer allocator.free(buffer);
    const input_length = try file.readFileToBuffer("input/day1.txt", buffer);

    var lines = std.mem.splitSequence(u8, buffer[0..input_length], "\n");

    var first_list = std.ArrayList(i64).init(allocator);
    var second_list = std.ArrayList(i64).init(allocator);

    while (lines.next()) |line| {
        if (line.len != 0) {
            var line_chunks = std.mem.splitSequence(u8, line, "   ");

            try first_list.append(try std.fmt.parseInt(i64, line_chunks.first(), 10));
            try second_list.append(try std.fmt.parseInt(i64, line_chunks.next().?, 10));
        }
    }

    const first_array = try first_list.toOwnedSlice();
    const second_array = try second_list.toOwnedSlice();

    defer allocator.free(first_array);
    defer allocator.free(second_array);

    std.mem.sort(i64, first_array, {}, comptime std.sort.asc(i64));
    std.mem.sort(i64, second_array, {}, comptime std.sort.asc(i64));

    var diff: i64 = 0;
    var similarity: i64 = 0;

    var start_iter: usize = 0;

    for (0.., first_array) |index, element| {
        if (element < second_array[index]) {
            diff += second_array[index] - element;
        } else {
            diff += element - second_array[index];
        }

        var occurrences: i64 = 0;
        for (start_iter.., second_array) |second_index, second_element| {
            if (second_element == element) {
                occurrences += 1;
            } else if (second_element > element) {
                start_iter = second_index;
                break;
            }
        }

        similarity += element * occurrences;
    }

    std.debug.print("Total diff (solution part 1): {}\n", .{diff});
    std.debug.print("Total similarity (solution part 2): {}\n", .{similarity});
}
