const std = @import("std");
const utils = @import("utils.zig");

pub fn main() !void {}

test "Day 1 - 1" {
    var first_list = std.ArrayList(u64).init(std.heap.page_allocator);
    var second_list = std.ArrayList(u64).init(std.heap.page_allocator);

    try utils.readFileInto("input_day1.txt", &first_list, &second_list);

    std.mem.sort(u64, first_list.items, {}, std.sort.asc(u64));
    std.mem.sort(u64, second_list.items, {}, std.sort.asc(u64));

    var sum: u64 = 0;
    for (first_list.items, second_list.items) |n1, n2| {
        const abs = @max(n1, n2) - @min(n1, n2);
        sum += abs;
    }

    try std.testing.expectEqual(sum, 1110981);
}

test "Day 1 - 2" {
    var first_list = std.ArrayList(u64).init(std.heap.page_allocator);
    var second_list = std.ArrayList(u64).init(std.heap.page_allocator);

    try utils.readFileInto("input_day1.txt", &first_list, &second_list);

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

    try std.testing.expectEqual(sum_scores, 24869388);
}
