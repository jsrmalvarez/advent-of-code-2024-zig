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
            for (0..self.num_rows) |n| {
                self.rows.items[n].deinit();
            }
            self.rows.deinit();
        }

        pub fn at(self: Self, n: usize, k: usize) !T {
            if (n >= self.rows.items.len) {
                return error.IndexOutOfBounds;
            }
            if (k >= self.rows.items[n].items.len) {
                return error.IndexOutOfBounds;
            }
            return self.rows.items[n].items[k];
        }

        pub fn set(self: Self, value: T, n: usize, k: usize) void {
            self.rows.items[n].items[k] = value;
        }

        pub fn find(self: Self, value: T) ?[2]usize {
            for (0..self.num_rows) |n| {
                for (0..self.num_cols) |k| {
                    if (self.rows.items[n].items[k] == value) {
                        return .{ n, k };
                    }
                }
            }

            return null;
        }
    };
}

pub const Direction = enum { E, W, N, S, NE, SE, SW, NW };

pub fn IteratorResult(comptime T: type) type {
    return struct {
        value: T,
        is_at_matrix_edge: bool,
    };
}

pub fn MatrixIterator(comptime T: type) type {
    return struct {
        const Self = @This();
        n: usize,
        k: usize,
        d: usize,
        dir: Direction,
        matrix: *const Matrix(T),

        pub fn init(matrix: *const Matrix(T), dir: Direction) Self {
            return Self{
                .n = 0,
                .k = 0,
                .d = 0,
                .dir = dir,
                .matrix = matrix,
            };
        }

        pub fn next(self: *Self) ?IteratorResult(T) {
            if (self.n < self.matrix.num_rows) {
                if (self.k < self.matrix.num_cols) {
                    switch (self.dir) {
                        Direction.E => return self.nextE(),
                        Direction.W => return self.nextW(),
                        Direction.S => return self.nextS(),
                        Direction.N => return self.nextN(),
                        Direction.NE => if (self.d <= self.matrix.num_rows + self.matrix.num_cols - 1) {
                            return self.nextNE();
                        },
                        Direction.NW => if (self.d <= self.matrix.num_rows + self.matrix.num_cols - 1) {
                            return self.nextNW();
                        },
                        Direction.SE => if (self.d <= self.matrix.num_rows + self.matrix.num_cols - 1) {
                            return self.nextSE();
                        },
                        Direction.SW => if (self.d <= self.matrix.num_rows + self.matrix.num_cols - 1) {
                            return self.nextSW();
                        },
                    }
                }
            }

            return null;
        }

        fn nextE(self: *Self) IteratorResult(T) {
            const item = self.matrix.at(self.n, self.k);
            var is_at_matrix_edge = false;
            self.k += 1;

            if (self.k == self.matrix.num_cols) {
                self.k = 0;
                self.n += 1;
                is_at_matrix_edge = true;
            }

            return IteratorResult(T){ .value = item, .is_at_matrix_edge = is_at_matrix_edge };
        }

        fn nextW(self: *Self) IteratorResult(T) {
            const item = self.matrix.at(self.n, self.matrix.num_cols - 1 - self.k);
            var is_at_matrix_edge = false;
            self.k += 1;

            if (self.k == self.matrix.num_cols) {
                self.k = 0;
                self.n += 1;
                is_at_matrix_edge = true;
            }

            return IteratorResult(T){ .value = item, .is_at_matrix_edge = is_at_matrix_edge };
        }

        fn nextS(self: *Self) IteratorResult(T) {
            const item = self.matrix.at(self.n, self.k);
            var is_at_matrix_edge = false;
            self.n += 1;

            if (self.n == self.matrix.num_rows) {
                self.n = 0;
                self.k += 1;
                is_at_matrix_edge = true;
            }

            return IteratorResult(T){ .value = item, .is_at_matrix_edge = is_at_matrix_edge };
        }

        fn nextN(self: *Self) IteratorResult(T) {
            const item = self.matrix.at(self.matrix.num_rows - 1 - self.n, self.k);
            var is_at_matrix_edge = false;
            self.n += 1;

            if (self.n == self.matrix.num_rows) {
                self.n = 0;
                self.k += 1;
                is_at_matrix_edge = true;
            }

            return IteratorResult(T){ .value = item, .is_at_matrix_edge = is_at_matrix_edge };
        }

        fn nextNE(self: *Self) IteratorResult(T) {
            const item = self.matrix.at(self.n, self.k);
            var is_at_matrix_edge = false;
            if (self.n == 0) {
                self.d += 1;
                is_at_matrix_edge = true;
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
                    is_at_matrix_edge = true;
                }
            }

            return IteratorResult(T){ .value = item, .is_at_matrix_edge = is_at_matrix_edge };
        }

        fn nextNW(self: *Self) IteratorResult(T) {
            const item = self.matrix.at(self.n, self.matrix.num_cols - 1 - self.k);
            var is_at_matrix_edge = false;
            if (self.n == 0) {
                self.d += 1;
                self.n = self.d;
                self.k = 0;
                is_at_matrix_edge = true;
            } else {
                self.n -= 1;
                if (self.k < self.matrix.num_cols - 1) {
                    self.k += 1;
                } else {
                    self.k = self.d - (self.matrix.num_cols - 1);
                    self.n = self.matrix.num_rows - 1;
                    self.d += 1;
                    is_at_matrix_edge = true;
                }
            }

            return IteratorResult(T){ .value = item, .is_at_matrix_edge = is_at_matrix_edge };
        }

        fn nextSE(self: *Self) IteratorResult(T) {
            const item = self.matrix.at(self.matrix.num_rows - 1 - self.n, self.k);
            var is_at_matrix_edge = false;
            if (self.n == 0) {
                self.d += 1;
                is_at_matrix_edge = true;
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
                    is_at_matrix_edge = true;
                }
            }

            return IteratorResult(T){ .value = item, .is_at_matrix_edge = is_at_matrix_edge };
        }

        fn nextSW(self: *Self) IteratorResult(T) {
            const item = self.matrix.at(self.matrix.num_rows - 1 - self.n, self.matrix.num_cols - 1 - self.k);
            var is_at_matrix_edge = false;
            if (self.n == 0) {
                self.d += 1;
                is_at_matrix_edge = true;
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
                    is_at_matrix_edge = true;
                }
            }

            return IteratorResult(T){ .value = item, .is_at_matrix_edge = is_at_matrix_edge };
        }
    };
}

