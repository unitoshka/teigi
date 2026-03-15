const std = @import("std");
const Io = std.Io;

const types = @import("types.zig");
const render = @import("render.zig");
const api = @import("api.zig");

fn italic(writer: *Io.Writer, text: []u8) !void {
    try writer.print("\x1b[3;34m{s}\x1b[0m", .{text});
}

pub fn main(init: std.process.Init) !void {
    const allo = std.heap.smp_allocator;

    var stdout_buf: [2048]u8 = undefined;
    var stderr_buf: [512]u8 = undefined;

    var stdout_fw: Io.File.Writer = .init(.stdout(), init.io, &stdout_buf);
    var stderr_fw: Io.File.Writer = .init(.stderr(), init.io, &stderr_buf);

    const stdout = &stdout_fw.interface;
    const stderr = &stderr_fw.interface;

    const args = try init.minimal.args.toSlice(allo);

    if (args.len < 2) {
        try stderr.print("Usage: {s} <word>\n", .{args[0]});
        try stderr.flush();

        std.process.exit(1);
    }

    const word = args[1];

    const parsed = api.fetch(allo, init.io, word) catch |err| switch (err) {
        error.NotFound => {
            try stderr.print("Word \"{s}\" not found\n", .{word});
            try stderr.flush();

            std.process.exit(1);
        },
        error.BadResponse => {
            try stderr.print("API Error\n", .{});
            try stderr.flush();

            std.process.exit(1);
        },
        else => return err,
    };

    defer parsed.deinit();

    if (parsed.value.len == 0) {
        try stderr.print("No entries for \"{s}\"\n", .{word});
        try stderr.flush();
        std.process.exit(1);
    }

    try render.printEntry(stdout, parsed.value[0]);
    try stdout.flush();
}
