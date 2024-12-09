const std = @import("std");
const FREE_BLOCK = '.';

pub fn expandData(arenaAllocator: std.mem.Allocator, data: []const u8) !std.DoublyLinkedList(u8) {
    var list = std.DoublyLinkedList(u8){};
    var id: u8 = 0;
    for (data, 0..data.len) |c, n| {
        const num = try std.fmt.charToDigit(c, 10);
        if (n % 2 == 0) {
            // num is number of file blocks
            for (0..num) |_| {
                const newNode: []std.DoublyLinkedList(u8).Node = try arenaAllocator.alloc(std.DoublyLinkedList(u8).Node, 1);
                newNode[0].data = id;
                list.append(&newNode[0]);
            }
            id += 1;
        } else {
            // num is number of free blocks
            for (0..num) |_| {
                const newNode: []std.DoublyLinkedList(u8).Node = try arenaAllocator.alloc(std.DoublyLinkedList(u8).Node, 1);
                newNode[0].data = FREE_BLOCK;
                list.append(&newNode[0]);
            }
        }
    }

    return list;
}

test "data expansion" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const data = "2333133121414131402";
    const list = try expandData(arena.allocator(), data[0..]);

    var string = [_]u8{undefined} ** 256;
    var string_index: usize = 0;

    if (list.first) |first| {
        var node = first;
        while (true) {
            if (node.data == FREE_BLOCK) {
                string[string_index] = FREE_BLOCK;
            } else {
                string[string_index] = std.fmt.digitToChar(node.data, std.fmt.Case.lower);
            }
            string_index += 1;
            if (node.next) |next| {
                node = next;
            } else {
                break;
            }
        }
    }
    std.debug.print("|{s}|\n", .{string[0..string_index]});
    try std.testing.expect(std.mem.eql(u8, "00...111...2...333.44.5555.6666.777.888899", string[0..string_index]));
}
pub fn getResultDay09_1(allocator: std.mem.Allocator) !u64 {
    _ = allocator;
    return 42;
}
