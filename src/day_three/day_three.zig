const std = @import("std");
const file = @import("../file-helpers.zig");

fn char_is_number(char: u8) bool {
    const digits = [10]u8{ '0', '1', '2', '3', '4', '5', '6', '7', '8', '9' };

    for (digits) |digit| {
        if (char == digit) return true;
    }

    return false;
}

const Instruction = enum { do, dont, mul };

const MUL_INSTRUCTION = [4]u8{ 'm', 'u', 'l', '(' };
const DO_INSTRUCTION = [4]u8{ 'd', 'o', '(', ')' };
const DONT_INSTRUCTION = [7]u8{ 'd', 'o', 'n', '\'', 't', '(', ')' };

const InstructionAndData = struct { inst_type: Instruction, data: []const u8 };
const INSTRUCTIONS = [3]InstructionAndData{
    InstructionAndData{ .inst_type = Instruction.mul, .data = &MUL_INSTRUCTION },
    InstructionAndData{ .inst_type = Instruction.do, .data = &DO_INSTRUCTION },
    InstructionAndData{ .inst_type = Instruction.dont, .data = &DONT_INSTRUCTION },
};

fn get_instruction(buffer: []const u8, buffer_length: usize, start_index: usize) ?Instruction {
    for (INSTRUCTIONS) |check| {
        if (start_index + check.data.len > buffer_length) continue;
        if (std.mem.eql(
            u8,
            buffer[start_index .. start_index + check.data.len],
            check.data,
        )) return check.inst_type;
    }

    return null;
}

pub fn run(allocator: std.mem.Allocator) !void {
    const buffer = try allocator.alloc(u8, 32768);
    defer allocator.free(buffer);
    const input_length = try file.readFileToBuffer("input/day3.txt", buffer);

    var total_one: i64 = 0;
    var total_two: i64 = 0;
    var index: usize = 0;
    var check = true;
    while (index < input_length) {
        const instruction = get_instruction(buffer, input_length, index);

        if (instruction == null) {
            index += 1;
            continue;
        } else if (instruction == Instruction.do) {
            check = true;
            index += DO_INSTRUCTION.len;
            continue;
        } else if (instruction == Instruction.dont) {
            check = false;
            index += DONT_INSTRUCTION.len;
            continue;
        }

        // Move to the start of the potential inner mult
        index += MUL_INSTRUCTION.len;

        var num_data = std.ArrayList(u8).init(allocator);
        defer num_data.deinit();

        while (char_is_number(buffer[index])) {
            try num_data.append(buffer[index]);
            index += 1;
        }

        if (num_data.items.len == 0 or buffer[index] != ',') {
            continue;
        }

        const first_num = try std.fmt.parseInt(i64, num_data.items, 10);
        num_data.clearAndFree();
        index += 1;

        while (char_is_number(buffer[index])) {
            try num_data.append(buffer[index]);
            index += 1;
        }

        if (num_data.items.len == 0 or buffer[index] != ')') {
            continue;
        }

        const second_num = try std.fmt.parseInt(i64, num_data.items, 10);
        index += 1;

        total_one += first_num * second_num;
        if (check) {
            total_two += first_num * second_num;
        }
    }

    std.debug.print("Total of valid muls (part 1): {}\n", .{total_one});
    std.debug.print("Total of valid muls (part 2): {}\n", .{total_two});
}
