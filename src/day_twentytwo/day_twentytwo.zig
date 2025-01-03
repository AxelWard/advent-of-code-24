const std = @import("std");
const file = @import("../file-helpers.zig");

pub fn run(allocator: std.mem.Allocator) !void {
    const buffer = try allocator.alloc(u8, 20000);
    defer allocator.free(buffer);
    const input_length = try file.readFileToBuffer("input/day22.txt", buffer);

    var lines = std.mem.splitSequence(u8, buffer[0..input_length], "\n");

    var secret_total: usize = 0;
    var banana_totals = try allocator.alloc(usize, 19 * 19 * 19 * 19);
    for (0..banana_totals.len) |index| {
        banana_totals[index] = 0;
    }

    while (lines.next()) |line| {
        if (line.len == 0) continue;
        var secret = try std.fmt.parseInt(usize, line, 10);

        var banana_changes = std.ArrayList(isize).init(allocator);
        defer banana_changes.deinit();

        var monkey_bananas = try allocator.alloc(?usize, 19 * 19 * 19 * 19);
        for (0..monkey_bananas.len) |index| {
            monkey_bananas[index] = null;
        }
        defer allocator.free(monkey_bananas);

        var iteration: usize = 0;
        while (iteration < 2000) : (iteration += 1) {
            const next_secret = calculateNextSecretNumber(secret);
            const diff = getSecretChange(secret, next_secret);

            try banana_changes.insert(0, diff);

            if (iteration < 3) {
                secret = next_secret;
                continue;
            }

            banana_changes.shrinkRetainingCapacity(4);
            const change_index = getChangeIndex(banana_changes.items);

            if (monkey_bananas[change_index] == null) {
                monkey_bananas[change_index] = next_secret % 10;
            }

            secret = next_secret;
        }

        for (monkey_bananas, 0..) |bananas, index| {
            if (bananas) |b| banana_totals[index] += b;
        }

        secret_total += secret;
    }

    var max_bananas: usize = 0;
    for (banana_totals) |bananas| {
        if (bananas > max_bananas) max_bananas = bananas;
    }

    std.debug.print("Total value of 2000th secret numbers (part 1): {}\n", .{secret_total});
    std.debug.print("Highest bananas possible (part 2): {}\n", .{max_bananas});
}

fn calculateNextSecretNumber(original_secret: usize) usize {
    const step_1 = prune(mix(original_secret * 64, original_secret));
    const step_2 = prune(mix(@divFloor(step_1, 32), step_1));
    return prune(mix(step_2 * 2048, step_2));
}

inline fn mix(value: usize, secret: usize) usize {
    return value ^ secret;
}

inline fn prune(secret: usize) usize {
    return secret % 16777216;
}

inline fn getSecretChange(original_secret: usize, next_secret: usize) isize {
    return @as(isize, @intCast(original_secret % 10)) - @as(isize, @intCast(next_secret % 10));
}

fn getChangeIndex(changes: []const isize) usize {
    if (changes.len != 4) unreachable;

    var total: usize = 0;
    for (0..4) |index| {
        total += @as(usize, @intCast(changes[index] + 9)) * std.math.pow(usize, 19, index);
    }

    return total;
}
