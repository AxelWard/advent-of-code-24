const std = @import("std");
const file = @import("../file-helpers.zig");

pub fn run(allocator: std.mem.Allocator) !void {
    const buffer = try allocator.alloc(u8, 25000);
    defer allocator.free(buffer);
    const input_length = try file.readFileToBuffer("input/day19.txt", buffer);

    var lines = std.mem.splitSequence(u8, buffer[0 .. input_length - 1], "\n");
    var pattern_splits = std.mem.splitSequence(u8, lines.first(), ", ");

    var pattern_list = std.ArrayList([]const u8).init(allocator);
    defer pattern_list.deinit();

    while (pattern_splits.next()) |pattern| {
        try addPattern(pattern, &pattern_list);
    }

    const patterns = try pattern_list.toOwnedSlice();

    defer allocator.free(patterns);

    _ = lines.next();
    var patterns_to_test = std.ArrayList([]const u8).init(allocator);
    defer patterns_to_test.deinit();
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        try patterns_to_test.append(line);
    }

    var possible: usize = 0;
    var num_arrangements: usize = 0;
    for (patterns_to_test.items) |pattern_to_test| {
        var previously_found = std.AutoHashMap(usize, usize).init(allocator);
        try previously_found.put(0, 1);
        defer previously_found.deinit();

        const result = try getPossibleArrangements(pattern_to_test, patterns, &previously_found);
        num_arrangements += result;
        if (result > 0) possible += 1;
    }

    std.debug.print("\nPossible design count (part 1): {}\n", .{possible});
    std.debug.print("Possible arrangement count (part 2): {}\n", .{num_arrangements});
}

fn addPattern(pattern: []const u8, patterns: *std.ArrayList([]const u8)) !void {
    if (pattern.len == 0) return;

    try patterns.append(pattern);
    const child = patterns.getLast();
    var child_index = patterns.items.len - 1;
    while (child_index > 0) {
        const parent_index = child_index - 1;
        const parent = patterns.items[parent_index];
        if (parent.len >= child.len) break;
        patterns.items[child_index] = parent;
        child_index = parent_index;
    }
    patterns.items[child_index] = child;
}

const PatternMatchResult = struct {
    length: usize,
    index: usize,
};

fn getPossibleArrangements(
    pattern: []const u8,
    patterns: [][]const u8,
    previously_found: *std.AutoHashMap(usize, usize),
) !usize {
    if (previously_found.get(pattern.len)) |previous_result| {
        return previous_result;
    }

    var search_start: usize = 0;
    var num_found: usize = 0;
    while (getLongestPatternMatch(pattern, patterns, search_start)) |result| {
        num_found += try getPossibleArrangements(pattern[result.length..], patterns, previously_found);
        search_start = result.index + 1;
    }

    try previously_found.put(pattern.len, num_found);
    return num_found;
}

fn getLongestPatternMatch(
    remaining_input: []const u8,
    patterns: [][]const u8,
    search_start: usize,
) ?PatternMatchResult {
    if (search_start == patterns.len) return null;

    for (patterns[search_start..], search_start..) |pattern, index| {
        if (remaining_input.len < pattern.len) continue;
        if (std.mem.eql(u8, remaining_input[0..pattern.len], pattern)) return PatternMatchResult{
            .length = pattern.len,
            .index = index,
        };
    }

    return null;
}
