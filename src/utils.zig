const std = @import("std");
const line_parser = @import("lineParser.zig");

fn loadDataInto(in_stream: anytype, first_list: *std.ArrayList(u64), second_list: *std.ArrayList(u64)) !void {
    var line_buf: [16]u8 = undefined;

    while (true) {
        var maybe_line = try in_stream.readUntilDelimiterOrEof(line_buf[0..], '\n');
        if (maybe_line) |*line| {
            const number_tuple = try line_parser.parseLine(line);

            try first_list.append(number_tuple[0]);
            try second_list.append(number_tuple[1]);
        } else {
            break;
        }
    }
}

pub fn readFileInto(file_name: []const u8, first_list: *std.ArrayList(u64), second_list: *std.ArrayList(u64)) !void {
    var input_file = try std.fs.cwd().openFile(file_name, .{ .mode = std.fs.File.OpenMode.read_only });
    defer input_file.close();

    var buf_reader = std.io.bufferedReader(input_file.reader());
    const in_stream = buf_reader.reader();

    try loadDataInto(in_stream, first_list, second_list);
}
