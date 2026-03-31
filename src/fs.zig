const std = @import("std");

pub fn openDir(path: []const u8, files: *[1024][256]u8, file_count: *usize) !void {
    file_count.* = 0;
    var dir = std.fs.cwd().openDir(path, .{ .iterate = true }) catch return;
    defer dir.close();
    var it = dir.iterate();
    while (try it.next()) |entry| {
        if (file_count.* >= 1024) break;
        if (std.mem.eql(u8, entry.name, ".") or std.mem.eql(u8, entry.name, "..")) continue;
        const len = @min(entry.name.len, 255);
        @memset(files[file_count.*][0..256], 0);
        @memcpy(files[file_count.*][0..len], entry.name[0..len]);
        file_count.* += 1;
    }
}

pub fn searchFilesWriter(writer: anytype, files: []const [256]u8, filtered: []const usize, cursor: usize, scroll: usize) !void {
    const MAX_VISIBLE: usize = 20;
    const total = filtered.len;
    const visible_end = @min(scroll + MAX_VISIBLE, total);
    const visible = filtered[scroll..visible_end];

    try writer.writeAll("\r\n--- Resultados ---\r\n");

    for (visible, 0..) |file_idx, i| {
        const real_i = scroll + i;
        const name = std.mem.sliceTo(&files[file_idx], 0);
        const selected = real_i == cursor;

        var is_dir = false;
        const stat = std.fs.cwd().statFile(name) catch null;
        if (stat) |s| {
            if (s.kind == .directory) is_dir = true;
        }

        if (selected) {
            if (is_dir) {
                try writer.print("\x1b[47m\x1b[34m> {s}/\x1b[0m\r\n", .{name});
            } else {
                try writer.print("\x1b[47m\x1b[30m> {s}\x1b[0m\r\n", .{name});
            }
        } else {
            if (is_dir) {
                try writer.print("  \x1b[34m{s}/\x1b[0m\r\n", .{name});
            } else {
                try writer.print("  {s}\r\n", .{name});
            }
        }
    }

    // Indicador de mais arquivos abaixo
    if (visible_end < total) {
        const remaining = total - visible_end;
        try writer.print("\x1b[90m  ↓ {} arquivo(s) abaixo\x1b[0m\r\n", .{remaining});
    }

    // Indicador de mais arquivos acima
    if (scroll > 0) {
        // Já mostramos a seta acima no header, mas adicionamos aqui também como info
    }
}
