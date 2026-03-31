const std = @import("std");
const print = @import("utils/Print.zig").print;
const posix = std.posix;

var orig_termios: posix.termios = undefined;
var raw_enabled: bool = false;

fn die(msg: []const u8) noreturn {
    std.debug.print("{s}\r\n", .{msg});
    std.process.exit(1);
}

pub fn disableRawMode() void {
    if (raw_enabled) {
        posix.tcsetattr(posix.STDIN_FILENO, .NOW, orig_termios) catch {};
        raw_enabled = false;
    }
}

pub fn enableRawMode() !void {
    if (raw_enabled) return;

    orig_termios = posix.tcgetattr(posix.STDIN_FILENO) catch |err| {
        try print("tcgetattr falhou: {}\r\n", .{err});
        std.process.exit(1);
    };

    var raw = orig_termios;

    raw.iflag.BRKINT = false;
    raw.iflag.INPCK = false;
    raw.iflag.ISTRIP = false;
    raw.iflag.IXON = false;

    raw.oflag.OPOST = false;

    raw.cflag.CSIZE = .CS8;

    raw.lflag.ECHO = false;
    raw.lflag.ICANON = false;
    raw.lflag.IEXTEN = false;
    raw.lflag.ISIG = true;

    raw.cc[@intFromEnum(posix.V.MIN)] = 0;
    raw.cc[@intFromEnum(posix.V.TIME)] = 1;

    posix.tcsetattr(posix.STDIN_FILENO, .NOW, raw) catch die("tcsetattr falhou");

    raw_enabled = true;
}
