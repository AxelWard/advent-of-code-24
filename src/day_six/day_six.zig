const std = @import("std");
const file = @import("../file-helpers.zig");

const Direction = enum { up, down, left, right };

fn getDirection(dir: Direction) Point {
    switch (dir) {
        Direction.up => {
            return Point{ .x = 0, .y = -1 };
        },
        Direction.down => {
            return Point{ .x = 0, .y = 1 };
        },
        Direction.right => {
            return Point{ .x = 1, .y = 0 };
        },
        Direction.left => {
            return Point{ .x = -1, .y = 0 };
        },
    }
}

const Cell = struct {
    visitedDirections: ?std.ArrayList(Direction),
    secondaryDirections: ?std.ArrayList(Direction),
};

const Grid = struct {
    cells: []Cell,
    width: usize,
    height: usize,

    fn getCell(self: *Grid, position: Point) ?*Cell {
        if (position.x < 0 or
            position.y < 0 or
            position.x >= self.width or
            position.y >= self.height) return null;

        return &self.cells[
            (@as(usize, @intCast(position.y)) * self.width) + @as(usize, @intCast(position.x))
        ];
    }
};

const Point = struct {
    x: isize,
    y: isize,

    fn add(self: *Point, rhs: Point) Point {
        return Point{ .x = self.x + rhs.x, .y = self.y + rhs.y };
    }
};

pub fn run(allocator: std.mem.Allocator) !void {
    std.debug.print("\n\nRunning AoC Day 6...\n\n", .{});

    const buffer = try allocator.alloc(u8, 20000);
    defer allocator.free(buffer);
    const input_length = try file.readFileToBuffer("input/day6.txt", buffer);

    const init = try readGrid(buffer[0..input_length], allocator);
    var grid = init.grid;
    defer {
        for (grid.cells) |*cell| {
            if (cell.visitedDirections) |*dir| {
                dir.clearAndFree();
            }
        }
        allocator.free(grid.cells);
    }

    var visited: usize = 1;
    var direction = Direction.up;
    var position = init.starting_position;
    var next_position = position.add(getDirection(direction));

    while (grid.getCell(next_position)) |next_cell| {
        // Check to see if the cell is obstructed
        if (next_cell.visitedDirections) |*directions| {
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
                if (current_cell.visitedDirections) |*directions| {
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
                            .visitedDirections = null,
                            .secondaryDirections = null,
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
                            .visitedDirections = directions,
                            .secondaryDirections = std.ArrayList(Direction).init(allocator),
                        });
                    },
                    else => {
                        try cell_list.append(Cell{
                            .visitedDirections = std.ArrayList(Direction).init(allocator),
                            .secondaryDirections = std.ArrayList(Direction).init(allocator),
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

// Part 2 solution:
//
// For each step put a new test obstruction in front of the current position
// Run the exit simulation until the character either exits the array
// OR encounters a position where they've been going that direction already.
// If they encounter a postion where they've been going that direction already
// then we can assume that they are now in a loop.

// fn obstructionWouldCauseLoop(
//     starting_position: Point,
//     starting_direction: Direction,
//     grid: *Grid,
// ) bool {
//     // Check if the next position is already obstructed, return false if so
//     var next_position = starting_position.add(getDirection(starting_direction));
//     if (grid.cells[next_position.arrayLocation(grid.width)].visitedDirections == null) {
//         return false;
//     }
//
//     // Make sure we clear our temp directions at the end of the function
//     defer for (grid.cells) |*cell| {
//         if (cell.secondaryDirections) |*directions| {
//             directions.clearAndFree();
//         }
//     };
//
//     while (next_position.x >= 0 and next_position.y >= 0 and
//         next_position.x < grid.grid_width and next_position.y < grid.grid_height)
//     {}
//
//     return false;
// }
