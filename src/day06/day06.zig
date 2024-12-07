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

const GuardDirection = enum(u2) { N, E, S, W };

const GuardPosition = struct {
    x: usize,
    y: usize,
};
const GuardLocation = struct {
    position: GuardPosition,
    direction: GuardDirection,
};

const Guard = struct {
    location: GuardLocation,
    mat: *const matrix.Matrix(u8),
    positionSet: std.AutoArrayHashMap(GuardPosition, u0),
    locationSet: std.AutoArrayHashMap(GuardLocation, u0),
    loop_detected: bool,

    pub fn init(allocator: std.mem.Allocator, mat: *const matrix.Matrix(u8), direction: GuardDirection, x: usize, y: usize) !Guard {
        var positionSet = std.AutoArrayHashMap(GuardPosition, u0).init(allocator);
        var locationSet = std.AutoArrayHashMap(GuardLocation, u0).init(allocator);

        // Add init location and position
        try positionSet.put(GuardPosition{ .x = x, .y = y }, 0);
        try locationSet.put(GuardLocation{ .position = GuardPosition{ .x = x, .y = y }, .direction = direction }, 0);

        return Guard{
            .location = GuardLocation{
                .position = GuardPosition{
                    .x = x,
                    .y = y,
                },
                .direction = direction,
            },
            .mat = mat,
            .positionSet = positionSet,
            .locationSet = locationSet,
            .loop_detected = false,
        };
    }

    pub fn deinit(self: *Guard) void {
        self.positionSet.deinit();
        self.locationSet.deinit();
    }

    fn rotateDirection90DegCW(self: *Guard) void {
        self.location.direction = switch (self.location.direction) {
            GuardDirection.N => GuardDirection.E,
            GuardDirection.E => GuardDirection.S,
            GuardDirection.S => GuardDirection.W,
            GuardDirection.W => GuardDirection.N,
        };
    }

    pub fn tick(self: *Guard) !bool {
        return tick_rec(self, 0);
    }

    fn tick_rec(self: *Guard, recursion: usize) !bool {
        if (recursion == 4) {
            return error.Stuck;
        }

        if (self.location.position.x == 0 or self.location.position.y == 0) {
            // Guard exits the matrix
            return true;
        }

        const look_next_square_attempt = switch (self.location.direction) {
            GuardDirection.N => self.mat.at(self.location.position.y - 1, self.location.position.x),
            GuardDirection.E => self.mat.at(self.location.position.y, self.location.position.x + 1),
            GuardDirection.S => self.mat.at(self.location.position.y + 1, self.location.position.x),
            GuardDirection.W => self.mat.at(self.location.position.y, self.location.position.x - 1),
        };

        if (look_next_square_attempt) |next_square| {
            if (next_square == '#') {
                // turn right
                rotateDirection90DegCW(self);
                return tick_rec(self, recursion + 1);
            } else {

                // Move forward
                switch (self.location.direction) {
                    GuardDirection.N => self.location.position.y -= 1,
                    GuardDirection.E => self.location.position.x += 1,
                    GuardDirection.S => self.location.position.y += 1,
                    GuardDirection.W => self.location.position.x -= 1,
                }

                // Detect loop
                if (self.locationSet.get(self.location)) |_| {
                    self.loop_detected = true;
                }

                // Add current location and position
                try self.positionSet.put(self.location.position, 0);
                try self.locationSet.put(self.location, 0);

                return false;
            }
        } else |_| {
            // Guard exits the matrix
            return true;
        }
    }

    pub fn getPositionCount(self: Guard) usize {
        return self.positionSet.count();
    }
};

test "Guard normal" {
    // zig fmt: off
    const data = [_]u8{ '.', '#', '.',
                               '.', '.', '#',
                               '.', '^', '.',
                               '.', '.', '.' };
    // zig fmt: on
    const map = try matrix.Matrix(u8).init(std.testing.allocator, 4, 3, &data);
    defer map.deinit();

    // Locate guard in matrix
    if (map.find('^')) |guard_position| {
        try std.testing.expect(guard_position[0] == 2 and guard_position[1] == 1);
        const guard_x = guard_position[1];
        const guard_y = guard_position[0];
        var g = try Guard.init(std.testing.allocator, &map, GuardDirection.N, guard_x, guard_y);
        defer g.deinit();
        {
            const out_of_matrix = try g.tick();
            try std.testing.expect(out_of_matrix == false);
            try std.testing.expect(g.location.position.x == 1 and g.location.position.y == 1 and g.location.direction == GuardDirection.N);
        }
        {
            const out_of_matrix = try g.tick();
            try std.testing.expect(out_of_matrix == false);
            try std.testing.expect(g.location.position.x == 1 and g.location.position.y == 2 and g.location.direction == GuardDirection.S);
        }
        {
            const out_of_matrix = try g.tick();
            try std.testing.expect(out_of_matrix == false);
            try std.testing.expect(g.location.position.x == 1 and g.location.position.y == 3 and g.location.direction == GuardDirection.S);
        }
        {
            const out_of_matrix = try g.tick();
            try std.testing.expect(out_of_matrix == true);
            const position_count = g.positionSet.count();
            try std.testing.expect(position_count == 3);
        }
    } else {
        try std.testing.expect(false);
    }
}