test "test E" {
    const data = [_]u8{ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l' };
    const a: Matrix(u8) = try Matrix(u8).init(std.heap.page_allocator, 4, 3, &data);

    var iter = MatrixIterator(u8, Direction.E).init(&a);
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'a', .is_at_matrix_edge = false });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'b', .is_at_matrix_edge = false });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'c', .is_at_matrix_edge = true });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'd', .is_at_matrix_edge = false });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'e', .is_at_matrix_edge = false });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'f', .is_at_matrix_edge = true });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'g', .is_at_matrix_edge = false });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'h', .is_at_matrix_edge = false });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'i', .is_at_matrix_edge = true });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'j', .is_at_matrix_edge = false });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'k', .is_at_matrix_edge = false });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'l', .is_at_matrix_edge = true });
    try std.testing.expectEqual(iter.next(), null);
}

test "test W" {
    const data = [_]u8{ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l' };
    const a: Matrix(u8) = try Matrix(u8).init(std.heap.page_allocator, 4, 3, &data);

    var iter = MatrixIterator(u8, Direction.W).init(&a);
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'c', .is_at_matrix_edge = false });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'b', .is_at_matrix_edge = false });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'a', .is_at_matrix_edge = true });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'f', .is_at_matrix_edge = false });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'e', .is_at_matrix_edge = false });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'd', .is_at_matrix_edge = true });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'i', .is_at_matrix_edge = false });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'h', .is_at_matrix_edge = false });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'g', .is_at_matrix_edge = true });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'l', .is_at_matrix_edge = false });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'k', .is_at_matrix_edge = false });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'j', .is_at_matrix_edge = true });
    try std.testing.expectEqual(iter.next(), null);
}

test "test S" {
    const data = [_]u8{ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l' };
    const a: Matrix(u8) = try Matrix(u8).init(std.heap.page_allocator, 4, 3, &data);

    var iter = MatrixIterator(u8, Direction.S).init(&a);
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'a', .is_at_matrix_edge = false });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'd', .is_at_matrix_edge = false });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'g', .is_at_matrix_edge = false });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'j', .is_at_matrix_edge = true });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'b', .is_at_matrix_edge = false });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'e', .is_at_matrix_edge = false });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'h', .is_at_matrix_edge = false });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'k', .is_at_matrix_edge = true });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'c', .is_at_matrix_edge = false });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'f', .is_at_matrix_edge = false });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'i', .is_at_matrix_edge = false });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'l', .is_at_matrix_edge = true });
    try std.testing.expectEqual(iter.next(), null);
}

