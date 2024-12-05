const std = @import("std");

pub fn Matrix(comptime T: type) type {
    return struct {
        const Self = @This();

        allocator: std.mem.Allocator,
        rows: std.ArrayList(std.ArrayList(T)),
        num_rows: usize,
        num_cols: usize,

        /// Deinitialize with `deinit`
        pub fn init(allocator: std.mem.Allocator, num_rows: usize, num_cols: usize, data: []const u8) !Self {
            var matrix = Self{
                .allocator = allocator,
                .rows = try std.ArrayList(std.ArrayList(T)).initCapacity(allocator, num_rows),
                .num_rows = num_rows,
                .num_cols = num_cols,
            };

            for (0..num_rows) |n| {
                var col = try std.ArrayList(T).initCapacity(allocator, num_cols);
                for (0..num_cols) |k| {
                    const datum = data[n * num_cols + k];
                    try col.append(datum);
                }
                try matrix.rows.append(col);
            }
            return matrix;
        }

        /// Release all allocated memory.
        pub fn deinit(self: Self) void {
            self.rows.deinit();
        }

        pub fn at(self: Self, n: usize, k: usize) T {
            return self.rows.items[n].items[k];
        }
    };
}

pub const Direction = enum { E, W, N, S, NE, SE, SW, NW };

pub fn MatrixIterator(comptime T: type, comptime dir: Direction) type {
    return struct {
        const Self = @This();
        n: usize,
        k: usize,
        d: usize,
        matrix: *const Matrix(T),

        pub fn init(matrix: *const Matrix(T)) Self {
            return Self{
                .n = 0,
                .k = 0,
                .d = 0,
                .matrix = matrix,
            };
        }

        pub fn next(self: *Self) ?T {
            switch (dir) {
                Direction.E => return self.nextE(),
                Direction.W => return self.nextW(),
                Direction.S => return self.nextS(),
                Direction.N => return self.nextN(),
                Direction.NE => return self.nextNE(),
                Direction.NW => return self.nextNW(),
                Direction.SE => return self.nextSE(),
                Direction.SW => return self.nextSW(),
            }
        }

        fn nextE(self: *Self) ?T {
            if (self.n < self.matrix.num_rows) {
                if (self.k < self.matrix.num_cols) {
                    const item = self.matrix.at(self.n, self.k);

                    self.k += 1;

                    if (self.k == self.matrix.num_cols) {
                        self.k = 0;
                        self.n += 1;
                    }

                    return item;
                }
            }

            return null;
        }

        fn nextW(self: *Self) ?T {
            if (self.n < self.matrix.num_rows) {
                if (self.k < self.matrix.num_cols) {
                    const item = self.matrix.at(self.n, self.matrix.num_cols - 1 - self.k);

                    self.k += 1;

                    if (self.k == self.matrix.num_cols) {
                        self.k = 0;
                        self.n += 1;
                    }

                    return item;
                }
            }

            return null;
        }

        fn nextS(self: *Self) ?T {
            if (self.n < self.matrix.num_rows) {
                if (self.k < self.matrix.num_cols) {
                    const item = self.matrix.at(self.n, self.k);

                    self.n += 1;

                    if (self.n == self.matrix.num_rows) {
                        self.n = 0;
                        self.k += 1;
                    }

                    return item;
                }
            }

            return null;
        }

        fn nextN(self: *Self) ?T {
            if (self.n < self.matrix.num_rows) {
                if (self.k < self.matrix.num_cols) {
                    const item = self.matrix.at(self.matrix.num_rows - 1 - self.n, self.k);

                    self.n += 1;

                    if (self.n == self.matrix.num_rows) {
                        self.n = 0;
                        self.k += 1;
                    }

                    return item;
                }
            }

            return null;
        }

        fn nextNE(self: *Self) ?T {
            if (self.d <= self.matrix.num_rows + self.matrix.num_cols - 1) {
                if (self.n < self.matrix.num_rows) {
                    if (self.k < self.matrix.num_cols) {
                        const item = self.matrix.at(self.n, self.k);

                        if (self.n == 0) {
                            self.d += 1;
                            self.n = self.d;
                            self.k = 0;
                        } else {
                            self.n -= 1;
                            if (self.k < self.matrix.num_cols - 1) {
                                self.k += 1;
                            } else {
                                self.k = self.d - (self.matrix.num_cols - 1);
                                self.n = self.matrix.num_rows - 1;
                                self.d += 1;
                            }
                        }

                        return item;
                    }
                }
            }

            return null;
        }

        fn nextNW(self: *Self) ?T {
            if (self.d <= self.matrix.num_rows + self.matrix.num_cols - 1) {
                if (self.n < self.matrix.num_rows) {
                    if (self.k < self.matrix.num_cols) {
                        const item = self.matrix.at(self.n, self.matrix.num_cols - 1 - self.k);

                        if (self.n == 0) {
                            self.d += 1;
                            self.n = self.d;
                            self.k = 0;
                        } else {
                            self.n -= 1;
                            if (self.k < self.matrix.num_cols - 1) {
                                self.k += 1;
                            } else {
                                self.k = self.d - (self.matrix.num_cols - 1);
                                self.n = self.matrix.num_rows - 1;
                                self.d += 1;
                            }
                        }

                        return item;
                    }
                }
            }

            return null;
        }

        fn nextSE(self: *Self) ?T {
            if (self.d <= self.matrix.num_rows + self.matrix.num_cols - 1) {
                if (self.n < self.matrix.num_rows) {
                    if (self.k < self.matrix.num_cols) {
                        const item = self.matrix.at(self.matrix.num_rows - 1 - self.n, self.k);

                        if (self.n == 0) {
                            self.d += 1;
                            self.n = self.d;
                            self.k = 0;
                        } else {
                            self.n -= 1;
                            if (self.k < self.matrix.num_cols - 1) {
                                self.k += 1;
                            } else {
                                self.k = self.d - (self.matrix.num_cols - 1);
                                self.n = self.matrix.num_rows - 1;
                                self.d += 1;
                            }
                        }

                        return item;
                    }
                }
            }

            return null;
        }

        fn nextSW(self: *Self) ?T {
            if (self.d <= self.matrix.num_rows + self.matrix.num_cols - 1) {
                if (self.n < self.matrix.num_rows) {
                    if (self.k < self.matrix.num_cols) {
                        const item = self.matrix.at(self.matrix.num_rows - 1 - self.n, self.matrix.num_cols - 1 - self.k);

                        if (self.n == 0) {
                            self.d += 1;
                            self.n = self.d;
                            self.k = 0;
                        } else {
                            self.n -= 1;
                            if (self.k < self.matrix.num_cols - 1) {
                                self.k += 1;
                            } else {
                                self.k = self.d - (self.matrix.num_cols - 1);
                                self.n = self.matrix.num_rows - 1;
                                self.d += 1;
                            }
                        }

                        return item;
                    }
                }
            }

            return null;
        }
    };
}

