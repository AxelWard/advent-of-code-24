const std = @import("std");
const file = @import("../file-helpers.zig");

const CalibrationLine = struct {
    target: usize,
    inputs: []const usize,
};

pub fn run(allocator: std.mem.Allocator) !void {
    std.debug.print("Running AoC Day 7...\n\n", .{});

    const buffer = try allocator.alloc(u8, 30000);
    defer allocator.free(buffer);
    const input_length = try file.readFileToBuffer("input/day7.txt", buffer);

    const lines = (try readInputs(buffer[0..input_length], allocator));
    defer for (lines) |line| {
        allocator.free(line.inputs);
    };

    var valid_lines: usize = 0;
    for (lines) |line| {
        if (lineContainsValidCombo(line)) valid_lines += line.target;
    }

    std.debug.print("Total of valid lines (part 1): {}\n", .{valid_lines});
}

fn readInputs(input: []const u8, allocator: std.mem.Allocator) !([]CalibrationLine) {
    var lines = std.mem.splitSequence(u8, input, "\n");

    var calibration_lines = std.ArrayList(CalibrationLine).init(allocator);

    while (lines.next()) |line| {
        if (line.len != 0) {
            var line_parts = std.mem.splitSequence(u8, line, ": ");
            const line_target = try std.fmt.parseInt(usize, line_parts.first(), 10);

            if (line_parts.next()) |line_inputs| {
                var inputs = std.mem.splitSequence(u8, line_inputs, " ");
                var input_nums = std.ArrayList(usize).init(allocator);

                while (inputs.next()) |in_num| {
                    try input_nums.append(try std.fmt.parseInt(usize, in_num, 10));
                }

                try calibration_lines.append(CalibrationLine{
                    .target = line_target,
                    .inputs = try input_nums.toOwnedSlice(),
                });
            }
        }
    }

    return try calibration_lines.toOwnedSlice();
}

fn lineContainsValidCombo(input: CalibrationLine) bool {
    if (input.inputs.len == 0) {
        return false;
    }

    return false;
}
