const std = @import("std");

var stdout_buffer: [65536]u8 = undefined;
var stdout_file_writer = std.fs.File.stdout().writer(&stdout_buffer);
const stdout = &stdout_file_writer.interface;

pub fn print(comptime fmt: []const u8, args: anytype) !void {
    try stdout.print(fmt, args);
}

pub fn flush() !void {
    try stdout.flush();
}
