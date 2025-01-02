const std = @import("std");
const file = @import("../file-helpers.zig");
const Point = @import("../Point.zig").Point;

const Button = struct { input: u8, location: Point };

pub fn run(allocator: std.mem.Allocator) !void {
    const buffer = try allocator.alloc(u8, 25000);
    defer allocator.free(buffer);
    const input_length = try file.readFileToBuffer("input/day21.txt", buffer);

    std.debug.print(
        "Total complexity (part 1): {}\n",
        .{try runWithDepth(buffer[0 .. input_length - 1], 2, allocator)},
    );

    std.debug.print(
        "Total complexity (part 2): {}\n",
        .{try runWithDepth(buffer[0 .. input_length - 1], 25, allocator)},
    );
}

fn runWithDepth(input: []const u8, depth: usize, allocator: std.mem.Allocator) !usize {
    var lines = std.mem.splitSequence(u8, input, "\n");
    var previous_expansions = std.StringHashMap(usize).init(allocator);
    defer previous_expansions.clearAndFree();

    var total_complexity: usize = 0;
    while (lines.next()) |line| {
        var key_sequence = std.ArrayList(u8).init(allocator);
        defer key_sequence.clearAndFree();

        var keypad_arm_location = Point{ .x = 2, .y = 3 };
        var total_key_count: usize = 0;
        for (line) |input_character| {
            const new_key_sequence = try getNecessaryDirectionalInputsForNumberPad(
                keypad_arm_location,
                input_character,
                allocator,
            );

            total_key_count += try getExpandedInputCodeLength(
                new_key_sequence.input_sequence,
                depth,
                0,
                &previous_expansions,
                allocator,
            );
            keypad_arm_location = new_key_sequence.new_location;
        }

        const input_code = try key_sequence.toOwnedSlice();
        defer allocator.free(input_code);

        const mult = try std.fmt.parseInt(usize, line[0..3], 10);
        total_complexity += mult * total_key_count;
    }

    return total_complexity;
}

fn getExpandedInputCodeLength(
    input: []u8,
    max_depth: usize,
    depth: usize,
    previous_expansions: *std.StringHashMap(usize),
    allocator: std.mem.Allocator,
) !usize {
    if (depth == max_depth) {
        return input.len;
    }

    const index_string = try std.fmt.allocPrint(
        allocator,
        "{s}_{}",
        .{ input, depth },
    );

    if (previous_expansions.get(index_string)) |previous_value| {
        allocator.free(index_string);
        return previous_value;
    }

    var character_index: usize = 0;
    var take_count: usize = 0;
    var input_total: usize = 0;
    while (character_index < input.len) {
        if (input[character_index] != 'A') {
            character_index += 1;
            take_count += 1;
            continue;
        }

        if (take_count == 0) {
            input_total += 1;
            character_index += 1;
            continue;
        }

        const start_location = character_index - take_count;
        const inputs = input[start_location .. character_index + 1];

        const expanded_inputs = try getInputSequenceExpansion(inputs, allocator);
        defer allocator.free(expanded_inputs);

        input_total += try getExpandedInputCodeLength(
            expanded_inputs,
            max_depth,
            depth + 1,
            previous_expansions,
            allocator,
        );

        character_index += 1;
        take_count = 0;
    }

    try previous_expansions.put(index_string, input_total);

    return input_total;
}

const DIRECTIONAL_ARM_START = Point{ .x = 2, .y = 0 };

fn getInputSequenceExpansion(
    input_sequence: []const u8,
    allocator: std.mem.Allocator,
) ![]u8 {
    var new_inputs = std.ArrayList(u8).init(allocator);
    var current_location = DIRECTIONAL_ARM_START;
    for (input_sequence) |input| {
        const input_result = try getNecessaryDirectionalInputs(
            current_location,
            input,
            allocator,
        );

        try new_inputs.appendSlice(input_result.input_sequence);
        current_location = input_result.new_location;
    }

    return try new_inputs.toOwnedSlice();
}

