const std = @import("std");
const file = @import("../file-helpers.zig");

pub fn run(allocator: std.mem.Allocator) !void {
    std.debug.print("Running AoC Day 2...\n\n", .{});

    const buffer = try allocator.alloc(u8, 32768);
    defer allocator.free(buffer);
    const input_length = try file.readFileToBuffer("input/day2.txt", buffer);

    var lines = std.mem.splitSequence(u8, buffer[0..input_length], "\n");

    var safe_reports: i64 = 0;
    var safe_reports_with_tolerance: i64 = 0;
    var line_index: usize = 1;
    while (lines.next()) |line| : (line_index += 1) {
        if (line.len != 0) {
            var line_chunks = std.mem.splitSequence(u8, line, " ");
            var line_data = std.ArrayList(i64).init(allocator);

            while (line_chunks.next()) |chunk| {
                try line_data.append(try std.fmt.parseInt(i64, chunk, 10));
            }

            const line_array = try line_data.toOwnedSlice();
            defer allocator.free(line_array);

            if (!checkLineHasError(line_array)) {
                safe_reports += 1;
            }
            if (try checkLineValidWithTolerance(line_array, allocator)) {
                safe_reports_with_tolerance += 1;
            }
        }
    }

    std.debug.print("Safe reports: {}\n", .{safe_reports});
    std.debug.print("Safe reports with tolerance: {}\n", .{safe_reports_with_tolerance});
}

fn checkLineValidWithTolerance(line_array: []const i64, allocator: std.mem.Allocator) !bool {
    if (checkLineHasError(line_array)) {
        for (0..line_array.len) |remove| {
            var first_set = try std.ArrayList(i64).initCapacity(allocator, line_array.len - 1);
            try first_set.appendSlice(line_array[0..remove]);
            try first_set.appendSlice(line_array[remove + 1 ..]);

            const first_array = try first_set.toOwnedSlice();
            defer allocator.free(first_array);

            if (!checkLineHasError(first_array)) return true;
        }

        return false;
    }

    return true;
}

fn checkLineHasError(line: []const i64) bool {
    var increasing: ?bool = null;
    for (line[0 .. line.len - 1], 0..) |last_val, index| {
        const next_val = line[index + 1];
        const diff = last_val - next_val;

        if (diff == 0 or diff > 3 or diff < -3) {
            return true;
        }

        if (increasing) |inc| {
            if (inc and diff > 0) {
                continue;
            } else if (!inc and diff < 0) {
                continue;
            } else {
                return true;
            }
        } else {
            if (diff > 0) {
                increasing = true;
            } else {
                increasing = false;
            }
        }
    }

    return false;
}
