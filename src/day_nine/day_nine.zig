const std = @import("std");
const file = @import("../file-helpers.zig");

pub fn run(allocator: std.mem.Allocator) !void {
    const buffer = try allocator.alloc(u8, 20000);
    defer allocator.free(buffer);
    const input_length = try file.readFileToBuffer("input/day9.txt", buffer);

    std.debug.print("Total file checksum (part 1): {}\n", .{
        try calculateChecksumFragmented(buffer[0 .. input_length - 1]),
    });
    
    std.debug.print("Total file checksum (part 2): {}\n", .{
        try calculateChecksumContiguous(buffer[0 .. input_length - 1]),
    });
}

fn calculateChecksumFragmented(input: []const u8) !usize {
    var left_index: usize = 0;
    var left_file_id: usize = 0;
    var right_index = input.len - 1;
    var right_file_id = right_index / 2;
    var number_to_take = try std.fmt.parseInt(usize, input[right_index .. right_index + 1], 10);

    var block_index: usize = 0;
    var checksum: usize = 0;
    while (left_file_id < right_file_id) {
        const block_length = try std.fmt.parseInt(usize, input[left_index .. left_index + 1], 10);

        for (block_index..(block_index + block_length)) |mult_index| {
            checksum += left_file_id * mult_index;
        }
        block_index += block_length;

        left_index += 1;

        var take = try std.fmt.parseInt(usize, input[left_index .. left_index + 1], 10);
        while (take > 0) {
            if (number_to_take == 0) {
                right_file_id -= 1;

                if (right_file_id != left_file_id) {
                    right_index -= 2;
                    number_to_take = try std.fmt.parseInt(usize, input[right_index .. right_index + 1], 10);
                } else {
                    break;
                }
            }

            checksum += block_index * right_file_id;
            number_to_take -= 1;
            block_index += 1;
            take -= 1;
        }

        left_index += 1;
        left_file_id += 1;
    }

    for (block_index..(block_index + number_to_take)) |mult_index| {
        checksum += right_file_id * mult_index;
    }

    return checksum;
}

fn calculateChecksumContiguous(input: []const u8) !usize {
    if (input.len == 0) return 0;
    return 0;
}