test "test E" {
    const data = [_]u8{ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l' };
    const a: Matrix(u8) = try Matrix(u8).init(std.heap.page_allocator, 4, 3, &data);

    var iter = MatrixIterator(u8, Direction.E).init(&a);
    try std.testing.expectEqual(iter.next(), 'a');
    try std.testing.expectEqual(iter.next(), 'b');
    try std.testing.expectEqual(iter.next(), 'c');
    try std.testing.expectEqual(iter.next(), 'd');
    try std.testing.expectEqual(iter.next(), 'e');
    try std.testing.expectEqual(iter.next(), 'f');
    try std.testing.expectEqual(iter.next(), 'g');
    try std.testing.expectEqual(iter.next(), 'h');
    try std.testing.expectEqual(iter.next(), 'i');
    try std.testing.expectEqual(iter.next(), 'j');
    try std.testing.expectEqual(iter.next(), 'k');
    try std.testing.expectEqual(iter.next(), 'l');
    try std.testing.expectEqual(iter.next(), null);
}

test "test W" {
    const data = [_]u8{ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l' };
    const a: Matrix(u8) = try Matrix(u8).init(std.heap.page_allocator, 4, 3, &data);

    var iter = MatrixIterator(u8, Direction.W).init(&a);
    try std.testing.expectEqual(iter.next(), 'c');
    try std.testing.expectEqual(iter.next(), 'b');
    try std.testing.expectEqual(iter.next(), 'a');
    try std.testing.expectEqual(iter.next(), 'f');
    try std.testing.expectEqual(iter.next(), 'e');
    try std.testing.expectEqual(iter.next(), 'd');
    try std.testing.expectEqual(iter.next(), 'i');
    try std.testing.expectEqual(iter.next(), 'h');
    try std.testing.expectEqual(iter.next(), 'g');
    try std.testing.expectEqual(iter.next(), 'l');
    try std.testing.expectEqual(iter.next(), 'k');
    try std.testing.expectEqual(iter.next(), 'j');
    try std.testing.expectEqual(iter.next(), null);
}

test "test S" {
    const data = [_]u8{ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l' };
    const a: Matrix(u8) = try Matrix(u8).init(std.heap.page_allocator, 4, 3, &data);

    var iter = MatrixIterator(u8, Direction.S).init(&a);
    try std.testing.expectEqual(iter.next(), 'a');
    try std.testing.expectEqual(iter.next(), 'd');
    try std.testing.expectEqual(iter.next(), 'g');
    try std.testing.expectEqual(iter.next(), 'j');
    try std.testing.expectEqual(iter.next(), 'b');
    try std.testing.expectEqual(iter.next(), 'e');
    try std.testing.expectEqual(iter.next(), 'h');
    try std.testing.expectEqual(iter.next(), 'k');
    try std.testing.expectEqual(iter.next(), 'c');
    try std.testing.expectEqual(iter.next(), 'f');
    try std.testing.expectEqual(iter.next(), 'i');
    try std.testing.expectEqual(iter.next(), 'l');
    try std.testing.expectEqual(iter.next(), null);
}

test "test N" {
    const data = [_]u8{ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l' };
    const a: Matrix(u8) = try Matrix(u8).init(std.heap.page_allocator, 4, 3, &data);

    var iter = MatrixIterator(u8, Direction.N).init(&a);
    try std.testing.expectEqual(iter.next(), 'j');
    try std.testing.expectEqual(iter.next(), 'g');
    try std.testing.expectEqual(iter.next(), 'd');
    try std.testing.expectEqual(iter.next(), 'a');
    try std.testing.expectEqual(iter.next(), 'k');
    try std.testing.expectEqual(iter.next(), 'h');
    try std.testing.expectEqual(iter.next(), 'e');
    try std.testing.expectEqual(iter.next(), 'b');
    try std.testing.expectEqual(iter.next(), 'l');
    try std.testing.expectEqual(iter.next(), 'i');
    try std.testing.expectEqual(iter.next(), 'f');
    try std.testing.expectEqual(iter.next(), 'c');
    try std.testing.expectEqual(iter.next(), null);
}

test "test NE" {
    const data = [_]u8{ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l' };
    const a: Matrix(u8) = try Matrix(u8).init(std.heap.page_allocator, 4, 3, &data);

    var iter = MatrixIterator(u8, Direction.NE).init(&a);
    try std.testing.expectEqual(iter.next(), 'a');
    try std.testing.expectEqual(iter.next(), 'd');
    try std.testing.expectEqual(iter.next(), 'b');
    try std.testing.expectEqual(iter.next(), 'g');
    try std.testing.expectEqual(iter.next(), 'e');
    try std.testing.expectEqual(iter.next(), 'c');
    try std.testing.expectEqual(iter.next(), 'j');
    try std.testing.expectEqual(iter.next(), 'h');
    try std.testing.expectEqual(iter.next(), 'f');
    try std.testing.expectEqual(iter.next(), 'k');
    try std.testing.expectEqual(iter.next(), 'i');
    try std.testing.expectEqual(iter.next(), 'l');
    try std.testing.expectEqual(iter.next(), null);
}

test "test NW" {
    const data = [_]u8{ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l' };
    const a: Matrix(u8) = try Matrix(u8).init(std.heap.page_allocator, 4, 3, &data);

    var iter = MatrixIterator(u8, Direction.NW).init(&a);
    try std.testing.expectEqual(iter.next(), 'c');
    try std.testing.expectEqual(iter.next(), 'f');
    try std.testing.expectEqual(iter.next(), 'b');
    try std.testing.expectEqual(iter.next(), 'i');
    try std.testing.expectEqual(iter.next(), 'e');
    try std.testing.expectEqual(iter.next(), 'a');
    try std.testing.expectEqual(iter.next(), 'l');
    try std.testing.expectEqual(iter.next(), 'h');
    try std.testing.expectEqual(iter.next(), 'd');
    try std.testing.expectEqual(iter.next(), 'k');
    try std.testing.expectEqual(iter.next(), 'g');
    try std.testing.expectEqual(iter.next(), 'j');
    try std.testing.expectEqual(iter.next(), null);
}

test "test SE" {
    const data = [_]u8{ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l' };
    const a: Matrix(u8) = try Matrix(u8).init(std.heap.page_allocator, 4, 3, &data);

    var iter = MatrixIterator(u8, Direction.SE).init(&a);
    try std.testing.expectEqual(iter.next(), 'j');
    try std.testing.expectEqual(iter.next(), 'g');
    try std.testing.expectEqual(iter.next(), 'k');
    try std.testing.expectEqual(iter.next(), 'd');
    try std.testing.expectEqual(iter.next(), 'h');
    try std.testing.expectEqual(iter.next(), 'l');
    try std.testing.expectEqual(iter.next(), 'a');
    try std.testing.expectEqual(iter.next(), 'e');
    try std.testing.expectEqual(iter.next(), 'i');
    try std.testing.expectEqual(iter.next(), 'b');
    try std.testing.expectEqual(iter.next(), 'f');
    try std.testing.expectEqual(iter.next(), 'c');
    try std.testing.expectEqual(iter.next(), null);
}

test "test SW" {
    const data = [_]u8{ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l' };
    const a: Matrix(u8) = try Matrix(u8).init(std.heap.page_allocator, 4, 3, &data);

    var iter = MatrixIterator(u8, Direction.SW).init(&a);
    try std.testing.expectEqual(iter.next(), 'l');
    try std.testing.expectEqual(iter.next(), 'i');
    try std.testing.expectEqual(iter.next(), 'k');
    try std.testing.expectEqual(iter.next(), 'f');
    try std.testing.expectEqual(iter.next(), 'h');
    try std.testing.expectEqual(iter.next(), 'j');
    try std.testing.expectEqual(iter.next(), 'c');
    try std.testing.expectEqual(iter.next(), 'e');
    try std.testing.expectEqual(iter.next(), 'g');
    try std.testing.expectEqual(iter.next(), 'b');
    try std.testing.expectEqual(iter.next(), 'd');
    try std.testing.expectEqual(iter.next(), 'a');
    try std.testing.expectEqual(iter.next(), null);
}