test "Guard stuck" {
    // zig fmt: off
    const data = [_]u8{ '.', '#', '.',
                               '#', '^', '#',
                               '.', '#', '.',
                               '.', '.', '.' };
    // zig fmt: on
    const map = try matrix.Matrix(u8).init(std.testing.allocator, 4, 3, &data);
    defer map.deinit();

    // Locate guard in matrix
    if (map.find('^')) |guard_position| {
        try std.testing.expect(guard_position[0] == 1 and guard_position[1] == 1);
        const guard_x = guard_position[1];
        const guard_y = guard_position[0];
        var g = try Guard.init(std.testing.allocator, &map, GuardDirection.N, guard_x, guard_y);
        defer g.deinit();
        {
            try std.testing.expectError(error.Stuck, g.tick());
        }
    } else {
        try std.testing.expect(false);
    }
}

test "Guard loop" {
    // zig fmt: off
    const data = [_]u8{ '.', '#', '.', '.',
                               '.', '^', '.', '#',
                               '.', '.', '.', '.',
                               '#', '.', '.', '.',
                               '.', '.', '#', '.' };
    // zig fmt: on
    const map = try matrix.Matrix(u8).init(std.testing.allocator, 4, 4, &data);
    defer map.deinit();

    // Locate guard in matrix
    if (map.find('^')) |guard_position| {
        try std.testing.expect(guard_position[0] == 1 and guard_position[1] == 1);
        const guard_x = guard_position[1];
        const guard_y = guard_position[0];
        var g = try Guard.init(std.testing.allocator, &map, GuardDirection.N, guard_x, guard_y);
        defer g.deinit();

        for (1..4) |n| {
            _ = try g.tick();
            if (n == 4) {
                try std.testing.expect(g.loop_detected == true);
            } else {
                try std.testing.expect(g.loop_detected == false);
            }
        }
    } else {
        try std.testing.expect(false);
    }
}

pub fn readFileInto(file_name: []const u8, list: *std.ArrayList(u8)) ![2]usize {
    var input_file = try std.fs.cwd().openFile(file_name, .{ .mode = std.fs.File.OpenMode.read_only });
    defer input_file.close();

    var buf_reader = std.io.bufferedReader(input_file.reader());
    const in_stream = buf_reader.reader();

    return try loadDataInto(in_stream, list);
}

pub fn getResultDay06_1() !u64 {
    // Load input file data into matrix
    var list = std.ArrayList(u8).init(std.testing.allocator);
    defer list.deinit();
    const matrix_size = try readFileInto("src/day06/input_day_06.txt", &list);
    const data = list.items;
    const map: matrix.Matrix(u8) = try matrix.Matrix(u8).init(std.testing.allocator, matrix_size[0], matrix_size[1], data);
    defer map.deinit();

    // Locate guard in matrix
    const guard_position = map.find('^') orelse return 0;
    const guard_x = guard_position[1];
    const guard_y = guard_position[0];
    var g = try Guard.init(std.testing.allocator, &map, GuardDirection.N, guard_x, guard_y);
    defer g.deinit();

    while (true) {
        const out_of_matrix = try g.tick();
        if (out_of_matrix) {
            break;
        }
    }

    return g.positionSet.count();
}

pub fn getResultDay06_2() !u64 {
    // Load input file data into matrix
    var list = std.ArrayList(u8).init(std.testing.allocator);
    defer list.deinit();
    const matrix_size = try readFileInto("src/day06/input_day_06.txt", &list);
    const data = list.items;
    var map: matrix.Matrix(u8) = try matrix.Matrix(u8).init(std.testing.allocator, matrix_size[0], matrix_size[1], data);
    defer map.deinit();

    // Locate guard in matrix
    const guard_position = map.find('^') orelse return 0;
    const guard_x = guard_position[1];
    const guard_y = guard_position[0];

    var possibilities: usize = 0;

    for (0..matrix_size[0]) |n| {
        for (0..matrix_size[1]) |k| {
            const square = try map.at(n, k);
            const skip_square = switch (square) {
                '#', '^' => true,
                else => false,
            };
            if (skip_square) {
                continue;
            }
            const original_square = square;
            map.set('#', n, k);

            var g = try Guard.init(std.testing.allocator, &map, GuardDirection.N, guard_x, guard_y);
            defer g.deinit();

            while (true) {
                const out_of_map = g.tick() catch |err| {
                    if (err == error.Stuck) {
                        break;
                    } else {
                        return err;
                    }
                };

                if (out_of_map) {
                    break;
                }

                if (g.loop_detected) {
                    possibilities += 1;
                    break;
                }
            }

            map.set(original_square, n, k);
        }
    }

    return possibilities;
}
