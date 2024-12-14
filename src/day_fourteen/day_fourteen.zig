const std = @import("std");
const readFileToBuffer = @import("../file-helpers.zig").readFileToBuffer;

const Point = @import("../Point.zig").Point;
const SECONDS_TO_SIMULATE: usize = 100;
const GRID_WIDTH: usize = 101;
const GRID_HEIGHT: usize = 103;

pub fn run(allocator: std.mem.Allocator) !void {
    const buffer = try allocator.alloc(u8, 20000);
    defer allocator.free(buffer);
    const input_length = try readFileToBuffer("input/day14.txt", buffer);

    var lines = std.mem.splitSequence(u8, buffer[0 .. input_length - 1], "\n");

    var final_bot_count = [4]usize{ 0, 0, 0, 0 };

    const grid_middle_x = ((GRID_WIDTH - 1) / 2);
    const grid_middle_y = ((GRID_HEIGHT - 1) / 2);

    var index: usize = 0;
    while (lines.next()) |line| : (index += 1) {
        if (line.len == 0) continue;
        var sides = std.mem.splitSequence(u8, line, " ");

        var position = Point{
            .x = 0,
            .y = 0,
        };
        if (sides.next()) |first| {
            var coords = std.mem.splitSequence(u8, first[2..], ",");
            position.x = try std.fmt.parseInt(i64, coords.first(), 10);
            if (coords.next()) |y_coord| {
                position.y = try std.fmt.parseInt(i64, y_coord, 10);
            }
        }

        var velocity = Point{
            .x = 0,
            .y = 0,
        };
        if (sides.next()) |first| {
            var coords = std.mem.splitSequence(u8, first[2..], ",");
            velocity.x = try std.fmt.parseInt(i64, coords.first(), 10);
            if (coords.next()) |y_coord| {
                velocity.y = try std.fmt.parseInt(i64, y_coord, 10);
            }
        }

        const final_x = @mod(position.x + (velocity.x * SECONDS_TO_SIMULATE), GRID_WIDTH);
        const final_y = @mod(position.y + (velocity.y * SECONDS_TO_SIMULATE), GRID_HEIGHT);

        if (final_x < grid_middle_x and final_y < grid_middle_y) {
            final_bot_count[0] += 1;
        } else if (final_x > grid_middle_x and final_y < grid_middle_y) {
            final_bot_count[1] += 1;
        } else if (final_x < grid_middle_x and final_y > grid_middle_y) {
            final_bot_count[2] += 1;
        } else if (final_x > grid_middle_x and final_y > grid_middle_y) {
            final_bot_count[3] += 1;
        }
    }

    var safety_factor: usize = 1;
    for (final_bot_count) |bot| safety_factor *= bot;

    std.debug.print("Final safety factor (part 1): {}\n", .{safety_factor});
}
