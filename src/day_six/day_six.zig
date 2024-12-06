const std = @import("std");
const file = @import("../file-helpers.zig");

const Cell = struct { visited: bool, obstructed: bool };
const Point = struct {
    x: isize,
    y: isize,

    fn add(self: *Point, rhs: Point) Point {
        return Point{ .x = self.x + rhs.x, .y = self.y + rhs.y };
    }

    fn arrayLocation(self: *Point, width: usize) usize {
        return (@as(usize, @intCast(self.y)) * width) + @as(usize, @intCast(self.x));
    }
};

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

pub fn run(allocator: std.mem.Allocator) !void {
    std.debug.print("\n\nRunning AoC Day 6...\n\n", .{});

    const buffer = try allocator.alloc(u8, 20000);
    defer allocator.free(buffer);
    const input_length = try file.readFileToBuffer("input/day6.txt", buffer);

    var lines = std.mem.splitSequence(u8, buffer[0..input_length], "\n");

    const grid_width = lines.first().len;
    var grid_height: usize = 0;
    lines.reset();

    var cell_list = std.ArrayList(Cell).init(allocator);
    var position = Point{ .x = 0, .y = 0 };
    var direction = Direction.up;

    var y_index: usize = 0;
    while (lines.next()) |line| : (y_index += 1) {
        if (line.len != 0) {
            grid_height += 1;
            for (line, 0..) |character, x_index| {
                switch (character) {
                    '#' => {
                        try cell_list.append(Cell{ .visited = false, .obstructed = true });
                    },
                    '^' => {
                        position = Point{
                            .x = @as(isize, @intCast(x_index)),
                            .y = @as(isize, @intCast(y_index)),
                        };
                        try cell_list.append(Cell{ .visited = true, .obstructed = false });
                    },
                    else => {
                        try cell_list.append(Cell{ .visited = false, .obstructed = false });
                    },
                }
            }
        }
    }

    var cells = try cell_list.toOwnedSlice();
    defer allocator.free(cells);

    var visited: usize = 1;
    var next_position = position.add(getDirection(direction));

    while (next_position.x >= 0 and next_position.y >= 0 and
        next_position.x < grid_width and next_position.y < grid_height)
    {
        if (!cells[next_position.arrayLocation(grid_width)].obstructed) {
            position = next_position;

            if (!cells[position.arrayLocation(grid_width)].visited) {
                visited += 1;
                cells[position.arrayLocation(grid_width)] = Cell{ .visited = true, .obstructed = false };
            }
        } else {
            switch (direction) {
                Direction.up => direction = Direction.right,
                Direction.right => direction = Direction.down,
                Direction.down => direction = Direction.left,
                Direction.left => direction = Direction.up,
            }
        }

        next_position = position.add(getDirection(direction));
    }

    std.debug.print("Total visited cells (part 1): {}\n", .{visited});
}