test "test N" {
    const data = [_]u8{ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l' };
    const a: Matrix(u8) = try Matrix(u8).init(std.heap.page_allocator, 4, 3, &data);

    var iter = MatrixIterator(u8, Direction.N).init(&a);
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'j', .is_at_matrix_edge = false });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'g', .is_at_matrix_edge = false });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'd', .is_at_matrix_edge = false });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'a', .is_at_matrix_edge = true });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'k', .is_at_matrix_edge = false });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'h', .is_at_matrix_edge = false });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'e', .is_at_matrix_edge = false });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'b', .is_at_matrix_edge = true });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'l', .is_at_matrix_edge = false });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'i', .is_at_matrix_edge = false });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'f', .is_at_matrix_edge = false });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'c', .is_at_matrix_edge = true });
    try std.testing.expectEqual(iter.next(), null);
}

test "test NE" {
    const data = [_]u8{ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l' };
    const a: Matrix(u8) = try Matrix(u8).init(std.heap.page_allocator, 4, 3, &data);

    var iter = MatrixIterator(u8, Direction.NE).init(&a);
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'a', .is_at_matrix_edge = true });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'd', .is_at_matrix_edge = false });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'b', .is_at_matrix_edge = true });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'g', .is_at_matrix_edge = false });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'e', .is_at_matrix_edge = false });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'c', .is_at_matrix_edge = true });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'j', .is_at_matrix_edge = false });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'h', .is_at_matrix_edge = false });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'f', .is_at_matrix_edge = true });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'k', .is_at_matrix_edge = false });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'i', .is_at_matrix_edge = true });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'l', .is_at_matrix_edge = true });
    try std.testing.expectEqual(iter.next(), null);
}

test "test NW" {
    const data = [_]u8{ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l' };
    const a: Matrix(u8) = try Matrix(u8).init(std.heap.page_allocator, 4, 3, &data);

    var iter = MatrixIterator(u8, Direction.NW).init(&a);
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'c', .is_at_matrix_edge = true });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'f', .is_at_matrix_edge = false });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'b', .is_at_matrix_edge = true });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'i', .is_at_matrix_edge = false });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'e', .is_at_matrix_edge = false });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'a', .is_at_matrix_edge = true });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'l', .is_at_matrix_edge = false });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'h', .is_at_matrix_edge = false });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'd', .is_at_matrix_edge = true });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'k', .is_at_matrix_edge = false });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'g', .is_at_matrix_edge = true });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'j', .is_at_matrix_edge = true });
    try std.testing.expectEqual(iter.next(), null);
}

test "test SE" {
    const data = [_]u8{ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l' };
    const a: Matrix(u8) = try Matrix(u8).init(std.heap.page_allocator, 4, 3, &data);

    var iter = MatrixIterator(u8, Direction.SE).init(&a);
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'j', .is_at_matrix_edge = true });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'g', .is_at_matrix_edge = false });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'k', .is_at_matrix_edge = true });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'd', .is_at_matrix_edge = false });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'h', .is_at_matrix_edge = false });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'l', .is_at_matrix_edge = true });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'a', .is_at_matrix_edge = false });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'e', .is_at_matrix_edge = false });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'i', .is_at_matrix_edge = true });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'b', .is_at_matrix_edge = false });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'f', .is_at_matrix_edge = true });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'c', .is_at_matrix_edge = true });
    try std.testing.expectEqual(iter.next(), null);
}

test "test SW" {
    const data = [_]u8{ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l' };
    const a: Matrix(u8) = try Matrix(u8).init(std.heap.page_allocator, 4, 3, &data);

    var iter = MatrixIterator(u8, Direction.SW).init(&a);
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'l', .is_at_matrix_edge = true });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'i', .is_at_matrix_edge = false });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'k', .is_at_matrix_edge = true });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'f', .is_at_matrix_edge = false });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'h', .is_at_matrix_edge = false });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'j', .is_at_matrix_edge = true });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'c', .is_at_matrix_edge = false });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'e', .is_at_matrix_edge = false });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'g', .is_at_matrix_edge = true });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'b', .is_at_matrix_edge = false });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'd', .is_at_matrix_edge = true });
    try std.testing.expectEqual(iter.next(), IteratorResult(u8){ .value = 'a', .is_at_matrix_edge = true });
    try std.testing.expectEqual(iter.next(), null);
}
