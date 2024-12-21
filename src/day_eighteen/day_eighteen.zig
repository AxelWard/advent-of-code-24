const std = @import("std");
const file = @import("../file-helpers.zig");
const Point = @import("../Point.zig").Point;

const CellType = enum { free, corrupted };
const Cell = struct { type: CellType, minimum_distance: usize, came_from: ?Point };
const Grid = @import("../Grid.zig").Grid(Cell);

// Test Config
// const STEPS_TO_SIMULATE: usize = 12;
// const GRID_WIDTH: usize = 7;
// const GRID_HEIGHT: usize = 7;

// Real Config
const STEPS_TO_SIMULATE: usize = 1024;
const STEPS_TO_START: usize = 2000;
const GRID_WIDTH: usize = 71;
const GRID_HEIGHT: usize = 71;

pub fn run(allocator: std.mem.Allocator) !void {
    const buffer = try allocator.alloc(u8, 20000);
    defer allocator.free(buffer);
    const input_length = try file.readFileToBuffer("input/day18.txt", buffer);

    var lines = std.mem.splitSequence(u8, buffer[0 .. input_length - 1], "\n");
    var memory_corruption_list = std.ArrayList(Point).init(allocator);
    while (lines.next()) |line| {
        var split_line = std.mem.splitSequence(u8, line, ",");
        try memory_corruption_list.append(Point{
            .x = try std.fmt.parseInt(isize, split_line.next().?, 10),
            .y = try std.fmt.parseInt(isize, split_line.next().?, 10),
        });
    }

    const memory_corruption_steps = try memory_corruption_list.toOwnedSlice();
    defer allocator.free(memory_corruption_steps);

    var grid = Grid{
        .cells = try allocator.alloc(Cell, GRID_WIDTH * GRID_HEIGHT),
        .width = GRID_WIDTH,
        .height = GRID_HEIGHT,
    };
    defer allocator.free(grid.cells);

    grid.cells[0] = Cell{ .type = CellType.free, .minimum_distance = 0, .came_from = null };
    for (1..GRID_WIDTH * GRID_HEIGHT) |index| {
        grid.cells[index] = Cell{
            .type = CellType.free,
            .minimum_distance = std.math.maxInt(usize),
            .came_from = null,
        };
    }

    for (memory_corruption_steps[0..STEPS_TO_SIMULATE]) |step| {
        grid.setCell(step, Cell{
            .type = CellType.corrupted,
            .minimum_distance = std.math.maxInt(usize),
            .came_from = null,
        });
    }

    var steps = try calculatePath(&grid, allocator);
    const part_1_len = steps.len;
    defer allocator.free(steps);

    for (memory_corruption_steps[STEPS_TO_SIMULATE..STEPS_TO_START]) |step| {
        grid.setCell(step, Cell{
            .type = CellType.corrupted,
            .minimum_distance = std.math.maxInt(usize),
            .came_from = null,
        });
    }

    var num_corrupted: usize = STEPS_TO_START;
    while (steps.len > 0) : (num_corrupted += 1) {
        const corruption_point = memory_corruption_steps[num_corrupted];
        std.debug.print("\x1B[2J\x1B[H", .{});
        allocator.free(steps);

        // Reset the grid
        for (1..GRID_WIDTH * GRID_HEIGHT) |index| {
            grid.cells[index].minimum_distance = std.math.maxInt(usize);
            grid.cells[index].came_from = null;
        }

        grid.setCell(
            corruption_point,
            Cell{
                .type = CellType.corrupted,
                .minimum_distance = std.math.maxInt(usize),
                .came_from = null,
            },
        );

        steps = try calculatePath(&grid, allocator);
        try printGrid(&grid, memory_corruption_steps[num_corrupted], steps, allocator);
        std.debug.print("Corrupted bit {} {} ({})\n", .{ corruption_point.x, corruption_point.y, num_corrupted });
        std.time.sleep(std.time.ns_per_ms * 16);
    }

    std.debug.print("\x1B[2J\x1B[H", .{});
    std.debug.print("Total steps taken to exit (part 1): {}\n", .{part_1_len});
    std.debug.print("First corruption that blocks (part 2): {},{} (index {})\n", .{
        memory_corruption_steps[num_corrupted - 1].x,
        memory_corruption_steps[num_corrupted - 1].y,
        num_corrupted - 1,
    });
}

