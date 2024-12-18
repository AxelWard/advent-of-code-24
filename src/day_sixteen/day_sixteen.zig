const std = @import("std");
const readFileToBuffer = @import("../file-helpers.zig").readFileToBuffer;
const Point = @import("../Point.zig").Point;

const CellType = enum { Empty, Wall, Goal, Walked };
const Direction = enum { North, South, East, West };
const DirectionInfo = struct { direction: Direction, travel: Point };

const CheckDirections = [4]DirectionInfo{
    .{ .direction = Direction.East, .travel = Point{ .x = 1, .y = 0 } },
    .{ .direction = Direction.South, .travel = Point{ .x = 0, .y = 1 } },
    .{ .direction = Direction.West, .travel = Point{ .x = -1, .y = 0 } },
    .{ .direction = Direction.North, .travel = Point{ .x = 0, .y = -1 } },
};

const Cell = struct {
    type: CellType,
    direction_cheapest_cost: std.EnumArray(Direction, usize),
    came_from: std.EnumArray(Direction, ?[]Point),
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

    std.debug.print("Possible best seats (part 2): {}\n", .{try countBestPathCells(
        &grid_info.grid,
        grid_info.goal_position,
        allocator,
    )});

    try printGrid(&grid_info.grid, grid_info.start_position, allocator);
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
                    .came_from = std.EnumArray(Direction, ?[]Point).initFill(null),
                    .direction_cheapest_cost = std.EnumArray(Direction, usize).initFill(std.math.maxInt(usize)),
                });
            } else if (character == '#') {
                try cell_list.append(Cell{
                    .type = CellType.Wall,
                    .came_from = std.EnumArray(Direction, ?[]Point).initFill(null),
                    .direction_cheapest_cost = std.EnumArray(Direction, usize).initFill(std.math.maxInt(usize)),
                });
            } else if (character == 'E') {
                try cell_list.append(Cell{
                    .type = CellType.Goal,
                    .came_from = std.EnumArray(Direction, ?[]Point).initFill(null),
                    .direction_cheapest_cost = std.EnumArray(Direction, usize).initFill(std.math.maxInt(usize)),
                });
                goal_position = Point{ .x = @intCast(x_index), .y = @intCast(grid_height) };
            } else {
                try cell_list.append(Cell{
                    .type = CellType.Empty,
                    .came_from = std.EnumArray(Direction, ?[]Point).initFill(null),
                    .direction_cheapest_cost = std.EnumArray(Direction, usize).initDefault(
                        std.math.maxInt(usize),
                        .{ .East = 0 },
                    ),
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
    start_cell: Point,
    allocator: std.mem.Allocator,
) !void {
    var grid_string = try allocator.alloc(u8, grid.cells.len + grid.height);
    defer allocator.free(grid_string);

    for (0..grid.height) |y_index| {
        for (0..grid.width) |x_index| {
            const set_index = (y_index * grid.width) + x_index + y_index;
            if (start_cell.x == x_index and start_cell.y == y_index) {
                grid_string[set_index] = '@';
            } else if (grid.getCell(Point{ .x = @intCast(x_index), .y = @intCast(y_index) })) |cell| {
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

    std.debug.print("{s}\n", .{grid_string});
}

const ExploreCell = struct {
    position: Point,
    direction: DirectionInfo,
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
        ExploreCell{ .position = start_position, .direction = .{ .direction = Direction.East, .travel = Point{ .x = 1, .y = 0 } }, .low_score = 0 },
        std.math.maxInt(usize),
        allocator,
    ));

    var found_distance: usize = std.math.maxInt(usize);
    while (to_explore.removeOrNull()) |next_point| {
        if (next_point.position.eq(goal_position)) {
            found_distance = next_point.low_score;
        }

        for (try getNextCells(grid, next_point, found_distance, allocator)) |cell_to_add| {
            if (cell_to_add.low_score <= found_distance) try to_explore.add(cell_to_add);
        }
    }

    return found_distance;
}

fn getNextCells(
    grid: *Grid,
    current_explore_cell: ExploreCell,
    goal_distance: usize,
    allocator: std.mem.Allocator,
) ![]ExploreCell {
    var cells = std.ArrayList(ExploreCell).init(allocator);
    defer cells.deinit();

    if (grid.getCell(current_explore_cell.position)) |current_cell| {
        for (CheckDirections) |direction| {
            var check_cost = current_explore_cell.low_score + 1000;
            if (check_cost < goal_distance and !direction.travel.eq(current_explore_cell.direction.travel)) {
                const backwards = direction.travel.add(current_explore_cell.direction.travel).eq(Point{ .x = 0, .y = 0 });
                const direction_low_value = current_cell.direction_cheapest_cost.get(direction.direction);

                if (backwards) check_cost += 1000;
                if (direction_low_value > check_cost) {
                    if (!backwards) try cells.append(ExploreCell{
                        .position = current_explore_cell.position,
                        .direction = direction,
                        .low_score = check_cost,
                    });

                    if (current_cell.came_from.get(direction.direction)) |past_from| {
                        allocator.free(past_from);
                    }

                    if (current_cell.came_from.get(current_explore_cell.direction.direction)) |originally_from| {
                        var new_from = try allocator.alloc(Point, originally_from.len);
                        for (originally_from, 0..) |from, index| {
                            new_from[index] = from;
                        }
                        current_cell.came_from.set(direction.direction, new_from);
                    }

                    current_cell.direction_cheapest_cost.set(direction.direction, check_cost);
                    continue;
                } else if (direction_low_value == check_cost) {
                    if (current_cell.came_from.get(direction.direction)) |existing_from| {
                        if (current_cell.came_from.get(current_explore_cell.direction.direction)) |originally_from| {
                            var new_from = try allocator.alloc(Point, originally_from.len + existing_from.len);
                            @memcpy(new_from[0..existing_from.len], existing_from);
                            for (originally_from, existing_from.len..) |from, index| {
                                new_from[index] = from;
                            }
                            current_cell.came_from.set(direction.direction, new_from);
                        }
                    }
                }
            } else if (grid.getCell(current_explore_cell.position.add(direction.travel))) |check_cell| {
                if (check_cell.type == CellType.Wall) continue;

                const direction_low_value = check_cell.direction_cheapest_cost.get(direction.direction);
                check_cost = current_explore_cell.low_score + 1;
                if (check_cost > goal_distance) continue;
                if (direction_low_value > check_cost) {
                    if (check_cell.type == CellType.Goal) cells.clearAndFree();

                    try cells.append(ExploreCell{
                        .position = current_explore_cell.position.add(direction.travel),
                        .direction = direction,
                        .low_score = check_cost,
                    });

                    if (check_cell.came_from.get(direction.direction)) |past_from| {
                        allocator.free(past_from);
                    }

                    var new_from = try allocator.alloc(Point, 1);
                    new_from[0] = current_explore_cell.position;

                    check_cell.came_from.set(direction.direction, new_from);
                    check_cell.direction_cheapest_cost.set(direction.direction, check_cost);

                    if (check_cell.type == CellType.Goal) break;
                } else if (direction_low_value == check_cost) {
                    if (check_cell.came_from.get(direction.direction)) |existing_from| {
                        var new_from = try allocator.alloc(Point, existing_from.len + 1);
                        @memcpy(new_from[0..existing_from.len], existing_from);
                        new_from[existing_from.len] = current_explore_cell.position;
                        check_cell.came_from.set(direction.direction, new_from);
                    }

                    if (check_cell.type == CellType.Goal) break;
                }
            }
        }
    }

    return try cells.toOwnedSlice();
}

const PastPoint = struct { position: Point, direction: Direction };

const arrayListContainsValue = @import("../array_list_helpers.zig").arrayListContainsValue(
    PastPoint,
    Point,
    struct {
        fn eqfn(a: PastPoint, b: Point) bool {
            return a.position.x == b.x and a.position.y == b.y;
        }
    }.eqfn,
);

fn countBestPathCells(
    grid: *Grid,
    goal_position: Point,
    allocator: std.mem.Allocator,
) !usize {
    var from_cells = std.ArrayList(PastPoint).init(allocator);
    for (grid.getCell(goal_position).?.came_from.values) |from| {
        if (from) |cells| {
            for (cells) |cell| {
                if (!arrayListContainsValue(&from_cells, cell)) {
                    try from_cells.append(PastPoint{
                        .position = cell,
                        .direction = directionFromPoint(goal_position.sub(cell)),
                    });
                }
            }
        }
    }
    defer from_cells.deinit();

    var check_cell: usize = 0;
    while (check_cell < from_cells.items.len) : (check_cell += 1) {
        if (grid.getCell(from_cells.items[check_cell].position)) |cell| {
            cell.type = CellType.Walked;
            if (cell.came_from.get(from_cells.items[check_cell].direction)) |cell_from| {
                for (cell_from) |from| {
                    if (!arrayListContainsValue(&from_cells, from)) {
                        try from_cells.append(PastPoint{
                            .position = from,
                            .direction = directionFromPoint(from_cells.items[check_cell].position.sub(from)),
                        });
                    }
                }
            }
        }
    }

    return from_cells.items.len + 1;
}

fn directionFromPoint(point: Point) Direction {
    for (CheckDirections) |direction| {
        if (point.x == direction.travel.x and point.y == direction.travel.y) return direction.direction;
    }
    unreachable;
}
