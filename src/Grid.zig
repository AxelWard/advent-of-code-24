const Point = @import("Point.zig").Point;

pub fn Grid(comptime T: type) type {
    return struct {
        cells: []T,
        width: usize,
        height: usize,

        pub fn getCell(self: *Grid(T), position: Point) ?*T {
            if (position.x < 0 or
                position.y < 0 or
                position.x >= self.width or
                position.y >= self.height) return null;

            return &self.cells[
                (@as(usize, @intCast(position.y)) * self.width) + @as(usize, @intCast(position.x))
            ];
        }

        pub fn getCellValue(self: *Grid(T), position: Point) ?T {
            if (position.x < 0 or
                position.y < 0 or
                position.x >= self.width or
                position.y >= self.height) return null;

            return self.cells[
                (@as(usize, @intCast(position.y)) * self.width) + @as(usize, @intCast(position.x))
            ];
        }

        pub fn setCell(self: *Grid(T), position: Point, new_cell: T) void {
            self.cells[
                (@as(usize, @intCast(position.y)) * self.width) + @as(usize, @intCast(position.x))
            ] = new_cell;
        }
    };
}
