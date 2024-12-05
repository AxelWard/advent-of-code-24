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
    var reordered_total: usize = 0;

    var rules = std.StringHashMap([][]const u8).init(allocator);

    while (lines.next()) |line| {
        if (line.len != 0) {
            var line_chunks = std.mem.splitSequence(u8, line, "|");
            const first_chunk = line_chunks.first();
            const second_chunk = line_chunks.next();

            if (second_chunk) |second_page| {
                try add_rule(first_chunk, second_page, &rules, allocator);
            } else {
                if (try check_print_valid(first_chunk, &rules, allocator)) {
                    valid_total += try get_middle_page(first_chunk, allocator);
                } else {
                    const new_pages = try get_reordered_pages(first_chunk, &rules, allocator);
                    defer allocator.free(new_pages);
                    reordered_total += try get_middle_page(new_pages, allocator);
                }
            }
        }
    }

    std.debug.print("Total of valid middle pages (part 1): {}\n", .{valid_total});
    std.debug.print("Total of reordered middle pages (part 2): {}\n", .{reordered_total});
}

fn add_rule(
    first_page: []const u8,
    second_page: []const u8,
    rules: *std.StringHashMap([][]const u8),
    allocator: std.mem.Allocator,
) !void {
    var new_rules = std.ArrayList([]const u8).init(allocator);

    if (rules.fetchRemove(second_page)) |old_rules| {
        try new_rules.appendSlice(old_rules.value);
    }

    try new_rules.append(first_page);

    try rules.put(second_page, try new_rules.toOwnedSlice());
}

fn check_print_valid(
    print: []const u8,
    rules: *std.StringHashMap([][]const u8),
    allocator: std.mem.Allocator,
) !bool {
    if (print.len == 0 or rules.count() == 0) return false;

    var pages = std.mem.splitSequence(u8, print, ",");

    var pages_not_allowed = std.ArrayList([]const u8).init(allocator);
    defer pages_not_allowed.deinit();

    while (pages.next()) |page| {
        if (array_list_contains_value(&pages_not_allowed, page)) {
            return false;
        }

        if (rules.get(page)) |page_rules| {
            for (page_rules) |rule| {
                if (!array_list_contains_value(&pages_not_allowed, rule)) {
                    try pages_not_allowed.append(rule);
                }
            }
        }
    }

    return true;
}

fn get_reordered_pages(print: []const u8, rules: *std.StringHashMap([][]const u8), allocator: std.mem.Allocator) ![]const u8 {
    var pages = std.mem.splitSequence(u8, print, ",");
    var page_list = std.ArrayList([]const u8).init(allocator);

    var relevant_rules = std.StringHashMap([][]const u8).init(allocator);

    while (pages.next()) |page| {
        var rules_iterator = relevant_rules.iterator();
        var earlier_pages = std.ArrayList([]const u8).init(allocator);

        while (rules_iterator.next()) |rules_to_check| {
            if (array_contains_value(rules_to_check.value_ptr, page)) {
                try earlier_pages.append(rules_to_check.key_ptr.*);
            }
        }

        var insert_index = page_list.items.len;
        for (page_list.items, 0..) |item, index| {
            if (array_list_contains_value(&earlier_pages, item)) {
                insert_index = index;
                break;
            }
        }

        if (insert_index == page_list.items.len) {
            try page_list.append(page);
        } else {
            const old_pages = try page_list.toOwnedSlice();
            try page_list.appendSlice(old_pages[0..insert_index]);
            try page_list.append(page);
            try page_list.appendSlice(old_pages[insert_index..]);
            allocator.free(old_pages);
        }

        if (rules.get(page)) |page_rules| {
            try relevant_rules.put(page, page_rules);
        }
    }

    const final_pages = try page_list.toOwnedSlice();
    defer allocator.free(final_pages);

    var page_string = std.ArrayList(u8).init(allocator);
    for (final_pages, 1..) |page_value, index| {
        try page_string.appendSlice(page_value);
        if (index != final_pages.len) try page_string.append(',');
    }

    const final_str = try page_string.toOwnedSlice();

    return final_str;
}

fn get_middle_page(print: []const u8, allocator: std.mem.Allocator) !usize {
    var pages = std.mem.splitSequence(u8, print, ",");

    var page_list = std.ArrayList([]const u8).init(allocator);
    defer page_list.deinit();

    while (pages.next()) |page| try page_list.append(page);

    if (page_list.items.len != 0) {
        const middle = (page_list.items.len - 1) / 2;
        return try std.fmt.parseUnsigned(usize, page_list.items[middle], 10);
    }

    return 0;
}

fn array_contains_value(array: *[][]const u8, value: []const u8) bool {
    for (array.*) |item| {
        if (std.mem.eql(u8, item, value)) return true;
    }

    return false;
}

fn array_list_contains_value(list: *std.ArrayList([]const u8), value: []const u8) bool {
    for (0..list.items.len) |index| {
        if (std.mem.eql(u8, list.items[index], value)) return true;
    }

    return false;
}
