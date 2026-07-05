const std = @import("std");
const vga = @import("vga.zig");
const ports = @import("ports.zig");

const scanmap = blk: {
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

var buffer: [256]u8 = undefined;
var len: usize = 0;

fn waitForKey() void {
    while (ports.inb(0x64) & 0x01 == 0) {
        asm volatile ("pause" ::: .{ .memory = true });
    }
}

fn scanKey() u8 {
    return ports.inb(0x60);
}

fn isBreakCode(scancode: u8) bool {
    return scancode >= 0x80;
}

fn scancodeToChar(scancode: u8) u8 {
    return scanmap[scancode];
}

fn isPrintable(ch: u8) bool {
    return ch >= 0x20 and ch < 0x7F;
}

fn appendBuffer(ch: u8) void {
    if (len < buffer.len - 1) {
        buffer[len] = ch;
        len += 1;
        vga.writeChar(ch);
    }
}

fn backspacePressed() void {
    if (len > 0) {
        len -= 1;
        vga.removeLast();
    }
}

fn enterPressed() []const u8 {
    buffer[len] = 0;
    vga.println("");
    return buffer[0..len];
}

pub fn input() []const u8 {
    len = 0;
    while (true) {
        waitForKey();
        const scancode = scanKey();
        if (isBreakCode(scancode)) continue;
        const ch = scancodeToChar(scancode);
        if (ch == 0) {} else if (ch == '\r') {
            return enterPressed();
        } else if (ch == '\x08') {
            backspacePressed();
        } else if (isPrintable(ch)) {
            appendBuffer(ch);
        }
    }
}
