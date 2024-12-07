const std = @import("std");
const matrix = @import("matrix.zig");

pub const ParseError = error{
    BadFormat,
};

fn loadDataInto(in_stream: anytype, list: *std.ArrayList(u8)) ![2]usize {
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

    return .{ num_rows, num_cols };
}

pub fn readFileInto(file_name: []const u8, list: *std.ArrayList(u8)) ![2]usize {
    var input_file = try std.fs.cwd().openFile(file_name, .{ .mode = std.fs.File.OpenMode.read_only });
    defer input_file.close();

    var buf_reader = std.io.bufferedReader(input_file.reader());
    const in_stream = buf_reader.reader();

    return try loadDataInto(in_stream, list);
}

pub fn getResultDay04_1() !u64 {
    var count: u64 = 0;
    var list = std.ArrayList(u8).init(std.heap.page_allocator);
    const matrix_size = try readFileInto("src/day04/input_day_04.txt", &list);
    const data = list.items;
    const mat: matrix.Matrix(u8) = try matrix.Matrix(u8).init(std.heap.page_allocator, matrix_size[0], matrix_size[1], data);
    defer mat.deinit();

    const WORD = "XMAS";
    var buffer = [_]u8{undefined} ** WORD.len;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    var ring_buffer = try std.RingBuffer.init(fba.allocator(), WORD.len);

    var iterators = [_]matrix.MatrixIterator(u8){
        matrix.MatrixIterator(u8).init(&mat, matrix.Direction.N),
        matrix.MatrixIterator(u8).init(&mat, matrix.Direction.S),
        matrix.MatrixIterator(u8).init(&mat, matrix.Direction.E),
        matrix.MatrixIterator(u8).init(&mat, matrix.Direction.W),
        matrix.MatrixIterator(u8).init(&mat, matrix.Direction.NE),
        matrix.MatrixIterator(u8).init(&mat, matrix.Direction.SE),
        matrix.MatrixIterator(u8).init(&mat, matrix.Direction.SW),
        matrix.MatrixIterator(u8).init(&mat, matrix.Direction.NW),
    };

    for (&iterators) |*iter| {
        while (!ring_buffer.isEmpty()) {
            _ = ring_buffer.read();
        }
        while (iter.next()) |ir| {
            ring_buffer.writeAssumeCapacity(ir.value);

            if (ring_buffer.isFull()) {
                const slice = ring_buffer.sliceAt(0, buffer.len);
                const match = std.mem.eql(u8, WORD[0..slice.first.len], slice.first[0..]) and std.mem.eql(u8, WORD[slice.first.len..], slice.second[0..]);
                if (match) {
                    count += 1;
                }
            }

            if (ir.is_at_matrix_edge) {
                while (!ring_buffer.isEmpty()) {
                    _ = ring_buffer.read();
                }
            }
        }
    }

    return count;
}
