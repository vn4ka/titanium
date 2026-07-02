const std = @import("std");
const vga = @import("vga.zig");
const ports = @import("ports.zig");

const scancode_map = blk: {
    var map: [256]u8 = undefined;
    for (&map) |*v| v.* = 0;
    map[0x02] = '1';
    map[0x03] = '2';
    map[0x04] = '3';
    map[0x05] = '4';
    map[0x06] = '5';
    map[0x07] = '6';
    map[0x08] = '7';
    map[0x09] = '8';
    map[0x0A] = '9';
    map[0x0B] = '0';
    map[0x10] = 'q';
    map[0x11] = 'w';
    map[0x12] = 'e';
    map[0x13] = 'r';
    map[0x14] = 't';
    map[0x15] = 'y';
    map[0x16] = 'u';
    map[0x17] = 'i';
    map[0x18] = 'o';
    map[0x19] = 'p';
    map[0x1E] = 'a';
    map[0x1F] = 's';
    map[0x20] = 'd';
    map[0x21] = 'f';
    map[0x22] = 'g';
    map[0x23] = 'h';
    map[0x24] = 'j';
    map[0x25] = 'k';
    map[0x26] = 'l';
    map[0x2C] = 'z';
    map[0x2D] = 'x';
    map[0x2E] = 'c';
    map[0x2F] = 'v';
    map[0x30] = 'b';
    map[0x31] = 'n';
    map[0x32] = 'm';
    map[0x39] = ' ';
    map[0x0E] = '\x08';
    map[0x1C] = '\r';
    break :blk map;
};
var input_buffer: [256]u8 = undefined;
pub fn input() []const u8 {
    var len: usize = 0;

    while (true) {
        while (ports.inb(0x64) & 0x01 == 0) {}
        const scancode = ports.inb(0x60);
        if (scancode >= 0x80) continue;
        const ch = scancode_map[scancode];
        if (ch == 0) {} else if (ch == '\r') {
            input_buffer[len] = 0;
            vga.println("");
            return input_buffer[0..len];
        } else if (ch == '\x08') {
            if (len > 0) {
                len -= 1;
                vga.removeLast();
            }
        } else if (ch >= 0x20 and ch < 0x7F) {
            if (len < input_buffer.len - 1) {
                input_buffer[len] = ch;
                len += 1;
                vga.writeChar(ch);
            }
        }
    }
}
