const math = @import("std").math;

pub const Point = struct {
    x: isize,
    y: isize,

    pub fn add(self: *const Point, rhs: Point) Point {
        return Point{ .x = self.x + rhs.x, .y = self.y + rhs.y };
    }

    pub fn sub(self: *const Point, rhs: Point) Point {
        return Point{ .x = self.x - rhs.x, .y = self.y - rhs.y };
    }

    pub fn mult(self: *const Point, rhs: isize) Point {
        return Point{ .x = self.x * rhs, .y = self.y * rhs };
    }

    pub fn eq(self: *const Point, rhs: Point) bool {
        return self.x == rhs.x and self.y == rhs.y;
    }

    pub fn distance(self: *const Point, rhs: Point) f64 {
        const dist_point = self.sub(rhs);
        return @sqrt(
            math.pow(f64, @floatFromInt(dist_point.x), 2.0) + math.pow(f64, @floatFromInt(dist_point.y), 2.0),
        );
    }
};
