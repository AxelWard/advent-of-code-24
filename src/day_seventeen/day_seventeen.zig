const std = @import("std");
const file = @import("../file-helpers.zig");

const ComputerState = struct {
    register_a: usize,
    register_b: usize,
    register_c: usize,
    current_instruction: usize,

    fn getComboOperand(self: *const ComputerState, opcode: u3) usize {
        switch (opcode) {
            4 => return self.register_a,
            5 => return self.register_b,
            6 => return self.register_c,
            7 => unreachable,
            else => return @as(usize, @intCast(opcode)),
        }
    }
};

pub fn run(allocator: std.mem.Allocator) !void {
    const buffer = try allocator.alloc(u8, 1000);
    defer allocator.free(buffer);
    const input_length = try file.readFileToBuffer("input/day17.txt", buffer);

    var lines = std.mem.splitSequence(u8, buffer[0 .. input_length - 1], "\n");

    const register_a = try std.fmt.parseInt(usize, lines.first()[12..], 10);
    _ = lines.next();
    _ = lines.next();
    _ = lines.next();
    const program = lines.next().?[9..];
    var instruction_strings = std.mem.splitSequence(u8, program, ",");
    var instruction_list = std.ArrayList(u3).init(allocator);
    while (instruction_strings.next()) |instruction| {
        try instruction_list.append(try std.fmt.parseUnsigned(u3, instruction, 10));
    }
    const instructions = try instruction_list.toOwnedSlice();
    defer allocator.free(instructions);

    var program_output = try getProgramOutput(register_a, instructions, allocator);
    var output_str = std.ArrayList(u8).init(allocator);
    for (program_output[0 .. program_output.len - 1]) |out_val| {
        try output_str.appendSlice(try std.fmt.allocPrint(allocator, "{},", .{out_val}));
    }
    try output_str.appendSlice(try std.fmt.allocPrint(allocator, "{}", .{program_output[program_output.len - 1]}));
    const final_out = try output_str.toOwnedSlice();
    defer allocator.free(final_out);

    std.debug.print("Final program output (part 1): {s}\n", .{final_out});
    std.debug.print("Smallest register a to copy program (part 2): {}\n", .{try searchForSmallest(instructions, instructions, 0, allocator)});
}

const SearchError = error{ValueNotFound};

fn searchForSmallest(instructions: []const u3, remaining: []const u3, start: usize, allocator: std.mem.Allocator) !usize {
    for (start..start + 8) |check_val| {
        const output = try getProgramOutput(check_val, instructions, allocator);
        defer allocator.free(output);
        if (output[0] == remaining[remaining.len - 1]) {
            if (remaining.len == 1) return check_val;
            return searchForSmallest(instructions, remaining[0 .. remaining.len - 1], check_val * 8, allocator) catch continue;
        }
    }

    return SearchError.ValueNotFound;
}

fn getProgramOutput(initial_a: usize, instructions: []const u3, allocator: std.mem.Allocator) ![]u3 {
    var state = ComputerState{
        .register_a = initial_a,
        .register_b = 0,
        .register_c = 0,
        .current_instruction = 0,
    };

    var current_output = try allocator.alloc(u3, 0);

    while (state.current_instruction < instructions.len - 1) {
        const operand = instructions[state.current_instruction + 1];
        switch (instructions[state.current_instruction]) {
            0 => adv(&state, operand),
            1 => bxl(&state, operand),
            2 => bst(&state, operand),
            3 => if (jnz(&state, operand)) continue,
            4 => bxc(&state),
            5 => {
                const new_output = try out(&state, operand, current_output, allocator);
                allocator.free(current_output);
                current_output = new_output;
            },
            6 => bdv(&state, operand),
            7 => cdv(&state, operand),
        }

        state.current_instruction += 2;
    }

    return current_output;
}

// 0
fn adv(state: *ComputerState, combo_operand: u3) void {
    state.register_a = @divTrunc(state.register_a, std.math.pow(usize, 2, state.getComboOperand(combo_operand)));
}

// 1
fn bxl(state: *ComputerState, literal_operand: u3) void {
    state.register_b ^= @as(usize, @intCast(literal_operand));
}

// 2
fn bst(state: *ComputerState, combo_operand: u3) void {
    state.register_b = @mod(state.getComboOperand(combo_operand), 8);
}

// 3
fn jnz(state: *ComputerState, literal_operand: u3) bool {
    if (state.register_a == 0) return false;

    state.current_instruction = literal_operand;
    return true;
}

// 4
fn bxc(state: *ComputerState) void {
    state.register_b ^= state.register_c;
}

// 5
fn out(state: *ComputerState, combo_operand: u3, current_output: []const u3, allocator: std.mem.Allocator) ![]u3 {
    const next_val = @mod(state.getComboOperand(combo_operand), 8);
    if (current_output.len != 0) {
        var next_output = try allocator.alloc(u3, current_output.len + 1);
        @memcpy(next_output[0..current_output.len], current_output);
        next_output[current_output.len] = @intCast(next_val);
        return next_output;
    }

    var next_output = try allocator.alloc(u3, 1);
    next_output[0] = @intCast(next_val);
    return next_output;
}

// 6
fn bdv(state: *ComputerState, combo_operand: u3) void {
    state.register_b = @divTrunc(state.register_a, std.math.pow(usize, 2, state.getComboOperand(combo_operand)));
}

// 7
fn cdv(state: *ComputerState, combo_operand: u3) void {
    state.register_c = @divTrunc(state.register_a, std.math.pow(usize, 2, state.getComboOperand(combo_operand)));
}
