const std = @import("std");
const readFileToBuffer = @import("../file-helpers.zig").readFileToBuffer;
const Point = @import("../Point.zig").Point;

const CellType = enum { Empty, BoxLeft, BoxRight, Wall, Player };

const Grid = @import("../Grid.zig").Grid(CellType);
var step_index: usize = 1;

pub fn run(allocator: std.mem.Allocator) !void {
    const buffer = try allocator.alloc(u8, 30000);
    defer allocator.free(buffer);
    const input_length = try readFileToBuffer("input/day15.txt", buffer);

    var lines = std.mem.splitSequence(u8, buffer[0 .. input_length - 1], "\n");
    const grid_width = lines.first().len;
    lines.reset();

    var cell_list = std.ArrayList(CellType).init(allocator);
    var current_location = Point{
        .x = 0,
        .y = 0,
    };

    var y_index: usize = 0;
    while (lines.next()) |line| : (y_index += 1) {
        if (line.len == 0) break;

        try cell_list.ensureUnusedCapacity(line.len * 2);
        for (line, 0..) |character, x_index| {
            if (character == 'O') {
                try cell_list.appendSlice(&[2]CellType{ CellType.BoxLeft, CellType.BoxRight });
            } else if (character == '#') {
                try cell_list.appendSlice(&[2]CellType{ CellType.Wall, CellType.Wall });
            } else if (character == '@') {
                current_location.x = @as(isize, @intCast(x_index * 2));
                current_location.y = @as(isize, @intCast(y_index));
                try cell_list.appendSlice(&[2]CellType{ CellType.Player, CellType.Empty });
            } else {
                try cell_list.appendSlice(&[2]CellType{ CellType.Empty, CellType.Empty });
            }
        }
    }

    var grid = Grid{
        .cells = try cell_list.toOwnedSlice(),
        .width = grid_width * 2,
        .height = y_index,
    };
    defer allocator.free(grid.cells);

    while (lines.next()) |line| {
        for (line) |character| {
            if (character == '>') {
                try runStep(&grid, &current_location, Point{ .x = 1, .y = 0 }, allocator);
            } else if (character == '^') {
                try runStep(&grid, &current_location, Point{ .x = 0, .y = -1 }, allocator);
            } else if (character == '<') {
                try runStep(&grid, &current_location, Point{ .x = -1, .y = 0 }, allocator);
            } else if (character == 'v') {
                try runStep(&grid, &current_location, Point{ .x = 0, .y = 1 }, allocator);
            } else {
                continue;
            }
            step_index += 1;
        }
    }

    std.debug.print("Lanternfish GPS total: {}\n", .{calculateGridGpsSum(&grid)});
}

// Debug troubleshooting helper
fn printGrid(grid: *Grid, allocator: std.mem.Allocator) !void {
    var grid_string = try allocator.alloc(u8, grid.cells.len + grid.height);
    defer allocator.free(grid_string);

    for (0..grid.height) |y_index| {
        for (0..grid.width) |x_index| {
            const set_index = (y_index * grid.width) + x_index + y_index;
            if (grid.getCell(Point{ .x = @intCast(x_index), .y = @intCast(y_index) })) |cell| {
                switch (cell.*) {
                    CellType.Empty => grid_string[set_index] = ' ',
                    CellType.Player => grid_string[set_index] = '@',
                    CellType.BoxLeft => grid_string[set_index] = '[',
                    CellType.BoxRight => grid_string[set_index] = ']',
                    CellType.Wall => grid_string[set_index] = '#',
                }
            }
        }

        grid_string[(y_index * grid.width) + grid.width + y_index] = '\n';
    }

    std.debug.print("{s}\n", .{grid_string});
}

fn runStep(grid: *Grid, current_location: *Point, step: Point, allocator: std.mem.Allocator) !void {
    if (grid.getCell(current_location.add(step))) |cell| {
        if (cell.* == CellType.Wall) return;

        if (cell.* == CellType.BoxLeft) {
            if (try getBoxesToPush(grid, current_location.add(Point{ .x = step.x, .y = step.y }), step, allocator)) |boxes| {
                try pushBoxes(grid, boxes, step, allocator);
                allocator.free(boxes);
            } else {
                return;
            }
        } else if (cell.* == CellType.BoxRight) {
            if (try getBoxesToPush(grid, current_location.add(Point{ .x = step.x - 1, .y = step.y }), step, allocator)) |boxes| {
                try pushBoxes(grid, boxes, step, allocator);
                allocator.free(boxes);
            } else {
                return;
            }
        }

        grid.setCell(current_location.*, CellType.Empty);
        grid.setCell(current_location.add(step), CellType.Player);

        const next_location = current_location.add(step);
        current_location.x = next_location.x;
        current_location.y = next_location.y;
    }
}

fn getBoxesToPush(grid: *Grid, boxToCheckLeft: Point, direction: Point, allocator: std.mem.Allocator) !?[]Point {
    if (direction.x != 0) return try getBoxesToPushX(grid, boxToCheckLeft, direction, allocator);
    return try getBoxesToPushY(grid, boxToCheckLeft, direction, allocator);
}

