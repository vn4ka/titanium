const vga = @import("vga.zig");
const inp = @import("input.zig");
const std = @import("std");

const CmdFn = *const fn ([]const u8) []const u8;
var cmd = std.StringHashMap(CmdFn).init(std.heap.page_allocator);

pub fn addCommand(name: []const u8, module: type) void {
    _ = cmd.put(name, module.exec);
}

pub fn returnShell(ok: bool) void {
    vga.newLine();
    if (ok) {
        vga.printColored("$>", .green, .black);
    } else {
        vga.printColored("X", .red, .black);
        vga.printColored(">", .green, .black);
    }
}

//pub fn isValid(name: []const u8) bool {
//    if (cmd.get(name)) |_| {
//        return true;
//    } else {
//        return false;
//    }
//}

pub fn split(command: []const u8) struct { []const u8, []const u8 } {
    if (std.mem.indexOfScalar(u8, command, ' ')) |index| {
        return .{ command[0..index], command[index + 1 ..] };
    } else {
        return .{ command, "" };
    }
}

pub fn execCommand(cmdstring: []const u8) []const u8 {
    const name, const args = split(cmdstring);
    if (cmd.get(name)) |fn_ptr| {
        return fn_ptr(args);
    } else {
        return "titanium: command not found.";
    }
}

pub fn startShell() void {
    const commandstr = inp.input();
    vga.print("Kernel output: ");
    if (std.mem.eql(u8, execCommand(commandstr), "titanium: command not found.")) {
        vga.println_color(execCommand(commandstr), .red, .black);
        returnShell(false);
    } else {
        vga.println_color(execCommand(commandstr), .light_blue, .black);
        returnShell(true);
    }
}
