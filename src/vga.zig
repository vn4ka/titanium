const ports = @import("ports.zig");
pub const VGA_WIDTH: u16 = 80;
pub const VGA_HEIGHT: u16 = 25;
pub const VGA_BUFFER: usize = 0xB8000;

pub const Color = enum(u4) {
    black = 0,
    blue = 1,
    green = 2,
    cyan = 3,
    red = 4,
    magenta = 5,
    brown = 6,
    light_grey = 7,
    dark_grey = 8,
    light_blue = 9,
    light_green = 10,
    light_cyan = 11,
    light_red = 12,
    light_magenta = 13,
    yellow = 14,
    white = 15,
};

pub fn vgaEntry(char: u8, fg: Color, bg: Color) u16 {
    const color: u8 = @as(u8, @intFromEnum(bg)) << 4 | @intFromEnum(fg);
    return @as(u16, color) << 8 | char;
}

pub var cursor_row: u16 = 0;
pub var cursor_col: u16 = 0;

pub fn renderCursor() void {
    const pos = cursor_row * VGA_WIDTH + cursor_col;
    ports.outb(0x3D4, 0x0F);
    ports.outb(0x3D5, @truncate(pos));
    ports.outb(0x3D4, 0x0E);
    ports.outb(0x3D5, @truncate(pos >> 8));
}

pub fn clearScreen() void {
    const vga: [*]volatile u16 = @ptrFromInt(VGA_BUFFER);
    for (0..VGA_WIDTH * VGA_HEIGHT) |i| {
        vga[i] = vgaEntry(' ', .light_grey, .black);
    }
    cursor_row = 0;
    cursor_col = 0;
}

pub fn writeCharAt(char: u8, row: usize, col: usize, fg: Color, bg: Color) void {
    const vga: [*]volatile u16 = @ptrFromInt(VGA_BUFFER);
    vga[(row * VGA_WIDTH) + col] = vgaEntry(char, fg, bg);
}

pub fn scrollUp() void {
    const vga: [*]volatile u16 = @ptrFromInt(VGA_BUFFER);
    const total = VGA_WIDTH * VGA_HEIGHT;

    for (VGA_WIDTH..total) |i| {
        vga[i - VGA_WIDTH] = vga[i];
    }

    for (total - VGA_WIDTH..total) |i| {
        vga[i] = vgaEntry(' ', .light_grey, .black);
    }
}

pub fn newLine() void {
    cursor_col = 0;
    cursor_row += 1;
    if (cursor_row >= VGA_HEIGHT) {
        scrollUp();
        cursor_row = VGA_HEIGHT - 1;
    }
}

pub fn moveCursor() void {
    cursor_col += 1;
    if (cursor_col >= VGA_WIDTH) {
        cursor_col = 0;
        cursor_row += 1;
        if (cursor_row >= VGA_HEIGHT) {
            scrollUp();
            cursor_row = VGA_HEIGHT - 1;
        }
    }
}

pub fn moveCursorBack() void {
    if (cursor_col == 0) {
        if (cursor_row == 0) return;
        cursor_col = VGA_WIDTH - 1;
        cursor_row -= 1;
    } else {
        cursor_col -= 1;
    }
}

pub fn printColored(msg: []const u8, fg: Color, bg: Color) void {
    for (msg) |byte| {
        if (byte == '\n') {
            newLine();
        } else {
            writeCharAt(byte, cursor_row, cursor_col, fg, bg);
            moveCursor();
        }
    }
    renderCursor();
}

pub fn removeLast() void {
    if (cursor_row == 0 and cursor_col == 0) return;
    moveCursorBack();
    const vga: [*]volatile u16 = @ptrFromInt(VGA_BUFFER);
    vga[cursor_row * VGA_WIDTH + cursor_col] = vgaEntry(' ', .light_grey, .black);
    renderCursor();
}

pub fn println(msg: []const u8) void {
    printColored(msg, .white, .black);
    if (msg.len == 0 or msg[msg.len - 1] != '\n') {
        newLine();
    }
    renderCursor();
}

pub fn println_color(msg: []const u8, fg: Color, bg: Color) void {
    printColored(msg, fg, bg);
    if (msg.len == 0 or msg[msg.len - 1] != '\n') {
        newLine();
    }
    renderCursor();
}

pub fn writeChar(char: u8) void {
    writeCharAt(char, cursor_row, cursor_col, .white, .black);
    moveCursor();
    renderCursor();
}

pub fn print(msg: []const u8) void {
    printColored(msg, .white, .black);
}
