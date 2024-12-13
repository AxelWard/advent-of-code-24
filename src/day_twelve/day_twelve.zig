const std = @import("std");
const readFileToBuffer = @import("../file-helpers.zig").readFileToBuffer;

const Cell = struct {
    plant: u8,
    plot_index: usize,

    fn plantMatches(self: *Cell, rhs: ?*Cell) bool {
        if (rhs) |check_cell| {
            return self.plant == check_cell.plant;
        }

        return false;
    }

    fn plotMatches(self: *Cell, rhs: ?*Cell) bool {
        if (rhs) |check_cell| {
            return self.plot_index == check_cell.plot_index;
        }

        return false;
    }
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
        allocator.free(sizes.perimeters);
    }

    var total_plot_price: usize = 0;
    for (sizes.areas, 0..) |area, index| {
        total_plot_price += area * sizes.perimeters[index];
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

const PlotInfos = struct {
    next_plot_index: usize,
    area_list: std.ArrayList(usize),
    perimeter_list: std.ArrayList(usize),

    fn addNewPlot(self: *PlotInfos, init_cell: *Cell) !void {
        init_cell.plot_index = self.next_plot_index;
        self.next_plot_index += 1;

        try self.area_list.append(1);
        try self.perimeter_list.append(4);
    }

    fn combineGridPlots(self: *PlotInfos, grid: *Grid, destination_plot: usize, remove_plot: usize) void {
        for (0..grid.cells.len) |index| {
            if (grid.cells[index].plot_index == remove_plot) {
                grid.cells[index].plot_index = destination_plot;
            }
        }

        self.area_list.items[destination_plot] += self.area_list.items[remove_plot];
        self.perimeter_list.items[destination_plot] += self.perimeter_list.items[remove_plot];

        self.area_list.items[remove_plot] = 0;
        self.perimeter_list.items[remove_plot] = 0;
    }
};

fn getGardenPlotSizes(grid: *Grid, allocator: std.mem.Allocator) !struct {
    areas: []usize,
    perimeters: []usize,
} {
    var infos = PlotInfos{
        .next_plot_index = 0,
        .area_list = std.ArrayList(usize).init(allocator),
        .perimeter_list = std.ArrayList(usize).init(allocator),
    };

    for (0..grid.height) |y_index| {
        for (0..grid.width) |x_index| {
            const current_point = Point{
                .x = @as(isize, @intCast(x_index)),
                .y = @as(isize, @intCast(y_index)),
            };

            if (grid.getCell(current_point)) |cell| {
                const x_check = grid.getCell(current_point.add(Point{ .x = -1, .y = 0 }));
                const y_check = grid.getCell(current_point.add(Point{ .x = 0, .y = -1 }));

                if (cell.plantMatches(x_check) and cell.plantMatches(y_check)) {
                    cell.plot_index = x_check.?.plot_index;

                    if (x_check.?.plot_index != y_check.?.plot_index) {
                        infos.combineGridPlots(grid, x_check.?.plot_index, y_check.?.plot_index);
                    }

                    infos.area_list.items[cell.plot_index] += 1;
                } else if (cell.plantMatches(x_check)) {
                    cell.plot_index = x_check.?.plot_index;

                    infos.area_list.items[cell.plot_index] += 1;
                    infos.perimeter_list.items[cell.plot_index] += 2;
                } else if (cell.plantMatches(y_check)) {
                    cell.plot_index = y_check.?.plot_index;

                    infos.area_list.items[cell.plot_index] += 1;
                    infos.perimeter_list.items[cell.plot_index] += 2;
                } else {
                    try infos.addNewPlot(cell);
                }
            }
        }
    }

    return .{
        .areas = try infos.area_list.toOwnedSlice(),
        .perimeters = try infos.perimeter_list.toOwnedSlice(),
    };
}
