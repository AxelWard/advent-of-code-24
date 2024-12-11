const std = @import("std");
const readFileToBuffer = @import("../file-helpers.zig").readFileToBuffer;
const Point = @import("../Point.zig").Point;

const Cell = struct {
    height: usize,
    found_destinations: usize,
    found_by: []Point,
};

const Grid = @import("../Grid.zig").Grid(Cell);

pub fn run(allocator: std.mem.Allocator) !void {
    const buffer = try allocator.alloc(u8, 20000);
    defer allocator.free(buffer);
    const input_length = try readFileToBuffer("input/day10.txt", buffer);

    var grid = try readGrid(buffer[0..input_length], allocator);

    var found_destinations: usize = 0;
    for (0..grid.height) |y_index| {
        for (0..grid.width) |x_index| {
            const search_x = @as(isize, @intCast(x_index));
            const search_y = @as(isize, @intCast(y_index));
            if (grid.getCell(Point{
                .x = search_x,
                .y = search_y,
            })) |cell| {
                if (cell.height == 0) {
                    found_destinations += try searchAdjacent(
                        0,
                        Point{ .x = search_x, .y = search_y },
                        Point{ .x = search_x, .y = search_y },
                        &grid,
                        allocator,
                    );
                }
            }
        }
    }

    std.debug.print("Trail distinct count (part 2): {}\n", .{found_destinations});
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
                    .found_by = &[0]Point{},
                });
            }
        }
    }

    return Grid{
        .cells = try cell_list.toOwnedSlice(),
        .width = grid_width,
        .height = grid_height,
    };
}

fn searchAdjacent(
    start_val: usize,
    search_start: Point,
    search_point: Point,
    grid: *Grid,
    allocator: std.mem.Allocator,
) !usize {
    if (start_val == 9) {
        // Part 1 logic
        //
        // if (grid.getCell(search_point)) |cell| {
        //     for (cell.found_by) |point| {
        //         if (point.x != search_start.x or point.y != search_start.y) {
        //             continue;
        //         } else return 0;
        //     }

        //     var points = try allocator.alloc(Point, cell.found_by.len + 1);
        //     if (cell.found_by.len != 0) {
        //         @memcpy(points[0..cell.found_by.len], cell.found_by);
        //     }
        //     points[points.len - 1] = search_start;
        //     allocator.free(cell.found_by);
        //     cell.found_by = points;

        return 1;

        // }
    }

    var cell_sum: usize = 0;
    if (grid.getCell(Point{ .x = search_point.x, .y = search_point.y + 1 })) |cell| {
        if (cell.height == start_val + 1) {
            if (cell.found_destinations != 0) {
                cell_sum += cell.found_destinations;
            } else {
                cell_sum += try searchAdjacent(
                    start_val + 1,
                    search_start,
                    Point{ .x = search_point.x, .y = search_point.y + 1 },
                    grid,
                    allocator,
                );
            }
        }
    }

    if (grid.getCell(Point{ .x = search_point.x + 1, .y = search_point.y })) |cell| {
        if (cell.height == start_val + 1) {
            if (cell.found_destinations != 0) {
                cell_sum += cell.found_destinations;
            } else {
                cell_sum += try searchAdjacent(
                    start_val + 1,
                    search_start,
                    Point{ .x = search_point.x + 1, .y = search_point.y },
                    grid,
                    allocator,
                );
            }
        }
    }

    if (grid.getCell(Point{ .x = search_point.x - 1, .y = search_point.y })) |cell| {
        if (cell.height == start_val + 1) {
            if (cell.found_destinations != 0) {
                cell_sum += cell.found_destinations;
            } else {
                cell_sum += try searchAdjacent(
                    start_val + 1,
                    search_start,
                    Point{ .x = search_point.x - 1, .y = search_point.y },
                    grid,
                    allocator,
                );
            }
        }
    }

    if (grid.getCell(Point{ .x = search_point.x, .y = search_point.y - 1 })) |cell| {
        if (cell.height == start_val + 1) {
            if (cell.found_destinations != 0) {
                cell_sum += cell.found_destinations;
            } else {
                cell_sum += try searchAdjacent(
                    start_val + 1,
                    search_start,
                    Point{ .x = search_point.x, .y = search_point.y - 1 },
                    grid,
                    allocator,
                );
            }
        }
    }

    return cell_sum;
}
