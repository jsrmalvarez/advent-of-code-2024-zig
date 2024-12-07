const std = @import("std");

const IncompleteEquation = struct {
    result: u64,
    operands: std.ArrayList(u64) = undefined,
    //operands_buffer: [128]u8 = [_]u8{undefined} ** 128,

    pub fn init(allocator: std.mem.Allocator, result: u64) IncompleteEquation {
        var ie = IncompleteEquation{
            .result = result,
        };

        //var fba = std.heap.FixedBufferAllocator.init(&ie.operands_buffer);
        ie.operands = std.ArrayList(u64).init(allocator);

        return ie;
    }

    pub fn deinit(self: *IncompleteEquation) void {
        self.operands.deinit();
    }

    pub fn addOperand(self: *IncompleteEquation, operand: u64) !void {
        try self.operands.append(operand);
    }

    const OperationSumProd = enum { sum, product };

    pub fn checkPossibleSolutionSumProd(self: IncompleteEquation) bool {
        const first = self.operands.items[0];
        const second = self.operands.items[1];
        const tail = self.operands.items[2..];
        const sum_check = checkPossibleSolutionSumProdRec(self.result, first, second, OperationSumProd.sum, tail);
        const prod_check = checkPossibleSolutionSumProdRec(self.result, first, second, OperationSumProd.product, tail);
        return sum_check or prod_check;
    }

    fn checkPossibleSolutionSumProdRec(equationResult: u64, first: u64, second: u64, operation: OperationSumProd, tail: []u64) bool {
        const result = switch (operation) {
            OperationSumProd.sum => first + second,
            OperationSumProd.product => first * second,
        };

        if (tail.len == 0) {
            return equationResult == result;
        } else {
            const sum_check = checkPossibleSolutionSumProdRec(equationResult, result, tail[0], OperationSumProd.sum, tail[1..]);
            const prod_check = checkPossibleSolutionSumProdRec(equationResult, result, tail[0], OperationSumProd.product, tail[1..]);
            return sum_check or prod_check;
        }
    }
};

test "Test 1" {
    var ie = IncompleteEquation.init(std.testing.allocator, 190);
    defer ie.deinit();

    try ie.addOperand(10);
    try ie.addOperand(19);
    try std.testing.expect(ie.checkPossibleSolutionSumProd() == true);
}

test "Test 2" {
    var ie = IncompleteEquation.init(std.testing.allocator, 3267);
    defer ie.deinit();

    try ie.addOperand(81);
    try ie.addOperand(40);
    try ie.addOperand(27);
    try std.testing.expect(ie.checkPossibleSolutionSumProd() == true);
}

test "Test 3" {
    var ie = IncompleteEquation.init(std.testing.allocator, 292);
    defer ie.deinit();

    try ie.addOperand(11);
    try ie.addOperand(6);
    try ie.addOperand(16);
    try ie.addOperand(20);
    try std.testing.expect(ie.checkPossibleSolutionSumProd() == true);
}

test "Test 4" {
    var ie = IncompleteEquation.init(std.testing.allocator, 83);
    defer ie.deinit();

    try ie.addOperand(17);
    try ie.addOperand(5);
    try std.testing.expect(ie.checkPossibleSolutionSumProd() == false);
}

test "Test 5" {
    var ie = IncompleteEquation.init(std.testing.allocator, 156);
    defer ie.deinit();

    try ie.addOperand(15);
    try ie.addOperand(6);
    try std.testing.expect(ie.checkPossibleSolutionSumProd() == false);
}

test "Test 6" {
    var ie = IncompleteEquation.init(std.testing.allocator, 7290);
    defer ie.deinit();

    try ie.addOperand(6);
    try ie.addOperand(8);
    try ie.addOperand(6);
    try ie.addOperand(15);

    try std.testing.expect(ie.checkPossibleSolutionSumProd() == false);
}

test "Test 7" {
    var ie = IncompleteEquation.init(std.testing.allocator, 192);
    defer ie.deinit();

    try ie.addOperand(17);
    try ie.addOperand(8);
    try ie.addOperand(14);

    try std.testing.expect(ie.checkPossibleSolutionSumProd() == false);
}

test "Test 8" {
    var ie = IncompleteEquation.init(std.testing.allocator, 21037);
    defer ie.deinit();

    try ie.addOperand(9);
    try ie.addOperand(7);
    try ie.addOperand(18);
    try ie.addOperand(13);
    try std.testing.expect(ie.checkPossibleSolutionSumProd() == false);
}

pub fn parseLine(allocator: std.mem.Allocator, line: *[]u8) !IncompleteEquation {
    var line_reader = std.io.fixedBufferStream(line.*);
    var line_stream = line_reader.reader();

    var buffer: [24]u8 = undefined;
    const result_str = try line_stream.readUntilDelimiter(&buffer, ':');
    const result: u64 = try std.fmt.parseInt(u64, result_str, 10);

    var incomplete_equation = IncompleteEquation.init(allocator, result);

    try line_stream.skipBytes(1, .{}); // skip space

    while (true) {
        const next_token_str = try line_stream.readUntilDelimiterOrEof(&buffer, ' ');
        if (next_token_str) |token| {
            const operand = try std.fmt.parseInt(u64, token, 10);
            try incomplete_equation.addOperand(operand);
        } else {
            break;
        }
    }

    return incomplete_equation;
}

pub fn getResultDay07_1(allocator: std.mem.Allocator) !usize {
    var input_file = try std.fs.cwd().openFile("src/day07/input_day_07.txt", .{ .mode = std.fs.File.OpenMode.read_only });
    defer input_file.close();

    var buf_reader = std.io.bufferedReader(input_file.reader());
    const in_stream = buf_reader.reader();

    var line_buf: [80]u8 = undefined;

    var total_calibration_result: usize = 0;
    while (true) {
        var maybe_line = try in_stream.readUntilDelimiterOrEof(line_buf[0..], '\n');
        if (maybe_line) |*line| {
            var incomplete_equation = try parseLine(allocator, line);
            defer incomplete_equation.deinit();
            if (incomplete_equation.checkPossibleSolutionSumProd()) {
                total_calibration_result += incomplete_equation.result;
            }
        } else {
            break;
        }
    }

    return total_calibration_result;
}

pub fn getResultDay07_2(allocator: std.mem.Allocator) !usize {
    var input_file = try std.fs.cwd().openFile("src/day07/input_day_07.txt", .{ .mode = std.fs.File.OpenMode.read_only });
    defer input_file.close();

    var buf_reader = std.io.bufferedReader(input_file.reader());
    const in_stream = buf_reader.reader();

    var line_buf: [80]u8 = undefined;

    var total_calibration_result: usize = 0;
    while (true) {
        var maybe_line = try in_stream.readUntilDelimiterOrEof(line_buf[0..], '\n');
        if (maybe_line) |*line| {
            var incomplete_equation = try parseLine(allocator, line);
            defer incomplete_equation.deinit();
            if (incomplete_equation.checkPossibleSolutionSumProdConcat()) {
                total_calibration_result += incomplete_equation.result;
            }
        } else {
            break;
        }
    }

    return total_calibration_result;
}
