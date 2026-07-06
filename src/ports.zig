pub fn outb(port: u16, value: u8) void {
    asm volatile ("outb %[val], %[port]"
        :
        : [val] "{al}" (value),
          [port] "{dx}" (port),
        : .{ .memory = true });
}

pub fn inb(port: u16) u8 {
    var result: u8 = undefined;
    asm volatile ("inb %[port], %[val]"
        : [val] "={al}" (result),
        : [port] "{dx}" (port),
        : .{ .memory = true });
    return result;
}

pub fn outw(port: u16, value: u16) void {
    asm volatile ("outw %[val], %[port]"
        :
        : [val] "{ax}" (value),
          [port] "{dx}" (port),
        : .{ .memory = true });
}

pub fn inw(port: u16) u16 {
    var result: u16 = undefined;
    asm volatile ("inw %[port], %[val]"
        : [val] "={ax}" (result),
        : [port] "{dx}" (port),
        : .{ .memory = true });
    return result;
}
