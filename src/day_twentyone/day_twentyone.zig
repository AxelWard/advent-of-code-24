const std = @import("std");
const file = @import("../file-helpers.zig");
const Point = @import("../Point.zig").Point;

pub fn run(allocator: std.mem.Allocator) !void {
    const buffer = try allocator.alloc(u8, 25000);
    defer allocator.free(buffer);
    const input_length = try file.readFileToBuffer("input/day21_test.txt", buffer);

    var lines = std.mem.splitSequence(u8, buffer[0 .. input_length - 1], "\n");

    var total_complexity: usize = 0;
    while (lines.next()) |line| {
        const input_code = try getInputCode(line, allocator);
        defer allocator.free(input_code);

        const complexity_to_add = try std.fmt.parseInt(usize, line[0..3], 10) * input_code.len;
        total_complexity += complexity_to_add;

        std.debug.print("For input {s} got {} complexity key sequence ({s} {})\n", .{ line, complexity_to_add, line[0..3], input_code.len });
    }

    std.debug.print("Total complexity (part 1): {} (< 181454)\n", .{total_complexity});
}

const Button = struct { input: u8, location: Point };
const Keypad = struct { buttons: []const Button, disallowed_location: Point };

const NumberPad = Keypad{
    .buttons = &[11]Button{
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
    },
    .disallowed_location = Point{ .x = 0, .y = 3 },
};

const DirectionalPad = Keypad{
    .buttons = &[5]Button{
        .{ .input = '^', .location = Point{ .x = 1, .y = 0 } },
        .{ .input = 'A', .location = Point{ .x = 2, .y = 0 } },
        .{ .input = '<', .location = Point{ .x = 0, .y = 1 } },
        .{ .input = 'v', .location = Point{ .x = 1, .y = 1 } },
        .{ .input = '>', .location = Point{ .x = 2, .y = 1 } },
    },
    .disallowed_location = Point{ .x = 0, .y = 0 },
};

const DIRECTIONAL_ARM_COUNT: usize = 2;
const DIRECTIONAL_ARM_START = Point{ .x = 2, .y = 0 };

// REWORK THIS SHIT TO BE RECURSIVE

fn getInputCode(input: []const u8, allocator: std.mem.Allocator) ![]u8 {
    var keypad_arm_location = Point{ .x = 2, .y = 3 };

    var key_sequence = std.ArrayList(u8).init(allocator);

    for (input) |input_character| {
        const new_key_sequence = try getNecessaryDirectionalInputs(
            keypad_arm_location,
            input_character,
            NumberPad,
            allocator,
        );

        keypad_arm_location = new_key_sequence.new_location;
        try key_sequence.appendSlice(new_key_sequence.input_sequence);
    }

    std.debug.print("\nInitial input sequence:\n{s}\n", .{key_sequence.items});

    for (0..DIRECTIONAL_ARM_COUNT) |arm_index| {
        var character_index: usize = 0;
        var take_count: usize = 0;
        while (character_index < key_sequence.items.len) {
            if (key_sequence.items[character_index] != 'A') {
                character_index += 1;
                take_count += 1;
                continue;
            }

            if (take_count == 0) {
                character_index += 1;
                continue;
            }

            const start_location = character_index - take_count;
            const inputs = key_sequence.items[start_location .. character_index + 1];
            const reordered_inputs = try reorderInputs(inputs, allocator);

            var expanded_inputs = try expandInputSequence(DIRECTIONAL_ARM_START, inputs, DirectionalPad, allocator);

            if (!std.mem.eql(u8, inputs, reordered_inputs)) {
                std.debug.print("Reorder for {s} is {s}\n", .{ inputs, reordered_inputs });
                const expanded_reordered_inputs = try expandInputSequence(DIRECTIONAL_ARM_START, reordered_inputs, DirectionalPad, allocator);
                const reordered_rating = calculateInputDistanceRating(
                    DIRECTIONAL_ARM_START,
                    expanded_reordered_inputs,
                    DirectionalPad,
                );

                const inputs_rating = calculateInputDistanceRating(
                    DIRECTIONAL_ARM_START,
                    expanded_inputs,
                    DirectionalPad,
                );

                std.debug.print("Comparing {s} ({d}) to {s} ({d})\n", .{ expanded_inputs, inputs_rating, expanded_reordered_inputs, reordered_rating });

                if (reordered_rating < inputs_rating) {
                    allocator.free(expanded_inputs);
                    expanded_inputs = expanded_reordered_inputs;
                }
            }

            try key_sequence.replaceRange(
                start_location,
                inputs.len,
                expanded_inputs,
            );

            character_index += expanded_inputs.len - take_count;
            take_count = 0;
        }

        std.debug.print("Arm {} expanded sequence to:\n{s}\n", .{ arm_index, key_sequence.items });
    }

    return key_sequence.toOwnedSlice();
}

