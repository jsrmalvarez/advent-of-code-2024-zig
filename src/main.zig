const std = @import("std");
const utils = @import("utils.zig");

pub fn main() !void {}

test "Day 1 - 1" {
    const day01 = @import("day01/day01.zig");
    try std.testing.expectEqual(try day01.getResultDay01_1(), 1110981);
}

test "Day 1 - 2" {
    const day01 = @import("day01/day01.zig");
    try std.testing.expectEqual(try day01.getResultDay01_2(), 24869388);
}

test "Day 3 - 1" {
    const day03 = @import("day03/day03.zig");
    try std.testing.expectEqual(try day03.getResultDay03_1(), 170394629);
}