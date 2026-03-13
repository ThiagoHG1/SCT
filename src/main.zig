const std = @import("std");
const Search = @import("Search.zig").Search;
const disableRawMode = @import("Search.zig").disableRawMode;

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    defer disableRawMode();

    if (args.len < 2) {
        try Search(null, allocator);
        return;
    }

    const command = args[1];

    try Search(command, allocator);
}

