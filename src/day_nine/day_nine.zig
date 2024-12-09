const std = @import("std");
const readFileToBuffer = @import("../file-helpers.zig").readFileToBuffer;

const File = struct {
    id: ?usize,
    length: usize,
};

pub fn run(allocator: std.mem.Allocator) !void {
    const buffer = try allocator.alloc(u8, 20000);
    defer allocator.free(buffer);
    const input_length = try readFileToBuffer("input/day9.txt", buffer);

    var files = std.ArrayList(File).init(allocator);
    var current_index: usize = 0;
    while (current_index * 2 < input_length - 1) : (current_index += 1) {
        try files.append(File{
            .id = current_index,
            .length = try std.fmt.parseInt(
                usize,
                buffer[current_index * 2 .. current_index * 2 + 1],
                10,
            ),
        });

        if (current_index * 2 + 1 < input_length - 1) try files.append(File{
            .id = null,
            .length = try std.fmt.parseInt(
                usize,
                buffer[current_index * 2 + 1 .. current_index * 2 + 2],
                10,
            ),
        });
    }

    const input_files = try files.toOwnedSlice();
    defer allocator.free(input_files);

    std.debug.print("Total file checksum (part 1): {}\n", .{
        try calculateChecksumFragmented(input_files),
    });

    std.debug.print("Total file checksum (part 2): {}\n", .{
        try calculateChecksumContiguous(input_files, allocator),
    });
}

fn calculateChecksumFragmented(input: []const File) !usize {
    var left_index: usize = 0;
    while (input[left_index].id == null) {
        left_index += 1;
    }
    var left_file_id: usize = input[left_index].id.?;

    var right_index = input.len - 1;
    while (input[right_index].id == null) {
        right_index -= 1;
    }
    var right_file_id = input[right_index].id.?;
    var number_to_take = input[right_index].length;

    var block_index: usize = 0;
    var checksum: usize = 0;
    while (left_file_id < right_file_id) {
        const block_length = input[left_index].length;
        for (block_index..(block_index + block_length)) |mult_index| {
            checksum += left_file_id * mult_index;
        }
        block_index += block_length;

        left_index += 1;

        var take = input[left_index].length;
        while (take > 0) {
            if (number_to_take == 0) {
                right_index -= 2;
                right_file_id = input[right_index].id.?;

                if (right_file_id != left_file_id) {
                    number_to_take = input[right_index].length;
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

fn calculateChecksumContiguous(input: []const File, allocator: std.mem.Allocator) !usize {
    var contiguous_files = std.ArrayList(File).init(allocator);
    for (input) |file| {
        try contiguous_files.append(file);
    }

    var index = contiguous_files.items.len - 1;
    while (index > 0) {
        const file = contiguous_files.items[index];

        if (file.id) |id| {
            for (contiguous_files.items[0..index], 0..) |check_file, check_index| {
                if (check_file.id == null and check_file.length >= file.length) {
                    _ = contiguous_files.orderedRemove(index);

                    try contiguous_files.insert(index, File{
                        .id = null,
                        .length = file.length,
                    });

                    _ = contiguous_files.orderedRemove(check_index);

                    try contiguous_files.insert(check_index, File{
                        .id = id,
                        .length = file.length,
                    });
                    

                    if (check_file.length > file.length) {
                        try contiguous_files.insert(check_index + 1, File{
                            .id = null,
                            .length = check_file.length - file.length,
                        });
                    }


                    break;
                }
            }
        }

        index -= 1;
    }

    var block_index: usize = 0;
    var checksum: usize = 0;
    for (contiguous_files.items) |file| {
        if (file.id) |id| {
            for (0..file.length) |_| {
                checksum += id * block_index;
                block_index += 1;
            }
        } else {
            block_index += file.length;
        }
    }

    return checksum;
}
