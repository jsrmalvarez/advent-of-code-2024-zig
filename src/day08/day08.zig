const std = @import("std");
const matrix = @import("../utils/matrix.zig");

const Antenna = struct {
    frequency: u8,
    x: usize,
    y: usize,

    pub fn hash(self: Antenna) u64 {
        const f = @as(u64, self.frequency);
        const x = @as(u64, self.x);
        const y = @as(u64, self.y);
        const hash_calculation = ((f & 0x00000000000000FF) << 56) | ((x & 0x000000000FFFFFFF) << 28) | (y & 0x000000000FFFFFFF);
        return hash_calculation;
    }

    pub fn eql(self: Antenna, other: Antenna) bool {
        return self.hash() == other.hash();
    }
};

const AntennaPair = struct {
    first: Antenna,
    second: Antenna,

    pub fn create(first: Antenna, second: Antenna) !AntennaPair {
        if (first.eql(second)) {
            return error.SameAntenna;
        }

        if (first.frequency != second.frequency) {
            return error.UnmatchingFrequency;
        }

        return AntennaPair{ .first = first, .second = second };
    }

    pub fn hash(self: AntennaPair) u64 {
        return self.first.hash() ^ self.second.hash();
    }

    pub fn eql(self: AntennaPair, other: AntennaPair) bool {
        return self.hash() == other.hash();
    }

    pub fn getVector(self: AntennaPair) [2]isize {
        const first_x: isize = @intCast(self.first.x);
        const first_y: isize = @intCast(self.first.y);
        const second_x: isize = @intCast(self.second.x);
        const second_y: isize = @intCast(self.second.y);
        return .{ (first_x - second_x), (first_y - second_y) };
    }

    pub fn getAntinodes(self: AntennaPair) [2]?Antinode {
        const vector = self.getVector();
        const vector_x = vector[0];
        const vector_y = vector[1];

        const first_x: isize = @intCast(self.first.x);
        const first_y: isize = @intCast(self.first.y);
        const second_x: isize = @intCast(self.second.x);
        const second_y: isize = @intCast(self.second.y);

        const antinode1_x = first_x + vector_x;
        const antinode1_y = first_y + vector_y;

        const antinode2_x = second_x - vector_x;
        const antinode2_y = second_y - vector_y;

        const antinode1: ?Antinode = if (antinode1_x >= 0 and antinode1_y >= 0)
            Antinode{
                .frequency = self.first.frequency,
                .x = @intCast(antinode1_x),
                .y = @intCast(antinode1_y),
            }
        else
            null;

        const antinode2: ?Antinode = if (antinode2_x >= 0 and antinode2_y >= 0)
            Antinode{
                .frequency = self.first.frequency,
                .x = @intCast(antinode2_x),
                .y = @intCast(antinode2_y),
            }
        else
            null;

        return .{ antinode1, antinode2 };
    }
};

const AntennaPairContext = struct {
    pub fn hash(self: AntennaPairContext, pair: AntennaPair) u64 {
        _ = self;
        return pair.hash();
    }

    pub fn eql(self: AntennaPairContext, first: AntennaPair, second: AntennaPair) bool {
        _ = self;
        return first.eql(second);
    }
};

const Antinode = struct {
    frequency: u8,
    x: usize,
    y: usize,

    pub fn hash(self: Antinode) u64 {
        const f = @as(u64, self.frequency);
        const x = @as(u64, self.x);
        const y = @as(u64, self.y);
        const hash_calculation = ((f & 0x00000000000000FF) << 56) | ((x & 0x000000000FFFFFFF) << 28) | (y & 0x000000000FFFFFFF);
        return hash_calculation;
    }

    pub fn eql(self: Antinode, other: Antinode) bool {
        return self.hash() == other.hash();
    }
};

const AntinodeContext = struct {
    pub fn hash(self: AntinodeContext, location: Antinode) u64 {
        _ = self;
        return location.hash();
    }

    pub fn eql(self: AntinodeContext, first: Antinode, second: Antinode) bool {
        _ = self;
        return first.eql(second);
    }
};

test "eql and hash" {
    const a1 = Antenna{ .frequency = 'a', .x = 42, .y = 54 };
    const a2 = Antenna{ .frequency = 'a', .x = 82, .y = 41 };
    const pair_a1_a2 = try AntennaPair.create(a1, a2);
    const pair_a2_a1 = try AntennaPair.create(a2, a1);
    const context = AntennaPairContext{};

    try std.testing.expect(context.hash(pair_a1_a2) == context.hash(pair_a2_a1));

    try std.testing.expect(context.eql(pair_a1_a2, pair_a1_a2));
    try std.testing.expect(context.eql(pair_a2_a1, pair_a2_a1));
    try std.testing.expect(context.eql(pair_a1_a2, pair_a2_a1));

    var pairs = std.HashMap(AntennaPair, u0, AntennaPairContext, 1).init(std.testing.allocator);
    defer pairs.deinit();

    try pairs.put(pair_a1_a2, 0);
    try std.testing.expect(pairs.count() == 1);
    try pairs.put(pair_a1_a2, 0);
    try std.testing.expect(pairs.count() == 1);
    try pairs.put(pair_a2_a1, 0);
    try std.testing.expect(pairs.count() == 1);
}

