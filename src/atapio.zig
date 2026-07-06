//This part is vibecoded btw
const std = @import("std");
const ports = @import("ports.zig");

const BASE = 0x1F0;
const DATA = BASE + 0;
const SECTOR_COUNT = BASE + 2;
const LBA_LOW = BASE + 3;
const LBA_MID = BASE + 4;
const LBA_HIGH = BASE + 5;
const DEVICE = BASE + 6;
const COMMAND = BASE + 7;
const STATUS = COMMAND;
const maxSectorsPerCmd = 255;
const sectorSize = 512;
const TIMEOUT = 1_000_000;
const BSY = 1 << 7;
const DRQ = 1 << 3;
const ERR = 1 << 0;
const CMD_READ_SECTORS = 0x20;
const CMD_WRITE_SECTORS = 0x30;
const CMD_FLUSH_CACHE = 0xE7;

fn makeDeviceValue(lba: u32) u8 {
    return 0xE0 | (@truncate(u8, lba >> 24) & 0x0F);
}

fn waitUntilReady() bool {
    var timeout = TIMEOUT;
    while (timeout > 0) : (timeout -= 1) {
        const status = ports.inb(STATUS);
        if ((status & BSY) == 0) {
            return (status & ERR) == 0;
        }
    }
    return false;
}

fn waitForDataRequest() bool {
    var timeout = TIMEOUT;
    while (timeout > 0) : (timeout -= 1) {
        const status = ports.inb(STATUS);
        if ((status & BSY) == 0) {
            if ((status & ERR) != 0) return false;
            if ((status & DRQ) != 0) return true;
        }
    }
    return false;
}

fn issueCommand(lba: u32, sectorCount: u8, command: u8) void {
    const dev_val = makeDeviceValue(lba);
    ports.outb(DEVICE, dev_val);
    ports.outb(SECTOR_COUNT, sectorCount);
    ports.outb(LBA_LOW, @truncate(u8, lba & 0xFF));
    ports.outb(LBA_MID, @truncate(u8, (lba >> 8) & 0xFF));
    ports.outb(LBA_HIGH, @truncate(u8, (lba >> 16) & 0xFF));
    ports.outb(COMMAND, command);
}

pub fn writeSectors(lba: u32, count: u8, buf: [*]const u8) bool {
    if (count == 0) return true;
    if (!waitUntilReady()) return false;
    issueCommand(lba, count, CMD_WRITE_SECTORS);
    var buf16 = @ptrCast([*]const u16, @alignCast(@alignOf(u16), buf));
    var remaining = count;
    while (remaining > 0) : (remaining -= 1) {
        if (!waitForDataRequest()) return false;
        for (0..256) |i| {
            ports.outw(DATA, buf16[i]);
        }
        buf16 += 256;
    }
    if (!waitUntilReady()) return false;
    return (ports.inb(STATUS) & ERR) == 0;
}

pub fn writeSector(lba: u32, buf: [*]const u8) bool {
    return writeSectors(lba, 1, buf);
}

pub fn writeSectorsRange(lbaStart: u32, lbaEnd: u32, buf: [*]const u8) bool {
    if (lbaEnd < lbaStart) return false;
    var currentLba = lbaStart;
    var remaining = lbaEnd - lbaStart + 1;
    var currentBuf = buf;
    while (remaining > 0) {
        const chunkCount = if (remaining > maxSectorsPerCmd)
            maxSectorsPerCmd
        else
            @as(u8, @intCast(remaining));

        if (!writeSectors(currentLba, chunkCount, currentBuf))
            return false;
        currentLba += chunkCount;
        currentBuf += chunkCount * sectorSize;
        remaining -= chunkCount;
    }

    return true;
}

pub fn flushCache() void {
    if (waitUntilReady()) {
        ports.outb(COMMAND, CMD_FLUSH_CACHE);
        _ = waitUntilReady();
    }
}

pub fn readSector(lba: u32, buf: [*]u8) bool {
    return readSectors(lba, 1, buf);
}

pub fn readSectors(lba: u32, count: u8, buf: [*]u8) bool {
    if (count == 0) return true;
    if (!waitUntilReady()) return false;
    issueCommand(lba, count, CMD_READ_SECTORS);
    var buf16 = @ptrCast([*]u16, @alignCast(@alignOf(u16), buf));
    var remaining = count;
    while (remaining > 0) : (remaining -= 1) {
        if (!waitForDataRequest()) return false;
        for (0..256) |i| {
            buf16[i] = ports.inw(DATA);
        }
        buf16 += 256;
    }

    const status = ports.inb(STATUS);
    return (status & ERR) == 0;
}

pub fn readSectorsRange(lbaStart: u32, lbaEnd: u32, buf: [*]u8) bool {
    if (lbaEnd < lbaStart) return false;

    var currentLba = lbaStart;
    var remaining = lbaEnd - lbaStart + 1;
    var currentBuf = buf;

    while (remaining > 0) {
        const chunkCount = if (remaining > maxSectorsPerCmd)
            maxSectorsPerCmd
        else
            @as(u8, @intCast(remaining));

        if (!readSectors(currentLba, chunkCount, currentBuf))
            return false;

        currentLba += chunkCount;
        currentBuf += chunkCount * sectorSize;
        remaining -= chunkCount;
    }

    return true;
}
