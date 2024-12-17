const std = @import("std");
const readFileToBuffer = @import("../file-helpers.zig").readFileToBuffer;
const Point = @import("../Point.zig").Point;

const CellType = enum { Empty, Wall, Goal, Walked };

const Cell = struct {
    type: CellType,
    totalCheapestCost: usize,
    cameFrom: ?Point,
};

const Grid = @import("../Grid.zig").Grid(Cell);

pub fn run(allocator: std.mem.Allocator) !void {
    const buffer = try allocator.alloc(u8, 30000);
    defer allocator.free(buffer);
    const input_length = try readFileToBuffer("input/day16.txt", buffer);

    var grid_info = try readGrid(buffer[0 .. input_length - 1], allocator);

    std.debug.print("Lowest reindeer score possible (part 1): {}\n", .{try findGoalDistance(
        &grid_info.grid,
        grid_info.start_position,
        grid_info.goal_position,
        allocator,
    )});
    try printGrid(&grid_info.grid, grid_info.start_position, grid_info.goal_position, allocator);
}

fn readGrid(input: []const u8, allocator: std.mem.Allocator) !struct {
    start_position: Point,
    goal_position: Point,
    grid: Grid,
} {
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
                    .type = CellType.Empty,
                    .cameFrom = null,
                    .totalCheapestCost = std.math.maxInt(usize),
                });
            } else if (character == '#') {
                try cell_list.append(Cell{
                    .type = CellType.Wall,
                    .cameFrom = null,
                    .totalCheapestCost = std.math.maxInt(usize),
                });
            } else if (character == 'E') {
                try cell_list.append(Cell{
                    .type = CellType.Goal,
                    .cameFrom = null,
                    .totalCheapestCost = std.math.maxInt(usize),
                });
                goal_position = Point{ .x = @intCast(x_index), .y = @intCast(grid_height) };
            } else {
                try cell_list.append(Cell{
                    .type = CellType.Empty,
                    .cameFrom = null,
                    .totalCheapestCost = std.math.maxInt(usize),
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

// Debug troubleshooting helper
fn printGrid(
    grid: *Grid,
    start_position: Point,
    goal_position: Point,
    allocator: std.mem.Allocator,
) !void {
    var next_cell = grid.getCell(grid.getCell(goal_position).?.cameFrom.?);
    while (next_cell) |pos| {
        if (pos.cameFrom) |pos_from| {
            pos.type = CellType.Walked;
            if (pos_from.eq(start_position)) break;
            next_cell = grid.getCell(pos_from);
            continue;
        }

        next_cell = null;
    }

    var grid_string = try allocator.alloc(u8, grid.cells.len + grid.height);
    defer allocator.free(grid_string);

    for (0..grid.height) |y_index| {
        for (0..grid.width) |x_index| {
            const set_index = (y_index * grid.width) + x_index + y_index;
            if (grid.getCell(Point{ .x = @intCast(x_index), .y = @intCast(y_index) })) |cell| {
                switch (cell.type) {
                    CellType.Empty => grid_string[set_index] = ' ',
                    CellType.Wall => grid_string[set_index] = '#',
                    CellType.Goal => grid_string[set_index] = 'G',
                    CellType.Walked => grid_string[set_index] = 'O',
                }
            }
        }

        grid_string[(y_index * grid.width) + grid.width + y_index] = '\n';
    }

    for (grid.cells) |*cell| {
        if (cell.type == CellType.Walked) {
            cell.type = CellType.Empty;
        }
    }

    std.debug.print("{s}\n", .{grid_string});
}

const ExploreCell = struct {
    position: Point,
    direction: Point,
    low_score: usize,
};

fn ecLessThan(context: void, a: ExploreCell, b: ExploreCell) std.math.Order {
    _ = context;
    return std.math.order(a.low_score, b.low_score);
}

fn findGoalDistance(
    grid: *Grid,
    start_position: Point,
    goal_position: Point,
    allocator: std.mem.Allocator,
) !usize {
    var to_explore = std.PriorityQueue(ExploreCell, void, ecLessThan).init(allocator, {});
    try to_explore.addSlice(try getNextCells(
        grid,
        ExploreCell{ .position = start_position, .direction = Point{ .x = 1, .y = 0 }, .low_score = 0 },
        allocator,
    ));

    while (to_explore.removeOrNull()) |next_point| {
        if (next_point.position.eq(goal_position)) {
            return next_point.low_score;
        }

        for (try getNextCells(grid, next_point, allocator)) |cell_to_add| {
            var should_add = true;
            for (to_explore.items, 0..) |check_cell, index| {
                if (check_cell.position.eq(cell_to_add.position)) {
                    should_add = check_cell.low_score > cell_to_add.low_score;
                    if (should_add) {
                        _ = to_explore.removeIndex(index);
                    }
                    break;
                }
            }

            if (should_add) try to_explore.add(cell_to_add);
        }
    }

    unreachable;
}

const CheckDirections = [4]Point{
    Point{ .x = -1, .y = 0 },
    Point{ .x = 1, .y = 0 },
    Point{ .x = 0, .y = -1 },
    Point{ .x = 0, .y = 1 },
};

fn getNextCells(
    grid: *Grid,
    current_cell: ExploreCell,
    allocator: std.mem.Allocator,
) ![]ExploreCell {
    var cells = std.ArrayList(ExploreCell).init(allocator);
    defer cells.deinit();

    for (CheckDirections) |direction| {
        var cost: usize = 1;
        if (grid.getCell(current_cell.position.add(direction))) |cell| {
            if (cell.type == CellType.Wall) continue;

            if (direction.add(current_cell.direction).eq(Point{ .x = 0, .y = 0 })) {
                cost += 2000;
            } else if (!direction.eq(current_cell.direction)) {
                cost += 1000;
            }

            if (cell.type == CellType.Empty and cell.totalCheapestCost > current_cell.low_score + cost) {
                try cells.append(ExploreCell{
                    .position = current_cell.position.add(direction),
                    .direction = direction,
                    .low_score = current_cell.low_score + cost,
                });
            } else if (cell.type == CellType.Goal) {
                cells.clearAndFree();
                try cells.append(ExploreCell{
                    .position = current_cell.position.add(direction),
                    .direction = direction,
                    .low_score = current_cell.low_score + cost,
                });
                break;
            }
        }
    }

    for (cells.items) |cell| {
        if (grid.getCell(cell.position)) |set_cell| {
            set_cell.totalCheapestCost = cell.low_score;
            set_cell.cameFrom = current_cell.position;
        }
    }

    return try cells.toOwnedSlice();
}
