const std = @import("std");
const matrix = @import("matrix.zig");

pub const ParseError = error{
    BadFormat,
};

fn loadDataInto(in_stream: anytype, list: *std.ArrayList(u8)) !void {
    var line_buf: [256]u8 = undefined;
    var num_rows: usize = 0;
    var num_cols: usize = 0;

    while (true) {
        const maybe_line = try in_stream.readUntilDelimiterOrEof(line_buf[0..], '\n');
        if (maybe_line) |line| {
            num_rows += 1;
            var this_line_cols: usize = 0;
            for (line) |c| {
                try list.append(c);
                this_line_cols += 1;
            }

            if (num_cols == 0) {
                num_cols = this_line_cols;
            } else {
                if (this_line_cols != num_cols) {
                    return ParseError.BadFormat;
                }
            }
        } else {
            break;
        }
    }
}

pub fn readFileInto(file_name: []const u8, list: *std.ArrayList(u8)) !void {
    var input_file = try std.fs.cwd().openFile(file_name, .{ .mode = std.fs.File.OpenMode.read_only });
    defer input_file.close();

    var buf_reader = std.io.bufferedReader(input_file.reader());
    const in_stream = buf_reader.reader();

    try loadDataInto(in_stream, list);
}

pub fn getResultDay04_1() !u64 {
    var list = std.ArrayList(u8).init(std.heap.page_allocator);
    try readFileInto("src/day04/input_day_04.txt", &list);
    const data = list.items;
    const a: matrix.Matrix(u8) = try matrix.Matrix(u8).init(std.heap.page_allocator, 4, 3, data);

    var iter = matrix.MatrixIterator(u8, matrix.Direction.SW).init(&a);
    _ = iter.next();
    return 42;
}
