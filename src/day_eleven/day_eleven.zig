const std = @import("std");
const readFileToBuffer = @import("../file-helpers.zig").readFileToBuffer;
const progress = @import("../progress_logger.zig");

const NUM_SPLITS: usize = 25;

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

    progress.logProgressStart();
    try splitStones(NUM_SPLITS, &stones, allocator);

    std.debug.print("\nFinal stone count (part 1): {}\n", .{stones.items.len});
}

fn splitStones(
    splitsRemaining: usize,
    stones: *std.ArrayList([]const u8),
    allocator: std.mem.Allocator,
) !void {
    progress.logProgress(NUM_SPLITS - splitsRemaining, NUM_SPLITS);
    if (splitsRemaining == 0) return;

    var index: usize = 0;
    while (index < stones.items.len) {
        const stone = stones.items[index];
        if (std.mem.eql(u8, stone, "0")) {
            try stones.replaceRange(index, 1, &[1][]const u8{"1"});
            index += 1;
        } else if (stone.len % 2 == 0) {
            const middle_index = stone.len / 2;
            var start_index: usize = 0;
            while (std.mem.eql(u8, &[1]u8{stone[start_index]}, "0") and start_index < middle_index - 1) {
                start_index += 1;
            }
            try stones.replaceRange(index, 1, &[1][]const u8{stone[start_index..middle_index]});

            start_index = middle_index;
            while (std.mem.eql(u8, &[1]u8{stone[start_index]}, "0") and start_index < stone.len - 1) {
                start_index += 1;
            }
            try stones.insert(index + 1, stone[start_index..]);
            index += 2;
        } else {
            const stone_string = try std.fmt.allocPrint(
                allocator,
                "{}",
                .{try std.fmt.parseUnsigned(usize, stone, 10) * 2024},
            );
            try stones.replaceRange(index, 1, &[1][]const u8{stone_string});
            index += 1;
        }
    }

    try splitStones(splitsRemaining - 1, stones, allocator);
}
