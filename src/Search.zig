const std = @import("std");
const p = @import("utils/Print.zig");
const terminal = @import("terminal.zig");
const fs = @import("fs.zig");
const posix = std.posix;

const MAX_VISIBLE: usize = 20;

fn addChar(query: *[1024]u8, query_len: *usize, key: u8) void {
    if (query_len.* >= query.len) return;
    query[query_len.*] = key;
    query_len.* += 1;
}

fn isMatch(name: []const u8, query: []const u8) bool {
    if (query.len == 0) return true;
    var q_idx: usize = 0;
    var n_idx: usize = 0;
    while (q_idx < query.len and n_idx < name.len) {
        if (std.ascii.toLower(query[q_idx]) == std.ascii.toLower(name[n_idx])) {
            q_idx += 1;
        }
        n_idx += 1;
    }
    return q_idx == query.len;
}

// Estado de render anterior para saber se precisa redesenhar tudo
const RenderState = struct {
    query_len: usize,
    cursor: usize,
    scroll: usize,
    file_count: usize,
    path_hash: u64,
};

fn hashPath(path: []const u8) u64 {
    var h: u64 = 14695981039346656037;
    for (path) |b| {
        h ^= b;
        h *%= 1099511628211;
    }
    return h;
}

pub fn Search(cmd_prefix: ?[]const u8, allocator: std.mem.Allocator) !void {
    try terminal.enableRawMode();
    defer terminal.disableRawMode();

    var files: [1024][256]u8 = undefined;
    var file_count: usize = 0;
    var query: [1024]u8 = undefined;
    var query_len: usize = 0;
    var cursor: usize = 0;
    var scroll: usize = 0;
    var cwd_buf: [1024]u8 = undefined;

    try fs.openDir(".", &files, &file_count);

    // Estado anterior — usado para detectar se precisamos full redraw
    var last_state: ?RenderState = null;
    var full_redraw = true; // primeiro frame sempre full

    // Buffer de render
    var render_buf: std.ArrayList(u8) = .empty;
    defer render_buf.deinit(allocator);

    // Esconde cursor durante render
    try p.print("\x1b[?25l", .{});
    defer p.print("\x1b[?25h", .{}) catch {};

    while (true) {
        const current_path = std.fs.cwd().realpath(".", &cwd_buf) catch "---";
        const path_hash = hashPath(current_path);

        // Monta lista filtrada
        var filtered: [1024]usize = undefined;
        var filtered_count: usize = 0;
        for (files[0..file_count], 0..) |*f, i| {
            const name = std.mem.sliceTo(f, 0);
            if (isMatch(name, query[0..query_len])) {
                filtered[filtered_count] = i;
                filtered_count += 1;
            }
        }

        // Ajusta cursor e scroll
        if (filtered_count == 0) {
            cursor = 0;
            scroll = 0;
        } else {
            if (cursor >= filtered_count) cursor = filtered_count - 1;
            // Scroll segue o cursor
            if (cursor < scroll) scroll = cursor;
            if (cursor >= scroll + MAX_VISIBLE) scroll = cursor - MAX_VISIBLE + 1;
        }

        // Detecta se algo mudou
        const cur_state = RenderState{
            .query_len = query_len,
            .cursor = cursor,
            .scroll = scroll,
            .file_count = file_count,
            .path_hash = path_hash,
        };

        const needs_full = full_redraw or last_state == null or
            last_state.?.path_hash != cur_state.path_hash or
            last_state.?.file_count != cur_state.file_count or
            last_state.?.query_len != cur_state.query_len;

        const needs_scroll_only = !needs_full and (last_state.?.cursor != cur_state.cursor or
            last_state.?.scroll != cur_state.scroll);

        render_buf.clearRetainingCapacity();
        const w = render_buf.writer(allocator);

        if (needs_full) {
            // Redesenho completo: limpa tela, header, lista
            try w.writeAll("\x1b[H\x1b[J");

            // Indicador de scroll acima
            if (scroll > 0) {
                try w.print("\x1b[90m  ↑ {} arquivo(s) acima\x1b[0m\r\n", .{scroll});
            } else {
                try w.print("\x1b[32mDiretório: {s}\x1b[0m\r\n", .{current_path});
            }

            if (scroll == 0) {
                try w.print("\x1b[1mBusca: {s}\x1b[0m\r\n", .{query[0..query_len]});
                try w.writeAll("---\r\n");
            }

            try fs.searchFilesWriter(w, files[0..file_count], filtered[0..filtered_count], cursor, scroll);
        } else if (needs_scroll_only) {
            // Só o scroll mudou: vai para a linha da lista e redesenha só ela
            // Header fica intacto — move cursor para linha 4 (após dir, busca, ---)
            const header_lines: usize = if (scroll > 0) 1 else 3;
            try w.print("\x1b[{}H\x1b[J", .{header_lines + 1});
            try fs.searchFilesWriter(w, files[0..file_count], filtered[0..filtered_count], cursor, scroll);
        }
        // Se nada mudou, render_buf fica vazio — zero escrita

        if (render_buf.items.len > 0) {
            try p.print("{s}", .{render_buf.items});
            try p.flush();
        }

        last_state = cur_state;
        full_redraw = false;

        // Lê input
        var buf: [1]u8 = undefined;
        const bytes_lidos = posix.read(posix.STDIN_FILENO, &buf) catch continue;
        if (bytes_lidos == 0) continue;

        const key = buf[0];

        if (key == 13 or key == 10) {
            if (filtered_count == 0) continue;
            const name = std.mem.sliceTo(&files[filtered[cursor]], 0);
            const stat = std.fs.cwd().statFile(name) catch null;
            if (stat != null and stat.?.kind == .directory) {
                std.posix.chdir(std.mem.sliceTo(&files[filtered[cursor]], 0)) catch continue;
                try fs.openDir(".", &files, &file_count);
                query_len = 0;
                cursor = 0;
                scroll = 0;
                full_redraw = true;
            } else {
                terminal.disableRawMode();
                if (cmd_prefix) |cmd| {
                    var child = std.process.Child.init(
                        &[_][]const u8{ cmd, std.mem.sliceTo(&files[filtered[cursor]], 0) },
                        allocator,
                    );
                    _ = child.spawnAndWait() catch {
                        try terminal.enableRawMode();
                        full_redraw = true;
                        continue;
                    };
                }
                return;
            }
        } else if (key == 127) {
            if (query_len > 0) {
                query_len -= 1;
                cursor = 0;
                scroll = 0;
            }
        } else if (key >= 32 and key <= 126) {
            addChar(&query, &query_len, key);
            cursor = 0;
            scroll = 0;
        }

        if (key == 27) {
            var seq: [2]u8 = undefined;
            const n = posix.read(posix.STDIN_FILENO, &seq) catch 0;
            if (n == 2 and seq[0] == 91) {
                switch (seq[1]) {
                    65 => {
                        if (cursor > 0) cursor -= 1;
                    },
                    66 => {
                        if (cursor + 1 < filtered_count) cursor += 1;
                    },
                    else => {},
                }
            } else {
                std.posix.chdir("..") catch continue;
                try fs.openDir(".", &files, &file_count);
                query_len = 0;
                cursor = 0;
                scroll = 0;
                full_redraw = true;
            }
        }
    }
}
