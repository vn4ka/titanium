const vga = @import("vga.zig");
const inp = @import("input.zig");
const std = @import("std");

const Command = struct {
    name: []const u8,
    func: *const fn (args: []const u8) []const u8,
};

const MAX_COMMANDS = 64;
var cmd: [MAX_COMMANDS]Command = undefined;
var cmdcnt: u8 = 0;

pub fn addCommand(name: []const u8, module: type) void {
    if (cmdcnt >= MAX_COMMANDS) {
        vga.print("command limit reached, ignoring '");
        vga.print(name);
        vga.print("'\n");
        return;
    }
    cmd[cmdcnt] = .{ .name = name, .func = module.exec };
    cmdcnt += 1;
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

pub fn getcmd(name: []const u8) ?*const fn (args: []const u8) []const u8 {
    for (cmd) |command| {
        if (std.mem.eql(u8, command.name, name)) {
            return command.func;
        }
    }
    return null;
}

pub fn execCommand(cmdstring: []const u8) []const u8 {
    const name, const args = split(cmdstring);
    if (getcmd(name)) |fnPtr| {
        return fnPtr(args);
    } else {
        return "titanium: command not found.";
    }
}

pub fn startShell() void {
    const commandstr = inp.input();
    vga.print("Kernel output:\n\n");
    if (std.mem.eql(u8, execCommand(commandstr), "titanium: command not found.")) {
        vga.println_color(execCommand(commandstr), .red, .black);
        returnShell(false);
    } else {
        vga.println_color(execCommand(commandstr), .light_blue, .black);
        returnShell(true);
    }
}
