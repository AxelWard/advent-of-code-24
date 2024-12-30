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

    std.debug.print("Total complexity (part 1): {}\n", .{total_complexity});
}

const Button = struct { input: u8, location: Point };

const KeypadLocations: [11]Button = [11]Button{
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

const DirectionalPadLocations: [5]Button = [5]Button{
    .{ .input = '^', .location = Point{ .x = 1, .y = 0 } },
    .{ .input = 'A', .location = Point{ .x = 2, .y = 0 } },
    .{ .input = '<', .location = Point{ .x = 0, .y = 1 } },
    .{ .input = 'v', .location = Point{ .x = 1, .y = 1 } },
    .{ .input = '>', .location = Point{ .x = 2, .y = 1 } },
};

const DIRECTIONAL_ARM_COUNT: usize = 2;
const DIRECTIONAL_ARM_START = Point{ .x = 2, .y = 0 };

fn getInputCode(input: []const u8, allocator: std.mem.Allocator) ![]u8 {
    var keypad_arm_location = Point{ .x = 2, .y = 3 };

    var key_sequence = std.ArrayList(u8).init(allocator);

    for (input) |input_character| {
        const new_key_sequence = try getNecessaryDirectionalInputs(
            keypad_arm_location,
            input_character,
            &KeypadLocations,
            allocator,
        );

        keypad_arm_location = new_key_sequence.new_location;
        try key_sequence.appendSlice(new_key_sequence.input_sequence);
    }

    std.debug.print("\nInitial input sequence:\n{s}\n", .{key_sequence.items});

    for (0..DIRECTIONAL_ARM_COUNT) |arm_index| {
        var arm_location = DIRECTIONAL_ARM_START;

        var move_keys = std.mem.splitSequence(u8, key_sequence.items, "A");

        var start = move_keys.index orelse 0;
        while (move_keys.next()) |reorder| : (start = move_keys.index orelse 0) {
            if (reorder.len == 0) continue;

            try key_sequence.replaceRange(
                start,
                reorder.len,
                try reorderInputsByDistance(reorder, &DirectionalPadLocations, allocator),
            );
        }

        std.debug.print("Arm {} reordered sequence to:\n{s}\n", .{ arm_index, key_sequence.items });

        var character_index: usize = 0;
        while (character_index < key_sequence.items.len) {
            const new_key_sequence = try getNecessaryDirectionalInputs(
                arm_location,
                key_sequence.items[character_index],
                &DirectionalPadLocations,
                allocator,
            );

            try key_sequence.replaceRange(character_index, 1, new_key_sequence.input_sequence);

            arm_location = new_key_sequence.new_location;
            character_index += new_key_sequence.input_sequence.len;
        }
        std.debug.print("Arm {} expanded sequence to:\n{s}\n", .{ arm_index, key_sequence.items });
    }

    return key_sequence.toOwnedSlice();
}

const InputReorderEntry = struct {
    character: u8,
    count: usize,
    location: Point,
};

fn ireLessThan(context: Point, a: InputReorderEntry, b: InputReorderEntry) std.math.Order {
    return std.math.order(a.location.distance(context), b.location.distance(context));
}

pub fn reorderInputsByDistance(
    input_sequence: []const u8,
    keypad: []const Button,
    allocator: std.mem.Allocator,
) ![]u8 {
    var characters = std.AutoHashMap(u8, usize).init(allocator);
    defer characters.deinit();

    for (input_sequence) |character| {
        const previous = characters.fetchRemove(character);
        if (previous) |prev| {
            try characters.put(character, prev.value + 1);
        } else {
            try characters.put(character, 1);
        }
    }

    var character_iterator = characters.iterator();
    var character_queue = std.PriorityQueue(InputReorderEntry, Point, ireLessThan).init(allocator, DIRECTIONAL_ARM_START);
    defer character_queue.deinit();

    while (character_iterator.next()) |character| {
        if (getKeyLocation(character.key_ptr.*, keypad)) |target_location| {
            try character_queue.add(InputReorderEntry{
                .character = character.key_ptr.*,
                .count = character.value_ptr.*,
                .location = target_location,
            });
        }
    }

    var new_characters = std.ArrayList(u8).init(allocator);
    while (character_queue.removeOrNull()) |next_character| {
        try new_characters.appendNTimes(next_character.character, next_character.count);
    }

    return try new_characters.toOwnedSlice();
}

fn getNecessaryDirectionalInputs(
    current_location: Point,
    target_button: u8,
    keypad: []const Button,
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

        if (distance.y < 0) {
            var current_key: u8 = '>';
            if (distance.x < 0) current_key = '<';
            try inputs.appendNTimes(current_key, @abs(distance.x));

            current_key = '^';
            try inputs.appendNTimes(current_key, @abs(distance.y));
        } else {
            var current_key: u8 = 'v';
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

fn getKeyLocation(target_button: u8, keypad: []const Button) ?Point {
    for (keypad) |key| {
        if (key.input == target_button) return key.location;
    }

    return null;
}