pub fn reorderInputs(
    input_sequence: []const u8,
    allocator: std.mem.Allocator,
) ![]u8 {
    var characters = std.ArrayList(u8).init(allocator);
    var character_counts = std.ArrayList(usize).init(allocator);
    defer characters.deinit();
    defer character_counts.deinit();

    for (input_sequence[0 .. input_sequence.len - 1]) |character| {
        if (characters.items.len != 0 and characters.items[0] == character) {
            character_counts.items[0] += 1;
        } else {
            try characters.insert(0, character);
            try character_counts.insert(0, 1);
        }
    }

    var new_characters = std.ArrayList(u8).init(allocator);
    for (characters.items, 0..) |next_character, index| {
        try new_characters.appendNTimes(next_character, character_counts.items[index]);
    }
    try new_characters.append('A');

    return try new_characters.toOwnedSlice();
}

fn expandInputSequence(
    start_location: Point,
    input_sequence: []const u8,
    keypad: Keypad,
    allocator: std.mem.Allocator,
) ![]const u8 {
    var new_inputs = std.ArrayList(u8).init(allocator);
    var current_location = start_location;
    for (input_sequence) |input| {
        const input_result = try getNecessaryDirectionalInputs(
            current_location,
            input,
            keypad,
            allocator,
        );

        try new_inputs.appendSlice(input_result.input_sequence);
        current_location = input_result.new_location;
    }

    return try new_inputs.toOwnedSlice();
}

fn getNecessaryDirectionalInputs(
    current_location: Point,
    target_button: u8,
    keypad: Keypad,
    allocator: std.mem.Allocator,
) !struct {
    input_sequence: []const u8,
    new_location: Point,
} {
    var inputs = std.ArrayList(u8).init(allocator);

    var key_location = current_location;
    if (getKeyLocation(target_button, keypad)) |target_location| {
        key_location = target_location;
        const distance = key_location.sub(current_location);

        if (!current_location.add(Point{ .x = distance.x, .y = 0 }).eq(keypad.disallowed_location)) {
            var current_key: u8 = '>';
            if (distance.x < 0) current_key = '<';
            try inputs.appendNTimes(current_key, @abs(distance.x));

            current_key = 'v';
            if (distance.y < 0) current_key = '^';
            try inputs.appendNTimes(current_key, @abs(distance.y));
        } else {
            var current_key: u8 = 'v';
            if (distance.y < 0) current_key = '^';
            try inputs.appendNTimes(current_key, @abs(distance.y));

            current_key = '>';
            if (distance.x < 0) current_key = '<';
            try inputs.appendNTimes(current_key, @abs(distance.x));
        }
    }

    try inputs.append('A');

    return .{
        .input_sequence = try inputs.toOwnedSlice(),
        .new_location = key_location,
    };
}

fn calculateInputDistanceRating(start_location: Point, input_sequence: []const u8, keypad: Keypad) f64 {
    var current_location = start_location;
    var distance_rating: f64 = 0;
    for (input_sequence) |next_key| {
        if (getKeyLocation(next_key, keypad)) |next_key_location| {
            distance_rating += current_location.distance(next_key_location);
            current_location = next_key_location;
        }
    }

    return distance_rating;
}

fn getKeyLocation(target_button: u8, keypad: Keypad) ?Point {
    for (keypad.buttons) |key| {
        if (key.input == target_button) return key.location;
    }

    return null;
}
