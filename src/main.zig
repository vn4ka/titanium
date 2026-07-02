const std = @import("std");
const vga = @import("vga.zig");
const input = @import("input.zig");
const MULTIBOOT_MAGIC: u32 = 0x1BADB002;
const MULTIBOOT_FLAGS: u32 = 0x00;
const MULTIBOOT_CHECKSUM: u32 = @as(u32, 0) -% MULTIBOOT_MAGIC -% MULTIBOOT_FLAGS;
const logo =
    \\ ______    __                                               
    \\/\__  _\__/\ \__                  __                        
    \\\/_/\ \/\_\ \ ,_\    __      ___ /\_\  __  __    ___ ___    
    \\   \ \ \/\ \ \ \/  /'__`\  /' _ `\/\ \/\ \/\ \ /' __` __`\  
    \\    \ \ \ \ \ \ \_/\ \L\.\_/\ \/\ \ \ \ \ \_\ \/\ \/\ \/\ \ 
    \\     \ \_\ \_\ \__\ \__/.\_\ \_\ \_\ \_\ \____/\ \_\ \_\ \_\
    \\      \/_/\/_/\/__/\/__/\/_/\/_/\/_/\/_/\/___/  \/_/\/_/\/_/
;

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
    vga.println("========================");
    vga.println("WELCOME TO THE TITANIUM!");
    vga.println("========================");
    vga.println("\n\n\n");
    vga.println(logo);
    vga.println("\n\n\n");
    vga.println("so now you can write hello and the kernel will answer hello to you!");
    while (true) {
        if (std.mem.eql(u8, input.input(), "hello")) {
            vga.println("Hello from titanium!");
        }
    }
    while (true) {
        asm volatile ("hlt");
    }
}

// kernel panic
pub const panic = std.debug.no_panic;
