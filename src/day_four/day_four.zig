const std = @import("std");
const file = @import("../file-helpers.zig");

const Direction = struct { direction_mask: u8, x: i2, y: i2 };

const UP_LEFT = Direction{ .direction_mask = 0b10000000, .x = -1, .y = -1 };
const UP = Direction{ .direction_mask = 0b01000000, .x = 0, .y = -1 };
const UP_RIGHT = Direction{ .direction_mask = 0b00100000, .x = 1, .y = -1 };
const RIGHT = Direction{ .direction_mask = 0b00010000, .x = 1, .y = 0 };
const DOWN_RIGHT = Direction{ .direction_mask = 0b00001000, .x = 1, .y = 1 };
const DOWN = Direction{ .direction_mask = 0b00000100, .x = 0, .y = 1 };
const DOWN_LEFT = Direction{ .direction_mask = 0b00000010, .x = -1, .y = 1 };
const LEFT = Direction{ .direction_mask = 0b00000001, .x = -1, .y = 0 };

const EVERY_DIRECTION = [8]Direction{ UP_LEFT, UP, UP_RIGHT, RIGHT, DOWN_RIGHT, DOWN, DOWN_LEFT, LEFT };
const X_DIRECTIONS = [2][2]Direction{ [2]Direction{ UP_LEFT, DOWN_RIGHT }, [2]Direction{ UP_RIGHT, DOWN_LEFT } };

const Location = struct {
    x: usize,
    y: usize,
    width: usize,

    pub fn current(self: *const Location) usize {
        return self.x + (self.y * self.width);
    }
};

pub fn run(allocator: std.mem.Allocator) !void {
    std.debug.print("Running AoC Day 4...\n\n", .{});

    const buffer = try allocator.alloc(u8, 20000);
    defer allocator.free(buffer);
    const input_length = try file.readFileToBuffer("input/day4.txt", buffer);

    var lines = std.mem.splitSequence(u8, buffer[0..input_length], "\n");
    const first = lines.first();

    var location = Location{
        .x = 0,
        .y = 0,
        .width = first.len,
    };

    var lines_conjoined = try std.ArrayList(u8).initCapacity(allocator, location.width);
    try lines_conjoined.appendSlice(first);
    while (lines.next()) |line| {
        if (line.len != 0) try lines_conjoined.appendSlice(line);
    }

    const crossword = try lines_conjoined.toOwnedSlice();
    defer allocator.free(crossword);

    var xmas_count: usize = 0;
    var x_mas_count: usize = 0;
    while (location.current() < crossword.len) {
        if (location.x >= location.width) {
            location.x = 0;
            location.y += 1;

            continue;
        }

        if (crossword[location.current()] == 'X') {
            const good_directions = check_directions(0b11111111, "MAS", crossword, location);

            for (EVERY_DIRECTION) |direction| {
                if (direction.direction_mask & good_directions == direction.direction_mask) {
                    xmas_count += 1;
                }
            }
        }

        if (crossword[location.current()] == 'A') {
            if (check_for_x(crossword, location)) {
                x_mas_count += 1;
            }
        }

        location.x += 1;
    }

    std.debug.print("Found {} XMASs\n", .{xmas_count});
    std.debug.print("Found {} X-MASs\n", .{x_mas_count});
}

fn get_next_location(location: Location, direction: Direction) ?Location {
    const next_x = @as(isize, @intCast(location.x)) + direction.x;
    if (next_x < 0 or next_x >= location.width) return null;

    const next_y = @as(isize, @intCast(location.y)) + direction.y;
    if (next_y < 0) return null;

    return Location{ .width = location.width, .x = @as(usize, @intCast(next_x)), .y = @as(usize, @intCast(next_y)) };
}

fn check_directions(
    directions: u8,
    find: []const u8,
    buffer: []const u8,
    location: Location,
) u8 {
    if (find.len == 0) {
        return directions;
    }

    var good_directions: u8 = 0;
    for (EVERY_DIRECTION) |direction| {
        if (direction.direction_mask & directions == direction.direction_mask) {
            if (get_next_location(location, direction)) |next_location| {
                if (next_location.current() > buffer.len) continue;

                if (buffer[next_location.current()] == find[0]) {
                    good_directions |= check_directions(direction.direction_mask, find[1..], buffer, next_location);
                }
            }
        }
    }

    return good_directions;
}

fn check_for_x(buffer: []const u8, location: Location) bool {
    var found_mas: usize = 0;
    for (X_DIRECTIONS) |directions| {
        var m_found = false;
        var s_found = false;
        for (directions) |direction| {
            if (get_next_location(location, direction)) |next_location| {
                if (next_location.current() > buffer.len) continue;

                if (buffer[next_location.current()] == 'S' and !s_found) {
                    s_found = true;
                } else if (buffer[next_location.current()] == 'M' and !m_found) {
                    m_found = true;
                }
            }
        }

        if (m_found and s_found) found_mas += 1;
    }

    return found_mas == 2;
}
