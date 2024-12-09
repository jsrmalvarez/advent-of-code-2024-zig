const std = @import("std");
const FREE_BLOCK = '.';

test "data expansion" {
    const data = "2333133121414131402";
    var list: std.DoublyLinkedList(u8) = undefined;
    var listElementCount: usize = 0;

    for (data, 0..data.len) |c, n| {
        const id = @as(u8, @intCast(n));
        const num = try std.fmt.charToDigit(c, 10);
        if (n % 2 == 0) {
            // num is number of file blocks
            for (0..num) |_| {
                const newNode = std.testing.allocator.alloc(std.DoublyLinkedList(u8).Node{ .data = id }, 1);
                list.append(newNode);
                listElementCount += 1;
            }
        } else {
            // num is number of free blocks
            for (0..num) |_| {
                list.append(FREE_BLOCK);
                listElementCount += 1;
            }
        }
    }

    var string = [_]u8{undefined} ** 256;
    for (list, 0..listElementCount) |e, n| {
        string[n] = e;
    }

    try std.testing.expect(true);
}
pub fn getResultDay09_1(allocator: std.mem.Allocator) !u64 {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    var arenaAllocator = arena.allocator();

    const data = "2333133121414131402";
    const listArray: []std.DoublyLinkedList(u8) = try allocator.alloc(std.DoublyLinkedList(u8), 1);
    var list = &listArray[0];
    defer allocator.free(listArray);

    var listElementCount: usize = 0;

    for (data, 0..data.len) |c, n| {
        const id = @as(u8, @intCast(n));
        const num = try std.fmt.charToDigit(c, 10);
        if (n % 2 == 0) {
            // num is number of file blocks
            for (0..num) |_| {
                const newNode: []std.DoublyLinkedList(u8).Node = try arenaAllocator.alloc(std.DoublyLinkedList(u8).Node, 1);
                newNode[0].data = id;
                list.append(&newNode[0]);
                listElementCount += 1;
            }
        } else {
            // num is number of free blocks
            for (0..num) |_| {
                const newNode: []std.DoublyLinkedList(u8).Node = try arenaAllocator.alloc(std.DoublyLinkedList(u8).Node, 1);
                newNode[0].data = FREE_BLOCK;
                list.append(&newNode[0]);
                listElementCount += 1;
            }
        }
    }

    var string = [_]u8{undefined} ** 256;
    for (0..listElementCount) |n| {
        if (list.pop()) |node| {
            string[n] = node.data;
        }
    }

    return 42;
}
