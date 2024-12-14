const std = @import("std");
const readFileToBuffer = @import("../file-helpers.zig").readFileToBuffer;
const progress = @import("../progress_logger.zig");

const Point = @import("../Point.zig").Point;

const SECONDS_TO_SIMULATE: usize = 100;
const MAX_SECONDS_TO_SIMULATE: usize = 1000000;
const GRID_WIDTH: usize = 101;
const GRID_HEIGHT: usize = 103;

const Bot = struct {
    position: Point,
    velocity: Point,
};

pub fn run(allocator: std.mem.Allocator) !void {
    const buffer = try allocator.alloc(u8, 20000);
    defer allocator.free(buffer);
    const input_length = try readFileToBuffer("input/day14.txt", buffer);

    var lines = std.mem.splitSequence(u8, buffer[0 .. input_length - 1], "\n");
    var bot_list = std.ArrayList(Bot).init(allocator);

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

        try bot_list.append(Bot{
            .position = position,
            .velocity = velocity,
        });
    }

    const bots = try bot_list.toOwnedSlice();
    const safety_factor = calculateSafteyFactor(bots);

    std.debug.print("Final safety factor (part 1): {}\n", .{safety_factor});

    std.debug.print("Simulating Bots... ", .{});
    progress.logProgressStart();

    var check: usize = 0;
    var bot_image = try allocator.alloc(u1, GRID_WIDTH * GRID_HEIGHT);

    while (check < MAX_SECONDS_TO_SIMULATE) : (check += 1) {
        if (checkForBotTree(bot_image)) {
            break;
        }

        for (0..bot_image.len) |img_index| bot_image[img_index] = 0;
        for (bots) |*bot| {
            bot.position = Point{
                .x = @mod(bot.position.x + bot.velocity.x, GRID_WIDTH),
                .y = @mod(bot.position.y + bot.velocity.y, GRID_HEIGHT),
            };

            bot_image[@as(usize, @intCast(bot.position.y * GRID_WIDTH + bot.position.x))] = 1;
        }

        progress.logProgress(check, MAX_SECONDS_TO_SIMULATE);
    }

    progress.logProgress(MAX_SECONDS_TO_SIMULATE, MAX_SECONDS_TO_SIMULATE);
    std.debug.print("\n\n-------------------\n\n", .{});
    for (0..GRID_HEIGHT) |y_index| {
        for (0..GRID_WIDTH) |x_index| {
            if (bot_image[y_index * GRID_WIDTH + x_index] == 1) {
                std.debug.print("*", .{});
            } else {
                std.debug.print(" ", .{});
            }
        }

        std.debug.print("\n", .{});
    }
    std.debug.print("\n\n-------------------\n\n", .{});
    std.debug.print("\nFound christmas tree at frame (part 2): {}\n", .{check});
}

pub fn calculateSafteyFactor(bots: []const Bot) usize {
    var final_bot_count = [4]usize{ 0, 0, 0, 0 };

    const grid_middle_x = ((GRID_WIDTH - 1) / 2);
    const grid_middle_y = ((GRID_HEIGHT - 1) / 2);

    for (bots) |bot| {
        const final_x = @mod(bot.position.x + (bot.velocity.x * SECONDS_TO_SIMULATE), GRID_WIDTH);
        const final_y = @mod(bot.position.y + (bot.velocity.y * SECONDS_TO_SIMULATE), GRID_HEIGHT);

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
    return safety_factor;
}

pub fn checkForBotTree(bot_image: []const u1) bool {
    // Border check method
    for (0..GRID_HEIGHT - 25) |y_index| {
        for (0..GRID_WIDTH - 25) |x_index| {
            const start_index = y_index * GRID_WIDTH + x_index;
            var cont = false;
            for (bot_image[start_index .. start_index + 25]) |pixel| {
                if (pixel == 0) {
                    cont = true;
                    break;
                }
            }

            if (cont) continue;

            var next_index = start_index;
            while (next_index < start_index + (25 * GRID_WIDTH)) {
                if (bot_image[next_index] == 0) {
                    cont = true;
                    break;
                }
                next_index += GRID_WIDTH;
            }

            if (cont) continue;
            return true;
        }
    }

    return false;
}
