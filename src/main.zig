const std = @import("std");
pub const std_options: std.Options = .{ .page_size_max = 4096 };

const vga = @import("vga.zig");
const input = @import("input.zig");
const shell = @import("shell.zig");
const MULTIBOOT_MAGIC: u32 = 0x1BADB002;
const MULTIBOOT_FLAGS: u32 = 0x00;
const MULTIBOOT_CHECKSUM: u32 = @as(u32, 0) -% MULTIBOOT_MAGIC -% MULTIBOOT_FLAGS;

const MultibootHeader = extern struct {
    magic: u32 = MULTIBOOT_MAGIC,
    flags: u32 = MULTIBOOT_FLAGS,
    checksum: u32 = MULTIBOOT_CHECKSUM,
};

export const multiboot_header: MultibootHeader linksection(".multiboot") = .{};

const STACK_SIZE = 16 * 1024;
export var stack_bytes: [STACK_SIZE]u8 align(16) linksection(".bss") = undefined;

export fn _start() callconv(.naked) noreturn {
    asm volatile (
        \\.extern stack_bytes
        \\lea stack_bytes + 16384, %%esp
        \\jmp kmain
    );
}

export fn kmain() noreturn {
    vga.clearScreen();
    shell.addCommand("fetch", @import("fetch.zig"));
    shell.addCommand("hello", @import("hello.zig"));
    vga.println(shell.execCommand("fetch"));
    shell.returnShell(true);
    while (true) {
        shell.startShell();
    }
}

// kernel panic
pub const panic = std.debug.no_panic;
