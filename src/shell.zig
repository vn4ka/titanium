const vga = @import("vga.zig");
const inp = @import("input.zig");
const std = @import("std");
const sep = " ";

var cmd: std.StringHashMap = undefined;
pub fn addCommand(name: []const u8, module: type) void {
    try cmd.put(name, module.exec);
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

pub fn isValid(name: []const u8) bool {
    if (cmd.get(name)) |_| {
        return true;
    } else {
        return false;
    }
}

pub fn split(command: []const u8) struct { []const u8, []const u8 } {
    if (std.mem.indexOfScalar(u8, command, sep)) |index| {
        return .{ command[0..index], command[index + 1 ..] };
    } else {
        return .{ command, "" };
    }
}

pub fn execCommand(cmdstring: []const u8) []const u8 {
    const name, const args = split(cmdstring);
    if (isValid(name)) {
        return cmd.get(name)(args);
    } else {
        return "titanium: command not found.";
    }
}
