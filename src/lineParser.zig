const std = @import("std");

pub fn parseLine(line: *[]u8) ![2]u64 {
    var line_reader = std.io.fixedBufferStream(line.*);
    var line_stream = line_reader.reader();
    var num1_buf: [6]u8 = undefined;
    const number1_str = try line_stream.readUntilDelimiter(num1_buf[0..], ' ');
    try line_stream.skipBytes(2, .{});
    var num2_buf: [6]u8 = undefined;
    const num_bytes = try line_stream.readAll(num2_buf[0..]);
    const number2_str = num2_buf[0..num_bytes];

    const num1: u64 = try std.fmt.parseInt(u64, number1_str, 10);
    const num2: u64 = try std.fmt.parseInt(u64, number2_str, 10);

    return .{ num1, num2 };
}
