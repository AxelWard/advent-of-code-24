// Create a hash map of the rules
// As you're checking prints add the new pages that are not allowed based on the current page
// Check the next page to make sure its not in the list of pages that are not allowed
const std = @import("std");
const file = @import("../file-helpers.zig");

pub fn run(allocator: std.mem.Allocator) !void {
    std.debug.print("\n\nRunning AoC Day 5...\n\n", .{});

    const buffer = try allocator.alloc(u8, 20000);
    defer allocator.free(buffer);
    const input_length = try file.readFileToBuffer("input/day5.txt", buffer);

    var lines = std.mem.splitSequence(u8, buffer[0..input_length], "\n");

    var valid_total: usize = 0;
    var rules = std.StringHashMap([][]const u8).init(allocator);

    var current_rule: ?[]const u8 = null;
    var current_rules = std.ArrayList([]const u8).init(allocator);

    while (lines.next()) |line| {
        if (line.len != 0) {
            var line_chunks = std.mem.splitSequence(u8, line, "|");
            const before = line_chunks.first();
            const second_chunk = line_chunks.next();

            if (second_chunk) |after| {
                if (current_rule) |current| {
                    if (!std.mem.eql(u8, current, after)) {
                        if (rules.fetchRemove(current)) |old_rules| {
                            try current_rules.appendSlice(old_rules.value);
                        }

                        if (current_rules.items.len != 0) {
                            try rules.put(current, try current_rules.toOwnedSlice());
                        }

                        current_rule = after;
                    }
                } else {
                    current_rule = after;
                }

                try current_rules.append(before);
            } else {
                if (current_rule) |current| {
                    if (current_rules.items.len != 0) {
                        try rules.put(current, try current_rules.toOwnedSlice());
                        current_rule = null;
                    }
                }

                valid_total += try check_print_valid(before, &rules, allocator);
            }
        }
    }

    std.debug.print("Total of valid middle pages (part 1): {}\n", .{valid_total});
}

fn check_print_valid(print: []const u8, rules: *std.StringHashMap([][]const u8), allocator: std.mem.Allocator) !usize {
    if (print.len == 0 or rules.count() == 0) return 0;

    var pages = std.mem.splitSequence(u8, print, ",");

    var pages_not_allowed = std.ArrayList([]const u8).init(allocator);
    defer pages_not_allowed.deinit();

    var page_list = std.ArrayList([]const u8).init(allocator);
    defer page_list.deinit();

    while (pages.next()) |page| {
        if (array_list_contains_value(&pages_not_allowed, page)) {
            return 0;
        }

        try page_list.append(page);

        if (rules.get(page)) |page_rules| {
            for (page_rules) |rule| {
                if (!array_list_contains_value(&pages_not_allowed, rule)) {
                    try pages_not_allowed.append(rule);
                }
            }
        }
    }

    if (page_list.items.len != 0) {
        const middle = (page_list.items.len - 1) / 2;
        return try std.fmt.parseUnsigned(usize, page_list.items[middle], 10);
    }

    return 0;
}

fn array_list_contains_value(list: *std.ArrayList([]const u8), value: []const u8) bool {
    for (0..list.items.len) |index| {
        if (std.mem.eql(u8, list.items[index], value)) return true;
    }

    return false;
}
