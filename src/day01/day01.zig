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

fn loadDataInto(in_stream: anytype, first_list: *std.ArrayList(u64), second_list: *std.ArrayList(u64)) !void {
    var line_buf: [16]u8 = undefined;

    while (true) {
        var maybe_line = try in_stream.readUntilDelimiterOrEof(line_buf[0..], '\n');
        if (maybe_line) |*line| {
            const number_tuple = try parseLine(line);

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

const input_file_path = "src/day01/input_day_01.txt";

pub fn getResultDay01_1() !u64 {
    var first_list = std.ArrayList(u64).init(std.heap.page_allocator);
    var second_list = std.ArrayList(u64).init(std.heap.page_allocator);

    try readFileInto(input_file_path, &first_list, &second_list);

    std.mem.sort(u64, first_list.items, {}, std.sort.asc(u64));
    std.mem.sort(u64, second_list.items, {}, std.sort.asc(u64));

    var sum: u64 = 0;
    for (first_list.items, second_list.items) |n1, n2| {
        const abs = @max(n1, n2) - @min(n1, n2);
        sum += abs;
    }

    return sum;
}

pub fn getResultDay01_2() !u64 {
    var first_list = std.ArrayList(u64).init(std.heap.page_allocator);
    var second_list = std.ArrayList(u64).init(std.heap.page_allocator);

    try readFileInto(input_file_path, &first_list, &second_list);

    const ScoreData = struct {
        id: u64,
        occurrences: u64,
        score: u64,
    };

    const ScoreList = std.MultiArrayList(ScoreData);

    var score_list = ScoreList{};
    defer score_list.deinit(std.heap.page_allocator);

    for (first_list.items) |f| {
        var data: ScoreData = .{ .id = f, .occurrences = 0, .score = 0 };
        for (second_list.items) |s| {
            if (f == s) {
                data.occurrences += 1;
            }
        }
        data.score = data.id * data.occurrences;
        try score_list.append(std.heap.page_allocator, data);
    }

    var sum_scores: u64 = 0;
    for (score_list.items(.score)) |score| {
        sum_scores += score;
    }

    return sum_scores;
}