fn getBoxesToPushX(grid: *Grid, boxToCheckLeft: Point, direction: Point, allocator: std.mem.Allocator) !?[]Point {
    var pushed_boxes: ?[]Point = null;
    var pushed = false;
    if (grid.getCell(boxToCheckLeft.add(direction))) |left_check| {
        if (grid.getCell(boxToCheckLeft.add(Point{ .x = 1, .y = 0 }).add(direction))) |right_check| {
            if (left_check.* == CellType.Wall or right_check.* == CellType.Wall) return null;

            if ((direction.x == -1 and left_check.* == CellType.BoxRight) or
                (direction.x == 1 and right_check.* == CellType.BoxLeft))
            {
                pushed = true;
                pushed_boxes = try getBoxesToPushX(grid, boxToCheckLeft.add(direction).add(direction), direction, allocator);
            }
        }
    }

    if (pushed and pushed_boxes == null) {
        return null;
    }

    var total_size: usize = 0;
    if (pushed_boxes) |boxes| {
        total_size += boxes.len;
    }
    var boxes_to_push = try allocator.alloc(Point, total_size + 2);

    if (pushed_boxes) |boxes| {
        @memcpy(boxes_to_push[0..boxes.len], boxes);
    }

    if (direction.x == -1) {
        boxes_to_push[boxes_to_push.len - 2] = boxToCheckLeft;
        boxes_to_push[boxes_to_push.len - 1] = boxToCheckLeft.add(Point{ .x = 1, .y = 0 });
    } else {
        boxes_to_push[boxes_to_push.len - 2] = boxToCheckLeft.add(Point{ .x = 1, .y = 0 });
        boxes_to_push[boxes_to_push.len - 1] = boxToCheckLeft;
    }

    return boxes_to_push;
}

fn getBoxesToPushY(grid: *Grid, boxToCheckLeft: Point, direction: Point, allocator: std.mem.Allocator) !?[]Point {
    var left_push: ?[]Point = null;
    var right_push: ?[]Point = null;
    var ignore_left = true;
    var ignore_right = true;

    if (grid.getCell(boxToCheckLeft.add(direction))) |left_check| {
        if (grid.getCell(boxToCheckLeft.add(direction).add(Point{ .x = 1, .y = 0 }))) |right_check| {
            if (left_check.* == CellType.Wall or right_check.* == CellType.Wall) return null;

            if (left_check.* == CellType.BoxLeft) {
                left_push = try getBoxesToPushY(grid, boxToCheckLeft.add(direction), direction, allocator);
                ignore_left = false;
            } else {
                if (left_check.* == CellType.BoxRight) {
                    left_push = try getBoxesToPushY(grid, boxToCheckLeft.add(direction).add(Point{ .x = -1, .y = 0 }), direction, allocator);
                    ignore_left = false;
                }

                if (right_check.* == CellType.BoxLeft) {
                    right_push = try getBoxesToPushY(grid, boxToCheckLeft.add(direction).add(Point{ .x = 1, .y = 0 }), direction, allocator);
                    ignore_right = false;
                }
            }
        }
    }

    if ((!ignore_right and right_push == null) or (!ignore_left and left_push == null)) {
        if (right_push) |right| {
            allocator.free(right);
        }

        if (left_push) |left| {
            allocator.free(left);
        }

        return null;
    }

    var total_size: usize = 0;
    if (left_push) |left| {
        total_size += left.len;
    }
    if (right_push) |right| {
        total_size += right.len;
    }

    var boxes_to_push = try allocator.alloc(Point, total_size + 2);
    var start_index: usize = 0;
    if (left_push) |left| {
        @memcpy(boxes_to_push[0..left.len], left);
        start_index = left.len;
    }

    if (right_push) |right| {
        @memcpy(boxes_to_push[start_index .. start_index + right.len], right);
    }

    boxes_to_push[boxes_to_push.len - 2] = boxToCheckLeft;
    boxes_to_push[boxes_to_push.len - 1] = boxToCheckLeft.add(Point{ .x = 1, .y = 0 });

    return boxes_to_push;
}

const arrayListContainsValue = @import("../array_list_helpers.zig").arrayListContainsValue(
    Point,
    Point,
    struct {
        fn eqfn(a: Point, b: Point) bool {
            return a.x == b.x and a.y == b.y;
        }
    }.eqfn,
);

fn pushBoxes(grid: *Grid, boxesToPush: []const Point, direction: Point, allocator: std.mem.Allocator) !void {
    var boxesPushed = std.ArrayList(Point).init(allocator);

    for (boxesToPush) |box| {
        if (!arrayListContainsValue(&boxesPushed, box)) {
            if (grid.getCellValue(box)) |old_cell| {
                grid.setCell(box.add(direction), old_cell);
                grid.setCell(box, CellType.Empty);
            }

            try boxesPushed.append(box);
        }
    }
}

fn calculateGridGpsSum(grid: *Grid) usize {
    var gps_total: usize = 0;
    for (1..grid.height) |y_index| {
        for (1..grid.width) |x_index| {
            if (grid.getCell(Point{ .x = @intCast(x_index), .y = @intCast(y_index) })) |cell| {
                if (cell.* == CellType.BoxLeft) {
                    gps_total += (100 * y_index) + x_index;
                }
            }
        }
    }

    return gps_total;
}
