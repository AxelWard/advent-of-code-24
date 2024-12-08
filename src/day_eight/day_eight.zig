const std = @import("std");
const file = @import("../file-helpers.zig");
const Point = @import("../point.zig").Point;

pub fn run(allocator: std.mem.Allocator) !void {
    const buffer = try allocator.alloc(u8, 20000);
    defer allocator.free(buffer);
    const input_length = try file.readFileToBuffer("input/day8.txt", buffer);

    var lines = std.mem.splitSequence(u8, buffer[0..input_length], "\n");
    const grid_width = lines.first().len;
    lines.reset();

    var antennas = std.AutoHashMap(u8, []const Point).init(allocator);
    var grid_height: usize = 0;
    while (lines.next()) |line| {
        if (line.len != 0) {
            try getLineAntennas(&antennas, grid_height, line, allocator);
            grid_height += 1;
        }
    }

    std.debug.print("Total unique equidistant antinode points (Part 1): {}\n", .{
        try getUniqueEquidistantAntinodeCount(&antennas, grid_width, grid_height, allocator),
    });

    std.debug.print("Total unique in line antinode points (Part 2): {}\n", .{
        try getUniqueInLineAntinodeCount(&antennas, grid_width, grid_height, allocator),
    });
}

fn getLineAntennas(
    antennas: *std.AutoHashMap(u8, []const Point),
    y_index: usize,
    line: []const u8,
    allocator: std.mem.Allocator,
) !void {
    for (line, 0..) |character, x_index| {
        if (character == '.') continue;

        var new_antennas = std.ArrayList(Point).init(allocator);

        if (antennas.fetchRemove(character)) |old_antennas| {
            defer allocator.free(old_antennas.value);
            try new_antennas.appendSlice(old_antennas.value);
        }

        try new_antennas.append(Point{
            .x = @as(isize, @intCast(x_index)),
            .y = @as(isize, @intCast(y_index)),
        });
        try antennas.put(character, try new_antennas.toOwnedSlice());
    }
}

fn getUniqueEquidistantAntinodeCount(
    antennas: *std.AutoHashMap(u8, []const Point),
    grid_width: usize,
    grid_height: usize,
    allocator: std.mem.Allocator,
) !usize {
    var antenna_iter = antennas.iterator();

    var antinode_locations = try allocator.alloc(bool, grid_width * grid_height);
    for (0..antinode_locations.len) |location| antinode_locations[location] = false;
    defer allocator.free(antinode_locations);

    var antinode_total: usize = 0;
    while (antenna_iter.next()) |antenna_set| {
        for (antenna_set.value_ptr.*[0 .. antenna_set.value_ptr.len - 1], 0..) |antenna, index| {
            for (antenna_set.value_ptr.*[index + 1 .. antenna_set.value_ptr.len]) |second_antenna| {
                const distance = second_antenna.sub(antenna);

                const antinode_1 = antenna.sub(distance);
                const antinode_2 = second_antenna.add(distance);

                if (pointInGrid(antinode_1, grid_width, grid_height) and
                    !antinode_locations[pointAsIndex(antinode_1, grid_width)])
                {
                    antinode_locations[pointAsIndex(antinode_1, grid_width)] = true;
                    antinode_total += 1;
                }

                if (pointInGrid(antinode_2, grid_width, grid_height) and
                    !antinode_locations[pointAsIndex(antinode_2, grid_width)])
                {
                    antinode_locations[pointAsIndex(antinode_2, grid_width)] = true;
                    antinode_total += 1;
                }
            }
        }
    }

    return antinode_total;
}

fn getUniqueInLineAntinodeCount(
    antennas: *std.AutoHashMap(u8, []const Point),
    grid_width: usize,
    grid_height: usize,
    allocator: std.mem.Allocator,
) !usize {
    var antenna_iter = antennas.iterator();

    var antinode_locations = try allocator.alloc(bool, grid_width * grid_height);
    for (0..antinode_locations.len) |location| antinode_locations[location] = false;
    defer allocator.free(antinode_locations);

    var antinode_total: usize = 0;
    while (antenna_iter.next()) |antenna_set| {
        for (antenna_set.value_ptr.*[0 .. antenna_set.value_ptr.len - 1], 0..) |antenna, index| {
            for (antenna_set.value_ptr.*[index + 1 .. antenna_set.value_ptr.len]) |second_antenna| {
                const distance = getSmallestStepPossible(second_antenna.sub(antenna));

                var location = antenna.add(distance);
                while (pointInGrid(location, grid_width, grid_height)) : (location = location.add(distance)) {
                    if (!antinode_locations[pointAsIndex(location, grid_width)]) {
                        antinode_locations[pointAsIndex(location, grid_width)] = true;
                        antinode_total += 1;
                    }
                }

                location = second_antenna.sub(distance);
                while (pointInGrid(location, grid_width, grid_height)) : (location = location.sub(distance)) {
                    if (!antinode_locations[pointAsIndex(location, grid_width)]) {
                        antinode_locations[pointAsIndex(location, grid_width)] = true;
                        antinode_total += 1;
                    }
                }
            }
        }
    }

    return antinode_total;
}

fn getSmallestStepPossible(point: Point) Point {
    // Get the greatest common denominator
    const x = @abs(point.x);
    const y = @abs(point.y);
    var gcd = @min(x, y);
    while (gcd > 0) : (gcd -= 1) if (x % gcd == 0 and y % gcd == 0) break;

    return Point{ .x = @divExact(point.x, @as(i64, @intCast(gcd))), .y = @divExact(point.y, @as(i64, @intCast(gcd))) };
}

fn pointAsIndex(point: Point, grid_width: usize) usize {
    return (@as(usize, @intCast(point.y)) * grid_width) + @as(usize, @intCast(point.x));
}

fn pointInGrid(point: Point, grid_width: usize, grid_height: usize) bool {
    return point.x >= 0 and point.y >= 0 and point.x < grid_width and point.y < grid_height;
}