test "pair count" {
    const a1 = Antenna{ .frequency = 'a', .x = 42, .y = 54 };
    const a2 = Antenna{ .frequency = 'a', .x = 82, .y = 41 };
    const a3 = Antenna{ .frequency = 'a', .x = 12, .y = 25 };
    const a4 = Antenna{ .frequency = 'b', .x = 12, .y = 25 }; // other frequency
    const a5 = Antenna{ .frequency = 'a', .x = 13, .y = 28 };
    const antennas = [_]Antenna{ a1, a2, a3, a4, a5 };

    var pairs = std.HashMap(AntennaPair, u0, AntennaPairContext, 1).init(std.testing.allocator);
    defer pairs.deinit();

    for (antennas) |ai| {
        for (antennas) |aj| {
            const pair: ?AntennaPair = AntennaPair.create(ai, aj) catch null;
            if (pair) |p| {
                try pairs.put(p, 0);
            }
        }
    }

    var pair_iterator = pairs.iterator();
    std.debug.print("\n", .{});
    while (pair_iterator.next()) |e| {
        const p = e.key_ptr;
        std.debug.print("hash {} | first hash {} f {} x {} y {} | second hash {} f {} x {} y {} )\n", .{ p.hash(), p.first.hash(), p.first.frequency, p.first.x, p.first.y, p.second.hash(), p.second.frequency, p.second.x, p.second.y });
    }

    try std.testing.expect(pairs.count() == 6);
}

test "get antinodes" {
    {
        const a1 = Antenna{ .frequency = 'a', .x = 42, .y = 54 };
        const a2 = Antenna{ .frequency = 'a', .x = 82, .y = 41 };
        const pair_a1_a2 = try AntennaPair.create(a1, a2);
        const nodes = pair_a1_a2.getAntinodes();
        if (nodes[0]) |antinode_1| {
            try std.testing.expect(antinode_1.eql(Antinode{ .frequency = 'a', .x = 2, .y = 67 }));
        } else {
            try std.testing.expect(false);
        }

        if (nodes[1]) |antinode_2| {
            try std.testing.expect(antinode_2.eql(Antinode{ .frequency = 'a', .x = 122, .y = 28 }));
        } else {
            try std.testing.expect(false);
        }
    }
    {
        const a1 = Antenna{ .frequency = 'a', .x = 40, .y = 54 };
        const a2 = Antenna{ .frequency = 'a', .x = 80, .y = 41 };
        const pair_a1_a2 = try AntennaPair.create(a1, a2);
        const nodes = pair_a1_a2.getAntinodes();
        if (nodes[0]) |antinode_1| {
            try std.testing.expect(antinode_1.eql(Antinode{ .frequency = 'a', .x = 0, .y = 67 }));
        } else {
            try std.testing.expect(false);
        }

        if (nodes[1]) |antinode_2| {
            try std.testing.expect(antinode_2.eql(Antinode{ .frequency = 'a', .x = 120, .y = 28 }));
        } else {
            try std.testing.expect(false);
        }
    }
    {
        const a1 = Antenna{ .frequency = 'a', .x = 39, .y = 54 };
        const a2 = Antenna{ .frequency = 'a', .x = 79, .y = 41 };
        const pair_a1_a2 = try AntennaPair.create(a1, a2);
        const nodes = pair_a1_a2.getAntinodes();
        if (nodes[0]) |_| {
            try std.testing.expect(false);
        } else {
            try std.testing.expect(true);
        }

        if (nodes[1]) |antinode_2| {
            try std.testing.expect(antinode_2.eql(Antinode{ .frequency = 'a', .x = 119, .y = 28 }));
        } else {
            try std.testing.expect(false);
        }
    }
    {
        const a1 = Antenna{ .frequency = 'a', .x = 42, .y = 26 };
        const a2 = Antenna{ .frequency = 'a', .x = 82, .y = 13 };
        const pair_a1_a2 = try AntennaPair.create(a1, a2);
        const nodes = pair_a1_a2.getAntinodes();
        if (nodes[0]) |antinode_1| {
            try std.testing.expect(antinode_1.eql(Antinode{ .frequency = 'a', .x = 2, .y = 39 }));
        } else {
            try std.testing.expect(false);
        }

        if (nodes[1]) |antinode_2| {
            try std.testing.expect(antinode_2.eql(Antinode{ .frequency = 'a', .x = 122, .y = 0 }));
        } else {
            try std.testing.expect(false);
        }
    }
    {
        const a1 = Antenna{ .frequency = 'a', .x = 42, .y = 23 };
        const a2 = Antenna{ .frequency = 'a', .x = 82, .y = 10 };
        const pair_a1_a2 = try AntennaPair.create(a1, a2);
        const nodes = pair_a1_a2.getAntinodes();
        if (nodes[0]) |antinode_1| {
            try std.testing.expect(antinode_1.eql(Antinode{ .frequency = 'a', .x = 2, .y = 36 }));
        } else {
            try std.testing.expect(false);
        }

        if (nodes[1]) |_| {
            try std.testing.expect(false);
        } else {
            try std.testing.expect(true);
        }
    }
    {
        const a1 = Antenna{ .frequency = 'a', .x = 82, .y = 10 };
        const a2 = Antenna{ .frequency = 'a', .x = 42, .y = 23 };
        const pair_a1_a2 = try AntennaPair.create(a1, a2);
        const nodes = pair_a1_a2.getAntinodes();
        if (nodes[0]) |_| {
            try std.testing.expect(false);
        } else {
            try std.testing.expect(true);
        }

        if (nodes[1]) |antinode_1| {
            try std.testing.expect(antinode_1.eql(Antinode{ .frequency = 'a', .x = 2, .y = 36 }));
        } else {
            try std.testing.expect(false);
        }
    }
}

pub fn getResultDay08_1(allocator: std.mem.Allocator) !usize {
    _ = allocator;
    return 42;
}
