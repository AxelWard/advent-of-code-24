const std = @import("std");
const readFileToBuffer = @import("../file-helpers.zig").readFileToBuffer;
pub const Point = struct {
    x: f128,
    y: f128,
};

const MachineConfig = struct {
    button_a: Point,
    button_b: Point,
    prize: Point,
};

pub fn run(allocator: std.mem.Allocator) !void {
    const buffer = try allocator.alloc(u8, 30000);
    defer allocator.free(buffer);
    const input_length = try readFileToBuffer("input/day13.txt", buffer);

    var lines = std.mem.splitSequence(u8, buffer[0 .. input_length - 1], "\n");

    var configs = std.ArrayList(MachineConfig).init(allocator);
    defer configs.deinit();

    var total_tokens: usize = 0;
    var total_expanded: usize = 0;

    while (try parseMachineConfig(&lines)) |config| {
        total_tokens += getMachineTokens(config);
        total_expanded += getMachineTokens(MachineConfig{
            .button_a = config.button_a,
            .button_b = config.button_b,
            .prize = Point{
                .x = config.prize.x + 10000000000000,
                .y = config.prize.y + 10000000000000,
            },
        });
    }

    std.debug.print("Total tokens used (part 1): {}\n", .{total_tokens});
    std.debug.print("Total tokens used in big machines (part 2): {}\n", .{total_expanded});
}

fn parseMachineConfig(lines: *std.mem.SplitIterator(u8, std.mem.DelimiterType.sequence)) !?MachineConfig {
    var config = MachineConfig{
        .button_a = Point{ .x = 0, .y = 0 },
        .button_b = Point{ .x = 0, .y = 0 },
        .prize = Point{ .x = 0, .y = 0 },
    };

    if (lines.next()) |first_line| {
        config.button_a = try parseLinePoint(first_line);
    } else return null;

    if (lines.next()) |second_line| {
        config.button_b = try parseLinePoint(second_line);
    } else return null;

    if (lines.next()) |third_line| {
        config.prize = try parseLinePoint(third_line);
    } else return null;

    _ = lines.next();

    return config;
}

fn parseLinePoint(line: []const u8) !Point {
    var x_start: usize = 0;
    var x_end: usize = 0;
    var y_start: usize = 0;

    for (line, 0..) |character, index| {
        if (character == '+' or character == '=') {
            x_start = index + 1;
        }
        if (character == ',') {
            x_end = index;
            break;
        }
    }

    for (line[x_end..], x_end..) |character, index| {
        if (character == '+' or character == '=') {
            y_start = index + 1;
            break;
        }
    }

    return Point{
        .x = @floatFromInt(try std.fmt.parseUnsigned(usize, line[x_start..x_end], 10)),
        .y = @floatFromInt(try std.fmt.parseUnsigned(usize, line[y_start..], 10)),
    };
}

fn getMachineTokens(config: MachineConfig) usize {

    // This math is courtesy of some fun whiteboard algebra. See whiteboard_math.png for more info
    const button_b_presses: f128 = ((config.button_a.y * config.prize.x) - (config.button_a.x * config.prize.y)) / ((config.button_a.y * config.button_b.x) - (config.button_a.x * config.button_b.y));
    const button_a_presses: f128 = (config.prize.x - (config.button_b.x * button_b_presses)) / config.button_a.x;

    if (button_a_presses != @round(button_a_presses)) return 0;
    if (button_b_presses != @round(button_b_presses)) return 0;

    const token_total = (3 * button_a_presses) + button_b_presses;
    return @as(usize, @intFromFloat(token_total));
}
