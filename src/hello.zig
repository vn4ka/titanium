const std = @import("std");

pub fn exec(args: []const u8) []const u8 {
    const result = std.fmt.allocPrint(std.heap.page_allocator, "Hello {s}!", .{args}) catch "out of memory";
    return result;
}