const NUMBER_PAD = [11]Button{
    .{ .input = '7', .location = Point{ .x = 0, .y = 0 } },
    .{ .input = '8', .location = Point{ .x = 1, .y = 0 } },
    .{ .input = '9', .location = Point{ .x = 2, .y = 0 } },
    .{ .input = '4', .location = Point{ .x = 0, .y = 1 } },
    .{ .input = '5', .location = Point{ .x = 1, .y = 1 } },
    .{ .input = '6', .location = Point{ .x = 2, .y = 1 } },
    .{ .input = '1', .location = Point{ .x = 0, .y = 2 } },
    .{ .input = '2', .location = Point{ .x = 1, .y = 2 } },
    .{ .input = '3', .location = Point{ .x = 2, .y = 2 } },
    .{ .input = '0', .location = Point{ .x = 1, .y = 3 } },
    .{ .input = 'A', .location = Point{ .x = 2, .y = 3 } },
};

fn getNecessaryDirectionalInputsForNumberPad(
    current_location: Point,
    target_button: u8,
    allocator: std.mem.Allocator,
) !struct {
    input_sequence: []u8,
    new_location: Point,
} {
    var inputs = std.ArrayList(u8).init(allocator);

    const target_location = getKeyLocation(target_button, &NUMBER_PAD);
    const distance = target_location.sub(current_location);

    var x_key: u8 = '>';
    if (distance.x < 0) x_key = '<';
    var y_key: u8 = 'v';
    if (distance.y < 0) y_key = '^';

    if (current_location.y == 3 and target_location.x == 0) {
        try inputs.appendNTimes(y_key, @abs(distance.y));
        try inputs.appendNTimes(x_key, @abs(distance.x));
    } else if (current_location.x == 0 and target_location.y == 3) {
        try inputs.appendNTimes(x_key, @abs(distance.x));
        try inputs.appendNTimes(y_key, @abs(distance.y));
    } else if (distance.x < 0) {
        try inputs.appendNTimes(x_key, @abs(distance.x));
        try inputs.appendNTimes(y_key, @abs(distance.y));
    } else {
        try inputs.appendNTimes(y_key, @abs(distance.y));
        try inputs.appendNTimes(x_key, @abs(distance.x));
    }

    try inputs.append('A');

    return .{
        .input_sequence = try inputs.toOwnedSlice(),
        .new_location = target_location,
    };
}

const DIRECTIONAL_PAD = [5]Button{
    .{ .input = '^', .location = Point{ .x = 1, .y = 0 } },
    .{ .input = 'A', .location = Point{ .x = 2, .y = 0 } },
    .{ .input = '<', .location = Point{ .x = 0, .y = 1 } },
    .{ .input = 'v', .location = Point{ .x = 1, .y = 1 } },
    .{ .input = '>', .location = Point{ .x = 2, .y = 1 } },
};

fn getNecessaryDirectionalInputs(
    current_location: Point,
    target_button: u8,
    allocator: std.mem.Allocator,
) !struct {
    input_sequence: []u8,
    new_location: Point,
} {
    var inputs = std.ArrayList(u8).init(allocator);

    const target_location = getKeyLocation(target_button, &DIRECTIONAL_PAD);
    const distance = target_location.sub(current_location);

    var x_key: u8 = '>';
    if (distance.x < 0) x_key = '<';
    var y_key: u8 = 'v';
    if (distance.y < 0) y_key = '^';

    if (current_location.x == 0 and target_location.y == 0) {
        try inputs.appendNTimes(x_key, @abs(distance.x));
        try inputs.appendNTimes(y_key, @abs(distance.y));
    } else if (current_location.y == 0 and target_location.x == 0) {
        try inputs.appendNTimes(y_key, @abs(distance.y));
        try inputs.appendNTimes(x_key, @abs(distance.x));
    } else if (distance.x < 0) {
        try inputs.appendNTimes(x_key, @abs(distance.x));
        try inputs.appendNTimes(y_key, @abs(distance.y));
    } else {
        try inputs.appendNTimes(y_key, @abs(distance.y));
        try inputs.appendNTimes(x_key, @abs(distance.x));
    }

    try inputs.append('A');

    return .{
        .input_sequence = try inputs.toOwnedSlice(),
        .new_location = target_location,
    };
}

fn getKeyLocation(target_button: u8, keypad: []const Button) Point {
    for (keypad) |key| {
        if (key.input == target_button) return key.location;
    }

    unreachable;
}
