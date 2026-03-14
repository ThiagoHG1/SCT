const std = @import("std");
const print = @import("Utils.zig").print;
const posix = std.posix;

var orig_termios: posix.termios = undefined;

fn die(msg: []const u8) noreturn {
    std.debug.print("{s}\r\n", .{msg});
    std.process.exit(1);
}

pub fn disableRawMode() void {
    posix.tcsetattr(posix.STDIN_FILENO, .FLUSH, orig_termios) catch {};
}

fn enableRawMode() !void {
    orig_termios = posix.tcgetattr(posix.STDIN_FILENO) catch |err| {
        try print("tcgetattr falhou: {}\r\n", .{err});
        std.process.exit(1);
    };

    var raw = orig_termios;

    raw.iflag.BRKINT = false;
    raw.iflag.ICRNL = false;
    raw.iflag.INPCK = false;
    raw.iflag.ISTRIP = false;
    raw.iflag.IXON = false;

    raw.oflag.OPOST = false;

    raw.cflag.CSIZE = .CS8;

    raw.lflag.ECHO = false;
    raw.lflag.ICANON = false;
    raw.lflag.IEXTEN = false;
    raw.lflag.ISIG = false;

    raw.cc[@intFromEnum(posix.V.MIN)] = 0;
    raw.cc[@intFromEnum(posix.V.TIME)] = 1;

    posix.tcsetattr(posix.STDIN_FILENO, .FLUSH, raw) catch die("tcsetattr falhou");
}

fn openDir(path: []const u8, files: *[1024][256]u8, file_count: *usize) !void {
    file_count.* = 0;
    // Abre o diretório atual
    var dir = std.fs.cwd().openDir(path, .{ .iterate = true }) catch return;
    defer dir.close();

    var it = dir.iterate();
    while (try it.next()) |entry| {
        if (file_count.* >= 1024) break;
        
        // Ignora "." e ".." da listagem para não poluir o visual
        if (std.mem.eql(u8, entry.name, ".") or std.mem.eql(u8, entry.name, "..")) continue;

        const len = @min(entry.name.len, 255);
        @memset(files[file_count.*][0..256], 0);
        @memcpy(files[file_count.*][0..len], entry.name[0..len]);
        
        file_count.* += 1;
    }
}

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

fn searchFiles(files: []const [256]u8, query: []const u8) !void {
    try print("\r\n--- Resultados ---\r\n", .{});

    for (files) |*f| {
        const name = std.mem.span(@as([*:0]const u8, @ptrCast(f)));
        if (isMatch(name, query)) {
            var is_dir = false;
            
            const stat = std.fs.cwd().statFile(name) catch null;
            if (stat) |s| {
                if (s.kind == .directory) is_dir = true;
            }

            if (is_dir) {
                try print("\x1b[34m{s}/\x1b[0m\r\n", .{name}); 
            } else {
                try print("{s}\r\n", .{name});
            }
        }
    }
}

pub fn Search(cmd_prefix: ?[]const u8, allocator: std.mem.Allocator) !void {
    try enableRawMode();
    defer disableRawMode();

    var files: [1024][256]u8 = undefined;
    var file_count: usize = 0;
    var query: [1024]u8 = undefined;
    var query_len: usize = 0;

    // Buffer para armazenar o caminho atual (CWD)
    var cwd_buf: [1024]u8 = undefined;

    try openDir(".", &files, &file_count);

    while (true) {
        // Limpa a tela e mostra o cabeçalho
        const current_path = std.fs.cwd().realpath(".", &cwd_buf) catch "---";
        try print("\x1b[2J\x1b[H", .{}); // Limpa tudo e volta pro topo (0,0)
        try print("\x1b[32mDiretório: {s}\x1b[0m\r\n", .{current_path});
        try print("\x1b[1mBusca: {s}\x1b[0m", .{query[0..query_len]});
        
        // Renderiza os arquivos filtrados
        try searchFiles(files[0..file_count], query[0..query_len]);

        // Lê o input do usuário
        var buf: [1]u8 = undefined;
        const bytes_lidos = posix.read(posix.STDIN_FILENO, &buf) catch continue;
        if (bytes_lidos == 0) continue;

        const key = buf[0];

        if (key == 13 or key == 10) { // ENTER
            var selected_file: ?[]const u8 = null;
            for (files[0..file_count]) |*f| {
                const name = std.mem.span(@as([*:0]const u8, @ptrCast(f)));
                if (isMatch(name, query[0..query_len])) {
                    selected_file = name;
                    break;
                }
            }

            if (selected_file) |path| {
                const stat = std.fs.cwd().statFile(path) catch null;
                if (stat != null and stat.?.kind == .directory) {
                    // Entra na pasta
                    std.posix.chdir(path) catch continue;
                    try openDir(".", &files, &file_count);
                    query_len = 0; // Reseta a busca ao navegar
                } else {
                    // Executa comando no arquivo
                    disableRawMode();
                    if (cmd_prefix) |cmd| {
                        var child = std.process.Child.init(&[_][]const u8{ cmd, path }, allocator);
                        _ = child.spawnAndWait() catch {
                            try enableRawMode();
                            continue;
                        };
                    } else {
                        std.debug.print("\r\nArquivo selecionado: {s}\r\n", .{path});
                    }
                    return; 
                }
            }
        } else if (key == 27) { // ESC - VOLTAR PASTA
            std.posix.chdir("..") catch continue;
            try openDir(".", &files, &file_count);
            query_len = 0;
        } else if (key == 127) { // BACKSPACE
            if (query_len > 0) {
                query_len -= 1;
            } 
        } else if (key >= 32 and key <= 126) { // CARACTERES DIGITÁVEIS
            addChar(&query, &query_len, key);
        } else if (key == 3) { // CTRL+C
            disableRawMode();
            break;
        }
    }
}
