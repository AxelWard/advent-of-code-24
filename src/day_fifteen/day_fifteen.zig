const std = @import("std");
const readFileToBuffer = @import("../file-helpers.zig").readFileToBuffer;
const Point = @import("../Point.zig").Point;

const CellType = enum { Empty, Box, Wall, Player };

const Grid = @import("../Grid.zig").Grid(CellType);

pub fn run(allocator: std.mem.Allocator) !void {
    const buffer = try allocator.alloc(u8, 30000);
    defer allocator.free(buffer);
    const input_length = try readFileToBuffer("input/day15.txt", buffer);

    var lines = std.mem.splitSequence(u8, buffer[0 .. input_length - 1], "\n");
    const grid_width = lines.first().len;
    lines.reset();

    var cell_list = std.ArrayList(CellType).init(allocator);
    var current_location = Point{
        .x = 0,
        .y = 0,
    };

    var y_index: usize = 0;
    while (lines.next()) |line| : (y_index += 1) {
        if (line.len == 0) break;

        try cell_list.ensureUnusedCapacity(line.len);
        for (line, 0..) |character, x_index| {
            if (character == 'O') {
                try cell_list.append(CellType.Box);
            } else if (character == '#') {
                try cell_list.append(CellType.Wall);
            } else if (character == '@') {
                current_location.x = @as(isize, @intCast(x_index));
                current_location.y = @as(isize, @intCast(y_index));
                try cell_list.append(CellType.Player);
            } else {
                try cell_list.append(CellType.Empty);
            }
        }
    }

    var grid = Grid{
        .cells = try cell_list.toOwnedSlice(),
        .width = grid_width,
        .height = y_index,
    };
    defer allocator.free(grid.cells);

    var steps_taken: usize = 0;
    while (lines.next()) |line| {
        for (line) |character| {
            if (character == '>') {
                runStep(&grid, &current_location, Point{ .x = 1, .y = 0 });
            } else if (character == '^') {
                runStep(&grid, &current_location, Point{ .x = 0, .y = -1 });
            } else if (character == '<') {
                runStep(&grid, &current_location, Point{ .x = -1, .y = 0 });
            } else if (character == 'v') {
                runStep(&grid, &current_location, Point{ .x = 0, .y = 1 });
            } else {
                continue;
            }

            steps_taken += 1;
        }
    }

    try printGrid(&grid, allocator);

    std.debug.print("Total steps taken: {}\n", .{steps_taken});
    std.debug.print("Lanternfish GPS total: {}\n", .{calculateGridGpsSum(&grid)});
}

// Debug troubleshooting helper
fn printGrid(grid: *Grid, allocator: std.mem.Allocator) !void {
    var grid_string = try allocator.alloc(u8, grid.cells.len + grid.height);
    defer allocator.free(grid_string);

    for (0..grid.height) |y_index| {
        for (0..grid.width) |x_index| {
            const set_index = (y_index * grid.width) + x_index + y_index;
            if (grid.getCell(Point{ .x = @intCast(x_index), .y = @intCast(y_index) })) |cell| {
                switch (cell.*) {
                    CellType.Empty => grid_string[set_index] = ' ',
                    CellType.Player => grid_string[set_index] = '@',
                    CellType.Box => grid_string[set_index] = 'O',
                    CellType.Wall => grid_string[set_index] = '#',
                }
            }
        }

        grid_string[(y_index * grid.width) + grid.width + y_index] = '\n';
    }

    std.debug.print("{s}\n", .{grid_string});
}

fn runStep(grid: *Grid, current_location: *Point, step: Point) void {
    if (grid.getCell(current_location.add(step))) |cell| {
        if (cell.* == CellType.Wall) return;

        if (cell.* == CellType.Box) {
            var push_count: usize = 1;
            while (grid.getCell(current_location.add(step.mult(@intCast(push_count + 1))))) |check_cell| {
                switch (check_cell.*) {
                    CellType.Box => push_count += 1,
                    CellType.Wall => return,
                    else => break,
                }
            }

            var step_index: usize = push_count;
            while (step_index > 0) : (step_index -= 1) {
                if (grid.getCell(current_location.add(step.mult(@intCast(step_index))))) |old_cell| {
                    grid.setCell(current_location.add(step.mult(@intCast(step_index + 1))), old_cell.*);
                }
            }
        }

        grid.setCell(current_location.*, CellType.Empty);
        grid.setCell(current_location.add(step), CellType.Player);
        current_location.x = current_location.add(step).x;
        current_location.y = current_location.add(step).y;
    }
}

fn calculateGridGpsSum(grid: *Grid) usize {
    var gps_total: usize = 0;
    for (1..grid.height) |y_index| {
        for (1..grid.width) |x_index| {
            if (grid.getCell(Point{ .x = @intCast(x_index), .y = @intCast(y_index) })) |cell| {
                if (cell.* == CellType.Box) {
                    gps_total += (100 * y_index) + x_index;
                }
            }
        }
    }

    return gps_total;
}
