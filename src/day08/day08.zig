const std = @import("std");

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

    pub fn getAntinodes(self: AntennaPair) [2]?Antinode {
        const x1 = self.first.x;
        const y1 = self.first.y;
        const x2 = self.second.x;
        const y2 = self.second.y;

        if (x2 >= x1 and y2 >= y1) {
            const dist_x = x2 - x1;
            const dist_y = y2 - y1;

            const antinode1: ?Antinode = if (x1 >= dist_x and y1 >= dist_y)
                Antinode{
                    .frequency = self.first.frequency,
                    .x = x1 - dist_x,
                    .y = y1 - dist_y,
                }
            else
                null;

            const antinode2: ?Antinode =
                Antinode{
                .frequency = self.first.frequency,
                .x = x2 + dist_x,
                .y = y2 + dist_y,
            };

            return .{ antinode1, antinode2 };
        } else if (x2 < x1 and y2 >= y1) {
            const dist_x = x1 - x2;
            const dist_y = y2 - y1;

            const antinode1: ?Antinode = if (y1 >= dist_y)
                Antinode{
                    .frequency = self.first.frequency,
                    .x = x1 + dist_x,
                    .y = y1 - dist_y,
                }
            else
                null;

            const antinode2: ?Antinode = if (x2 >= dist_x)
                Antinode{
                    .frequency = self.first.frequency,
                    .x = x2 - dist_x,
                    .y = y2 + dist_y,
                }
            else
                null;

            return .{ antinode1, antinode2 };
        } else if (x2 < x1 and y2 < y1) {
            const dist_x = x1 - x2;
            const dist_y = y1 - y2;

            const antinode1: ?Antinode =
                Antinode{
                .frequency = self.first.frequency,
                .x = x1 + dist_x,
                .y = y1 + dist_y,
            };

            const antinode2: ?Antinode = if (x2 >= dist_x and y2 >= dist_y)
                Antinode{
                    .frequency = self.first.frequency,
                    .x = x2 - dist_x,
                    .y = y2 - dist_y,
                }
            else
                null;

            return .{ antinode1, antinode2 };
        } else if (x2 >= x1 and y2 < y1) {
            const dist_x = x2 - x1;
            const dist_y = y1 - y2;

            const antinode1: ?Antinode = if (x1 >= dist_x)
                Antinode{
                    .frequency = self.first.frequency,
                    .x = x1 - dist_x,
                    .y = y1 + dist_y,
                }
            else
                null;

            const antinode2: ?Antinode = if (y2 >= dist_y)
                Antinode{
                    .frequency = self.first.frequency,
                    .x = x2 + dist_x,
                    .y = y2 - dist_y,
                }
            else
                null;

            return .{ antinode1, antinode2 };
        } else {
            unreachable;
        }
    }

    pub fn getAntinodes2(self: AntennaPair) [2]?Antinode {
        const vector = self.getVector();
        const vector_x = vector[0];
        const vector_y = vector[1];

        const first_x: isize = @intCast(self.first.x);
        const first_y: isize = @intCast(self.first.y);
        const second_x: isize = @intCast(self.second.x);
        const second_y: isize = @intCast(self.second.y);

        const antinode1_x = first_x - vector_x;
        const antinode1_y = first_y - vector_y;

        const antinode2_x = second_x + vector_x;
        const antinode2_y = second_y + vector_y;

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
    pub fn hash(self: AntinodeContext, antinode: Antinode) u64 {
        _ = self;
        return antinode.hash();
    }

    pub fn eql(self: AntinodeContext, first: Antinode, second: Antinode) bool {
        _ = self;
        return first.eql(second);
    }
};

const Location = struct {
    x: usize,
    y: usize,

    pub fn hash(self: Location) u64 {
        const x = @as(u64, self.x);
        const y = @as(u64, self.y);
        const hash_calculation = ((x & 0x00000000FFFFFFFF) << 32) | (y & 0x00000000FFFFFFFF);
        return hash_calculation;
    }

    pub fn eql(self: Location, other: Location) bool {
        return self.hash() == other.hash();
    }
};

const LocationContext = struct {
    pub fn hash(self: LocationContext, location: Location) u64 {
        _ = self;
        return location.hash();
    }

    pub fn eql(self: LocationContext, first: Location, second: Location) bool {
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
                    return error.BadFormat;
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

pub fn getResultDay08_1(allocator: std.mem.Allocator) !usize {
    const matrix = @import("../utils/matrix.zig");
    var list = std.ArrayList(u8).init(allocator);
    defer list.deinit();

    //const data = "......#....#...#....0.......#0....#...#....0........0....#...#....A........#........#......#............A............A............#...........#.";
    //const map: matrix.Matrix(u8) = try matrix.Matrix(u8).init(std.testing.allocator, 12, 12, data);

    const matrix_size = try readFileInto("src/day08/input_day_08.txt", &list);
    const data = list.items;
    const map: matrix.Matrix(u8) = try matrix.Matrix(u8).init(allocator, matrix_size[0], matrix_size[1], data);
    defer map.deinit();

    var antennas = std.ArrayList(Antenna).init(allocator);
    defer antennas.deinit();

    // Get antennas
    for (0..map.num_rows) |n| {
        for (0..map.num_cols) |k| {
            const c = try map.at(n, k);
            if (std.ascii.isAlphanumeric(c)) {
                const antenna = Antenna{
                    .frequency = c,
                    .x = n,
                    .y = k,
                };
                try antennas.append(antenna);
            }
        }
    }

    // Get antenna pairs
    var pairs = std.HashMap(AntennaPair, u0, AntennaPairContext, 1).init(allocator);
    defer pairs.deinit();

    for (antennas.items) |ai| {
        for (antennas.items) |aj| {
            const pair: ?AntennaPair = AntennaPair.create(ai, aj) catch null;
            if (pair) |p| {
                try pairs.put(p, 0);
            }
        }
    }

    var unique_locations_with_antinodes_within_bounds = std.HashMap(Location, u0, LocationContext, 1).init(allocator);
    defer unique_locations_with_antinodes_within_bounds.deinit();
    var pair_iterator = pairs.iterator();
    while (pair_iterator.next()) |e| {
        const p = e.key_ptr;
        const maybe_antinodes = p.getAntinodes();
        for (maybe_antinodes) |maybe_antinode| {
            if (maybe_antinode) |antinode| {
                if (antinode.x < map.num_rows and antinode.y < map.num_cols) {
                    try unique_locations_with_antinodes_within_bounds.put(Location{ .x = antinode.x, .y = antinode.y }, 0);
                }
            }
        }
    }

    return unique_locations_with_antinodes_within_bounds.count();
}
