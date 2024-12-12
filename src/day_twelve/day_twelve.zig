const std = @import("std");
const readFileToBuffer = @import("../file-helpers.zig").readFileToBuffer;

const Cell = struct {
    plant: u8,
    plot_index: usize,
};

const Grid = @import("../Grid.zig").Grid(Cell);
const Point = @import("../Point.zig").Point;

pub fn run(allocator: std.mem.Allocator) !void {
    const buffer = try allocator.alloc(u8, 20000);
    defer allocator.free(buffer);
    const input_length = try readFileToBuffer("input/day12.txt", buffer);

    var grid = try readGrid(buffer[0..input_length], allocator);
    defer allocator.free(grid.cells);

    const sizes = try getGardenPlotSizes(&grid, allocator);
    defer {
        allocator.free(sizes.areas);
        allocator.free(sizes.perimiters);
    }

    var total_plot_price: usize = 0;
    for (sizes.areas, 0..) |area, index| {
        total_plot_price += area * sizes.perimiters[index];
    }

    std.debug.print("Total garden plot price (part 1): {}\n", .{total_plot_price});
}

fn readGrid(buffer: []const u8, allocator: std.mem.Allocator) !Grid {
    var lines = std.mem.splitSequence(u8, buffer, "\n");

    const grid_width = lines.first().len;
    var grid_height: usize = 0;
    lines.reset();

    var cell_list = std.ArrayList(Cell).init(allocator);

    while (lines.next()) |line| {
        try cell_list.ensureTotalCapacity(cell_list.items.len + grid_width);
        if (line.len != 0) {
            grid_height += 1;
            for (line) |character| {
                try cell_list.append(Cell{
                    .plant = character,
                    .plot_index = 0,
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

fn getGardenPlotSizes(grid: *Grid, allocator: std.mem.Allocator) !struct {
    areas: []usize,
    perimiters: []usize,
} {
    var area_list = std.ArrayList(usize).init(allocator);
    var perimiter_list = std.ArrayList(usize).init(allocator);

    var next_plot_index: usize = 0;
    for (0..grid.height) |y_index| {
        for (0..grid.width) |x_index| {
            const current_point = Point{ .x = @as(isize, @intCast(x_index)), .y = @as(isize, @intCast(y_index)) };

            if (grid.getCell(current_point)) |cell| {
                const x_check = grid.getCell(current_point.add(Point{ .x = -1, .y = 0 }));
                const y_check = grid.getCell(current_point.add(Point{ .x = 0, .y = -1 }));

                if (x_check) |x_check_cell| {
                    if (y_check) |y_check_cell| {
                        if (cell.plant == x_check_cell.plant and
                            cell.plant == y_check_cell.plant and
                            y_check_cell.plot_index != x_check_cell.plot_index)
                        {
                            cell.plot_index = x_check_cell.plot_index;
                            const change_index = y_check_cell.plot_index;
                            for (0..grid.cells.len) |index| {
                                if (grid.cells[index].plot_index == change_index) {
                                    grid.cells[index].plot_index = x_check_cell.plot_index;
                                }
                            }

                            area_list.items[x_check_cell.plot_index] += area_list.items[change_index] + 1;
                            perimiter_list.items[x_check_cell.plot_index] += perimiter_list.items[change_index];
                            area_list.items[change_index] = 0;
                            perimiter_list.items[change_index] = 0;
                            continue;
                        } else if (cell.plant == x_check_cell.plant and cell.plant == y_check_cell.plant) {
                            cell.plot_index = x_check_cell.plot_index;
                            area_list.items[x_check_cell.plot_index] += 1;
                            continue;
                        }
                    }
                }

                if (x_check) |x_check_cell| {
                    if (cell.plant == x_check_cell.plant) {
                        cell.plot_index = x_check_cell.plot_index;
                        area_list.items[x_check_cell.plot_index] += 1;
                        perimiter_list.items[x_check_cell.plot_index] += 2;
                        continue;
                    }
                }

                if (y_check) |y_check_cell| {
                    if (cell.plant == y_check_cell.plant) {
                        cell.plot_index = y_check_cell.plot_index;
                        area_list.items[y_check_cell.plot_index] += 1;
                        perimiter_list.items[y_check_cell.plot_index] += 2;
                        continue;
                    }
                }

                cell.plot_index = next_plot_index;
                next_plot_index += 1;
                try area_list.append(1);
                try perimiter_list.append(4);
            }
        }
    }

    return .{
        .areas = try area_list.toOwnedSlice(),
        .perimiters = try perimiter_list.toOwnedSlice(),
    };
}
