const std = @import("std");
const file = @import("../file-helpers.zig");
const Point = @import("../Point.zig").Point;

const arrayListContainsValue = @import("../array_list_helpers.zig").arrayListContainsValue(
    Direction,
    struct {
        fn eqfn(a: Direction, b: Direction) bool {
            return a == b;
        }
    }.eqfn,
);

const Direction = enum { up, down, left, right };

fn getDirection(dir: Direction) Point {
    switch (dir) {
        Direction.up => return Point{ .x = 0, .y = -1 },
        Direction.down => return Point{ .x = 0, .y = 1 },
        Direction.right => return Point{ .x = 1, .y = 0 },
        Direction.left => return Point{ .x = -1, .y = 0 },
    }
}

const Cell = struct {
    visited_directions: ?std.ArrayList(Direction),
    temp_directions: ?std.ArrayList(Direction),
};

const Grid = @import("../Grid.zig").Grid(Cell);

pub fn run(allocator: std.mem.Allocator) !void {
    const buffer = try allocator.alloc(u8, 20000);
    defer allocator.free(buffer);
    const input_length = try file.readFileToBuffer("input/day6.txt", buffer);

    const init = try readGrid(buffer[0..input_length], allocator);
    var grid = init.grid;
    defer {
        for (grid.cells) |*cell| {
            if (cell.visited_directions) |*dir| {
                dir.clearAndFree();
            }
        }
        allocator.free(grid.cells);
    }

    var visited: usize = 1;
    var possible_obstructions: usize = 0;
    var direction = Direction.up;
    var position = init.starting_position;
    var next_position = position.add(getDirection(direction));

    if (grid.getCell(position)) |start_cell| {
        if (start_cell.visited_directions) |*directions| {
            try directions.append(direction);
        }
    }

    while (grid.getCell(next_position)) |next_cell| {
        if (try obstructionWouldCauseLoop(position, direction, &grid)) possible_obstructions += 1;

        // Check to see if the cell is obstructed
        if (next_cell.visited_directions) |*directions| {
            position = next_position;

            // Check to see if we've visited this cell going any other direction before
            if (directions.items.len == 0) {
                // If we've never traversed this cell before then we should add one to our cell count
                visited += 1;
            }

            // Add our current direction of travel to our list of visited directions
            try directions.append(direction);
        } else {
            // Turn right
            direction = getNextDirection(direction);
            if (grid.getCell(position)) |current_cell| {
                if (current_cell.visited_directions) |*directions| {
                    // Append that we've visited this cell going the new direction to our list of
                    // visited directions
                    try directions.append(direction);
                }
            }
        }

        // Track which cell will be our next cell to visit
        next_position = position.add(getDirection(direction));
    }

    std.debug.print("Total visited cells (part 1): {}\n", .{visited});
    std.debug.print("Total possible obstructions (part 2): {}\n", .{possible_obstructions});
}

fn readGrid(buffer: []const u8, allocator: std.mem.Allocator) !struct { grid: Grid, starting_position: Point } {
    var lines = std.mem.splitSequence(u8, buffer, "\n");
    const grid_width = lines.first().len;
    var grid_height: usize = 0;
    lines.reset();

    var cell_list = std.ArrayList(Cell).init(allocator);
    var position = Point{ .x = 0, .y = 0 };

    // Initialize starting grid
    var y_index: usize = 0;
    while (lines.next()) |line| : (y_index += 1) {
        if (line.len != 0) {
            grid_height += 1;
            for (line, 0..) |character, x_index| {
                switch (character) {
                    '#' => {
                        try cell_list.append(Cell{
                            .visited_directions = null,
                            .temp_directions = null,
                        });
                    },
                    '^' => {
                        position = Point{
                            .x = @as(isize, @intCast(x_index)),
                            .y = @as(isize, @intCast(y_index)),
                        };

                        var directions = std.ArrayList(Direction).init(allocator);
                        try directions.append(Direction.up);
                        try cell_list.append(Cell{
                            .visited_directions = directions,
                            .temp_directions = std.ArrayList(Direction).init(allocator),
                        });
                    },
                    else => {
                        try cell_list.append(Cell{
                            .visited_directions = std.ArrayList(Direction).init(allocator),
                            .temp_directions = std.ArrayList(Direction).init(allocator),
                        });
                    },
                }
            }
        }
    }

    return .{
        .grid = Grid{ .cells = try cell_list.toOwnedSlice(), .width = grid_width, .height = grid_height },
        .starting_position = position,
    };
}

fn getNextDirection(direction: Direction) Direction {
    switch (direction) {
        Direction.up => return Direction.right,
        Direction.right => return Direction.down,
        Direction.down => return Direction.left,
        Direction.left => return Direction.up,
    }
}

fn obstructionWouldCauseLoop(
    starting_position: Point,
    starting_direction: Direction,
    grid: *Grid,
) !bool {
    // Check if the next position is already obstructed, return false if so
    var current_position = starting_position;
    var next_position = starting_position.add(getDirection(starting_direction));
    var old_cell: ?Cell = null;

    if (grid.getCell(next_position) == null) {
        return false;
    }

    if (grid.getCell(next_position)) |cell| {
        if (cell.visited_directions) |directions| {
            if (directions.items.len > 0) return false;
        }

        old_cell = Cell{
            .visited_directions = cell.visited_directions,
            .temp_directions = cell.temp_directions,
        };

        grid.setCell(next_position, Cell{
            .visited_directions = null,
            .temp_directions = null,
        });
    }

    defer {
        // Make sure we clear our temp directions at the end of the function
        for (grid.cells) |*cell| {
            if (cell.temp_directions) |*directions| {
                directions.clearAndFree();
            }
        }

        // and replace the cell that we set as an obstacle
        if (old_cell) |*cell| {
            grid.setCell(
                starting_position.add(getDirection(starting_direction)),
                cell.*,
            );
        }
    }

    // turn because we know that there is an obstruction
    var direction = getNextDirection(starting_direction);
    next_position = starting_position.add(getDirection(direction));

    // Add our turned direction to our list of temp visited directions
    if (grid.getCell(current_position)) |cell| {
        if (cell.temp_directions) |*temp_directions| {
            try temp_directions.append(starting_direction);
            try temp_directions.append(direction);
        }
    }

    while (grid.getCell(next_position)) |next_cell| {
        if (next_cell.temp_directions) |*temp_directions| {
            if (arrayListContainsValue(temp_directions, direction)) {
                return true;
            }

            try temp_directions.append(direction);
            current_position = next_position;
        } else {
            direction = getNextDirection(direction);
            if (grid.getCell(current_position)) |cell| {
                if (cell.temp_directions) |*temp_directions| {
                    try temp_directions.append(direction);
                }
            }
        }

        next_position = current_position.add(getDirection(direction));
    }

    return false;
}
