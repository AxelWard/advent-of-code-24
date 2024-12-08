const std = @import("std");
const file = @import("../file-helpers.zig");
const progress = @import("../progress_logger.zig");

const CalibrationLine = struct {
    target: usize,
    inputs: []const usize,
};

const Operator = enum { add, mult, concat };

pub fn run(allocator: std.mem.Allocator) !void {
    const buffer = try allocator.alloc(u8, 30000);
    defer allocator.free(buffer);
    const input_length = try file.readFileToBuffer("input/day7.txt", buffer);

    const lines = (try readInputs(buffer[0..input_length], allocator));
    defer for (lines) |line| {
        allocator.free(line.inputs);
    };

    var valid_lines: usize = 0;
    var valid_lines_with_concat: usize = 0;

    progress.logProgressStart();
    for (lines, 1..) |line, index| {
        progress.logProgress(index, lines.len);

        if (try lineIsValid(
            line.target,
            line.inputs,
            &[2]Operator{ Operator.add, Operator.mult },
            allocator,
        )) valid_lines += line.target;
        if (try lineIsValid(
            line.target,
            line.inputs,
            &[3]Operator{ Operator.add, Operator.mult, Operator.concat },
            allocator,
        )) valid_lines_with_concat += line.target;
    }

    std.debug.print("\n\nTotal of valid lines (part 1): {}\n", .{valid_lines});
    std.debug.print("Total of valid lines (part 2): {}\n", .{valid_lines_with_concat});
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

fn lineIsValid(
    target: usize,
    inputs: []const usize,
    operators_to_try: []const Operator,
    allocator: std.mem.Allocator,
) !bool {
    if (inputs.len == 0 or inputs[0] > target) {
        return false;
    } else if (inputs.len == 1) {
        return inputs[0] == target;
    }

    for (operators_to_try) |operator| {
        var new_input = inputs[0];

        if (operator == Operator.mult) {
            new_input *= inputs[1];
        } else if (operator == Operator.concat) {
            const new_str = try std.fmt.allocPrint(
                allocator,
                "{}{}",
                .{ new_input, inputs[1] },
            );
            defer allocator.free(new_str);

            new_input = try std.fmt.parseInt(
                usize,
                new_str,
                10,
            );
        } else {
            new_input += inputs[1];
        }

        var new_inputs = try allocator.alloc(usize, inputs.len - 1);
        defer allocator.free(new_inputs);

        new_inputs[0] = new_input;
        if (inputs.len > 2) {
            for (inputs[2..], 1..) |input, index| new_inputs[index] = input;
        }

        if (try lineIsValid(target, new_inputs, operators_to_try, allocator)) {
            return true;
        }
    }

    return false;
}
