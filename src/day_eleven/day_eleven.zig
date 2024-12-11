const std = @import("std");
const readFileToBuffer = @import("../file-helpers.zig").readFileToBuffer;
const progress = @import("../progress_logger.zig");

const NUM_SPLITS: usize = 75;

pub fn run(allocator: std.mem.Allocator) !void {
    const buffer = try allocator.alloc(u8, 20000);
    defer allocator.free(buffer);
    const input_length = try readFileToBuffer("input/day11.txt", buffer);

    var chunks = std.mem.splitSequence(u8, buffer[0 .. input_length - 1], " ");

    var stones = std.ArrayList([]const u8).init(allocator);
    defer stones.deinit();

    while (chunks.next()) |chunk| {
        if (chunk.len == 0) continue;
        try stones.append(chunk);
    }

    var total_stones: usize = 0;
    var known_splits = std.StringHashMap(usize).init(allocator);
    for (stones.items) |stone| total_stones += try splitStone(stone, NUM_SPLITS, &known_splits, allocator);

    std.debug.print("\nFinal stone count (part 2): {}\n", .{total_stones});
}

fn splitStone(
    stone: []const u8,
    splitsRemaining: usize,
    known_splits: *std.StringHashMap(usize),
    allocator: std.mem.Allocator,
) !usize {
    if (splitsRemaining == 0) return 1;

    const index_string = try std.fmt.allocPrint(
        allocator,
        "{s}-{}",
        .{ stone, splitsRemaining },
    );

    if (known_splits.get(index_string)) |value| return value;

    var stone_value: usize = 0;
    if (std.mem.eql(u8, stone, "0")) {
        stone_value = try splitStone("1", splitsRemaining - 1, known_splits, allocator);
    } else if (stone.len % 2 == 0) {
        const middle_index = stone.len / 2;
        var start_index: usize = 0;

        while (std.mem.eql(u8, &[1]u8{stone[start_index]}, "0") and start_index < middle_index - 1) {
            start_index += 1;
        }

        const stone_one = try splitStone(stone[start_index..middle_index], splitsRemaining - 1, known_splits, allocator);

        start_index = middle_index;
        while (std.mem.eql(u8, &[1]u8{stone[start_index]}, "0") and start_index < stone.len - 1) {
            start_index += 1;
        }

        stone_value = stone_one + try splitStone(stone[start_index..], splitsRemaining - 1, known_splits, allocator);
    } else {
        const stone_string = try std.fmt.allocPrint(
            allocator,
            "{}",
            .{try std.fmt.parseUnsigned(usize, stone, 10) * 2024},
        );
        defer allocator.free(stone_string);

        stone_value = try splitStone(stone_string, splitsRemaining - 1, known_splits, allocator);
    }

    try known_splits.put(index_string, stone_value);
    return stone_value;
}