fn printGrid(
    grid: *Grid,
    last_corrupted: Point,
    steps: []const Point,
    allocator: std.mem.Allocator,
) !void {
    var grid_string = try allocator.alloc(u8, grid.cells.len + grid.height);
    defer allocator.free(grid_string);

    for (0..grid.height) |y_index| {
        for (0..grid.width) |x_index| {
            const set_index = (y_index * grid.width) + x_index + y_index;
            if (last_corrupted.x == x_index and last_corrupted.y == y_index) {
                grid_string[set_index] = '@';
            } else if (grid.getCell(Point{ .x = @intCast(x_index), .y = @intCast(y_index) })) |cell| {
                switch (cell.type) {
                    CellType.free => grid_string[set_index] = ' ',
                    CellType.corrupted => grid_string[set_index] = '#',
                }
            }
        }

        grid_string[(y_index * grid.width) + grid.width + y_index] = '\n';
    }

    for (steps) |step| {
        const set_index = (@as(usize, @intCast(step.y)) * grid.width) + @as(usize, @intCast(step.x)) + @as(usize, @intCast(step.y));
        grid_string[set_index] = 'O';
    }

    std.debug.print("{s}\n", .{grid_string});
}

const ExploreCell = struct {
    position: Point,
    low_score: usize,
};

fn ecLessThan(context: void, a: ExploreCell, b: ExploreCell) std.math.Order {
    _ = context;
    return std.math.order(a.low_score, b.low_score);
}

fn calculatePath(grid: *Grid, allocator: std.mem.Allocator) ![]Point {
    var to_explore = std.PriorityQueue(ExploreCell, void, ecLessThan).init(allocator, {});
    defer to_explore.deinit();

    const start = Point{ .x = 0, .y = 0 };
    try to_explore.addSlice(try getNextCells(
        grid,
        ExploreCell{ .position = start, .low_score = 0 },
        allocator,
    ));

    const goal = Point{ .x = GRID_WIDTH - 1, .y = GRID_HEIGHT - 1 };
    while (to_explore.removeOrNull()) |next_point| {
        if (next_point.position.eq(goal)) {
            break;
        }

        for (try getNextCells(grid, next_point, allocator)) |cell_to_add| {
            try to_explore.add(cell_to_add);
        }
    }

    var points = std.ArrayList(Point).init(allocator);
    var next: ?Point = null;
    if (grid.getCell(goal)) |goal_cell| {
        next = goal_cell.came_from;
    }

    while (next) |next_cell| {
        try points.append(next_cell);
        if (grid.getCell(next_cell)) |cell| {
            next = cell.came_from;
        } else {
            next = null;
        }
    }

    return try points.toOwnedSlice();
}

const CheckDirections = [4]Point{
    Point{ .x = 1, .y = 0 },
    Point{ .x = 0, .y = 1 },
    Point{ .x = -1, .y = 0 },
    Point{ .x = 0, .y = -1 },
};

fn getNextCells(
    grid: *Grid,
    current_explore_cell: ExploreCell,
    allocator: std.mem.Allocator,
) ![]ExploreCell {
    var cells = std.ArrayList(ExploreCell).init(allocator);
    defer cells.deinit();

    for (CheckDirections) |direction| {
        const next_position = current_explore_cell.position.add(direction);
        if (grid.getCell(next_position)) |check_cell| {
            if (check_cell.type == CellType.corrupted) continue;

            if (current_explore_cell.low_score + 1 < check_cell.minimum_distance) {
                check_cell.minimum_distance = current_explore_cell.low_score + 1;
                check_cell.came_from = current_explore_cell.position;
                try cells.append(ExploreCell{
                    .position = next_position,
                    .low_score = check_cell.minimum_distance,
                });
            }
        }
    }

    return try cells.toOwnedSlice();
}
