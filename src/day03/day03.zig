const std = @import("std");
const utils = @import("../utils.zig");

const input_file_path = "src/day03/input_day_03.txt";

fn tick(pc: u8, c: u8, sum: *u64) void {
    std.debug.print("{c} - >{c}\n", .{ pc, c });
    sum.* +%= 1;
}

pub fn getResultDay03_1() !u64 {
    var input_file = try std.fs.cwd().openFile(input_file_path, .{ .mode = std.fs.File.OpenMode.read_only });
    defer input_file.close();
    var buf_reader = std.io.bufferedReader(input_file.reader());
    const in_stream = buf_reader.reader();

    var sum: u64 = 0;

    // seek "m"
    scanner: while (true) {
        while (true) {
            const c = in_stream.readByte() catch |err| {
                if (err == error.EndOfStream) {
                    break :scanner;
                } else {
                    return err;
                }
            };

            if (c == 'm') {
                break;
            }
        }

        // m found
        // check for "ul"
        const maybe_ul: [2]u8 = in_stream.readBytesNoEof(2) catch |err| {
            if (err == error.EndOfStream) {
                break :scanner;
            } else {
                return err;
            }
        };

        if (std.mem.eql(u8, "ul", &maybe_ul)) {
            // ul found
            // test for "("
            const c = in_stream.readByte() catch |err| {
                if (err == error.EndOfStream) {
                    break :scanner;
                } else {
                    return err;
                }
            };

            if (c == '(') {
                var num1_buff: [8]u8 = undefined;
                var num1_fbs = std.io.fixedBufferStream(&num1_buff);

                while (true) {
                    const d = in_stream.readByte() catch |err| {
                        if (err == error.EndOfStream) {
                            break;
                        } else {
                            return err;
                        }
                    };

                    if (std.ascii.isDigit(d)) {
                        try num1_fbs.writer().writeByte(d);
                    } else if (d == ',') { // "," found

                        const num_1: u64 = try std.fmt.parseInt(u64, num1_buff[0..num1_fbs.pos], 10);

                        var num2_buff: [8]u8 = undefined;
                        var num2_fbs = std.io.fixedBufferStream(&num2_buff);

                        while (true) {
                            const d2 = in_stream.readByte() catch |err| {
                                if (err == error.EndOfStream) {
                                    break;
                                } else {
                                    return err;
                                }
                            };

                            if (std.ascii.isDigit(d2)) {
                                try num2_fbs.writer().writeByte(d2);
                            } else if (d2 == ')') { // ")" found
                                const num_2: u64 = try std.fmt.parseInt(u64, num2_buff[0..num2_fbs.pos], 10);
                                sum += num_1 * num_2;
                            } else {
                                break;
                            }
                        }
                    } else {
                        break;
                    }
                }
            }
        }
    }

    return sum;
}
