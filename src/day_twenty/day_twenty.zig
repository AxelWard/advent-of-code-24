const std = @import("std");
const file = @import("../file-helpers.zig");
const Point = @import("../Point.zig").Point;

const CellType = enum { path, wall };
const Cell = struct { type: CellType, exit_distance: isize };
const Grid = @import("../Grid.zig").Grid(Cell);

const SHORTCUT_THRESHHOLD: usize = 100;
const CHEAT_TIME: isize = 20;

const CheckDirections = [4]Point{
    Point{ .x = 1, .y = 0 },
    Point{ .x = 0, .y = 1 },
    Point{ .x = -1, .y = 0 },
    Point{ .x = 0, .y = -1 },
};

const GridInfo = struct {
    start_position: Point,
    goal_position: Point,
    grid: Grid,
};

pub fn run(allocator: std.mem.Allocator) !void {
    const buffer = try allocator.alloc(u8, 25000);
    defer allocator.free(buffer);
    const input_length = try file.readFileToBuffer("input/day20.txt", buffer);

    var grid_info = try readGrid(buffer[0 .. input_length - 1], allocator);
    defer allocator.free(grid_info.grid.cells);

    precalculateDistances(&grid_info);

    std.debug.print("Number of best shortcuts (part 1): {}\n", .{countBestShortcuts(&grid_info)});
    std.debug.print("Number of best long shortcuts (part 2): {}\n", .{countBestLongShortcuts(&grid_info)});
}

fn readGrid(input: []const u8, allocator: std.mem.Allocator) !GridInfo {
    var lines = std.mem.splitSequence(u8, input, "\n");
    const grid_width = lines.first().len;
    var grid_height: usize = 0;
    lines.reset();

    var cell_list = std.ArrayList(Cell).init(allocator);
    var start_position = Point{ .x = 0, .y = 0 };
    var goal_position = Point{ .x = 0, .y = 0 };

    while (lines.next()) |line| : (grid_height += 1) {
        if (line.len == 0) continue;

        try cell_list.ensureUnusedCapacity(line.len);
        for (line, 0..) |character, x_index| {
            if (character == '.') {
                try cell_list.append(Cell{
                    .type = CellType.path,
                    .exit_distance = std.math.maxInt(isize),
                });
            } else if (character == '#') {
                try cell_list.append(Cell{
                    .type = CellType.wall,
                    .exit_distance = std.math.maxInt(isize),
                });
            } else if (character == 'E') {
                try cell_list.append(Cell{
                    .type = CellType.path,
                    .exit_distance = 0,
                });
                goal_position = Point{ .x = @intCast(x_index), .y = @intCast(grid_height) };
            } else if (character == 'S') {
                try cell_list.append(Cell{
                    .type = CellType.path,
                    .exit_distance = std.math.maxInt(isize),
                });

                start_position = Point{ .x = @intCast(x_index), .y = @intCast(grid_height) };
            }
        }
    }

    return .{
        .start_position = start_position,
        .goal_position = goal_position,
        .grid = Grid{
            .cells = try cell_list.toOwnedSlice(),
            .width = grid_width,
            .height = grid_height,
        },
    };
}

fn precalculateDistances(grid_info: *GridInfo) void {
    var previous_location = grid_info.goal_position;

    while (!previous_location.eq(grid_info.start_position)) {
        const previous_distance = grid_info.grid.getCell(previous_location).?.exit_distance;
        for (CheckDirections) |direction| {
            const check_location = previous_location.add(direction);
            if (grid_info.grid.getCell(check_location)) |check_cell| {
                if (check_cell.type == CellType.wall or check_cell.exit_distance < previous_distance) continue;

                check_cell.exit_distance = previous_distance + 1;
                previous_location = check_location;
                break;
            }
        }
    }

    std.debug.print("largest distance: {}\n", .{grid_info.grid.getCell(grid_info.start_position).?.exit_distance});
}

fn countBestShortcuts(grid_info: *GridInfo) usize {
    var current_location = grid_info.start_position;

    var best_count: usize = 0;
    while (!current_location.eq(grid_info.goal_position)) {
        var next_location = current_location;
        const current_cell = grid_info.grid.getCell(current_location).?;

        for (CheckDirections) |direction| {
            const step_one = current_location.add(direction);
            if (grid_info.grid.getCell(step_one)) |first_cell| {
                if (first_cell.exit_distance == current_cell.exit_distance - 1) {
                    next_location = step_one;
                    continue;
                }

                if (first_cell.type == CellType.path) continue;

                if (grid_info.grid.getCell(step_one.add(direction))) |second_cell| {
                    if (second_cell.type != CellType.path) continue;
                    const shortcut_distance = current_cell.exit_distance - second_cell.exit_distance - 2;
                    if (shortcut_distance >= SHORTCUT_THRESHHOLD) best_count += 1;
                }
            }
        }

        current_location = next_location;
    }

    return best_count;
}

fn countBestLongShortcuts(grid_info: *GridInfo) usize {
    var current_location = grid_info.start_position;

    var best_count: usize = 0;
    while (!current_location.eq(grid_info.goal_position)) {
        const current_cell = grid_info.grid.getCell(current_location).?;
        var next_location = current_location;

        var y_index = -CHEAT_TIME;
        while (y_index <= CHEAT_TIME) : (y_index += 1) {
            var x_index = -CHEAT_TIME;
            while (x_index <= CHEAT_TIME) : (x_index += 1) {
                const travel_distance = @as(isize, @bitCast(@abs(y_index) + @abs(x_index)));
                if (travel_distance > 20) continue;

                const check_location = current_location.add(Point{ .x = x_index, .y = y_index });
                if (grid_info.grid.getCell(check_location)) |check_cell| {
                    if (check_cell.exit_distance == current_cell.exit_distance - 1) {
                        next_location = check_location;
                        continue;
                    }

                    if (check_cell.type == CellType.wall) continue;
                    const shortcut_distance = current_cell.exit_distance - check_cell.exit_distance - travel_distance;
                    if (shortcut_distance >= SHORTCUT_THRESHHOLD) best_count += 1;
                }
            }
        }

        current_location = next_location;
    }

    return best_count;
}
