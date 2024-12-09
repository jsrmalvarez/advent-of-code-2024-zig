const std = @import("std");
const FREE_BLOCK = '.';

test "data expansion" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var arenaAllocator = arena.allocator();

    const data = "2333133121414131402";
    const U8List = std.DoublyLinkedList(u8);
    var list = U8List{};

    var string = [_]u8{undefined} ** 256;

    var listElementCount: usize = 0;
    var id: u8 = 0;
    var string_index: usize = 0;
    for (data, 0..data.len) |c, n| {
        const num = try std.fmt.charToDigit(c, 10);
        if (n % 2 == 0) {
            // num is number of file blocks
            for (0..num) |_| {
                const newNode: []std.DoublyLinkedList(u8).Node = try arenaAllocator.alloc(std.DoublyLinkedList(u8).Node, 1);
                newNode[0].data = id;
                list.append(&newNode[0]);
                listElementCount += 1;
                string[string_index] = id + '0';
                string_index += 1;
            }
            id += 1;
        } else {
            // num is number of free blocks
            for (0..num) |_| {
                const newNode: []std.DoublyLinkedList(u8).Node = try arenaAllocator.alloc(std.DoublyLinkedList(u8).Node, 1);
                newNode[0].data = FREE_BLOCK;
                list.append(&newNode[0]);
                listElementCount += 1;
                string[string_index] = FREE_BLOCK;
                string_index += 1;
            }
        }
    }
    std.debug.print("|{s}|\n", .{string[0..string_index]});
    try std.testing.expect(std.mem.eql(u8, "00...111...2...333.44.5555.6666.777.888899", string[0..string_index]));
}
pub fn getResultDay09_1(allocator: std.mem.Allocator) !u64 {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    var arenaAllocator = arena.allocator();

    const data = "2333133121414131402";
    //const listArray: []std.DoublyLinkedList(u8) = try allocator.alloc(std.DoublyLinkedList(u8), 1);
    //var list = &listArray[0];
    //defer allocator.free(listArray);
    const U8List = std.DoublyLinkedList(u8);
    var list = U8List{};

    var listElementCount: usize = 0;
    std.debug.print("|", .{});
    var id: u8 = 0;
    for (data, 0..data.len) |c, n| {
        const num = try std.fmt.charToDigit(c, 10);
        if (n % 2 == 0) {
            // num is number of file blocks
            for (0..num) |_| {
                const newNode: []std.DoublyLinkedList(u8).Node = try arenaAllocator.alloc(std.DoublyLinkedList(u8).Node, 1);
                newNode[0].data = id;
                list.append(&newNode[0]);
                listElementCount += 1;
                std.debug.print("{c}", .{id + '0'});
            }
            id += 1;
        } else {
            // num is number of free blocks
            for (0..num) |_| {
                const newNode: []std.DoublyLinkedList(u8).Node = try arenaAllocator.alloc(std.DoublyLinkedList(u8).Node, 1);
                newNode[0].data = FREE_BLOCK;
                list.append(&newNode[0]);
                listElementCount += 1;
                std.debug.print("{c}", .{FREE_BLOCK});
            }
        }
    }

    return 42;
}
