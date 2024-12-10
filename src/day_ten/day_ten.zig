const std = @import("std");
const readFileToBuffer = @import("../file-helpers.zig").readFileToBuffer;
const Point = @import("../Point.zig").Point;

const Cell = struct {
    height: usize,
    found_destinations: usize,
};

const Grid = @import("../Grid.zig").Grid(Cell);

pub fn run(allocator: std.mem.Allocator) !void {
    const buffer = try allocator.alloc(u8, 20000);
    defer allocator.free(buffer);
    const input_length = try readFileToBuffer("input/day10_test.txt", buffer);

    var grid = try readGrid(buffer[0..input_length], allocator);

    for (0..grid.height) |y_index| {
        for (0..grid.width) |x_index| {
            if (grid.getCell(Point{
                .x = @as(isize, @intCast(x_index)),
                .y = @as(isize, @intCast(y_index)),
            })) |cell| {
                if (cell.height == 0) {}
            }
        }
    }
}

fn readGrid(buffer: []const u8, allocator: std.mem.Allocator) !Grid {
    var lines = std.mem.splitSequence(u8, buffer, "\n");
    const grid_width = lines.first().len;
    var grid_height: usize = 0;
    lines.reset();

    var cell_list = std.ArrayList(Cell).init(allocator);

    while (lines.next()) |line| {
        if (line.len != 0) {
            grid_height += 1;
            for (line) |character| {
                try cell_list.append(Cell{
                    .height = try std.fmt.parseUnsigned(usize, &[1]u8{character}, 10),
                    .found_destinations = 0,
                });
            }
        }
    }

    return Grid{ .cells = try cell_list.toOwnedSlice(), .width = grid_width, .height = grid_height };
}
