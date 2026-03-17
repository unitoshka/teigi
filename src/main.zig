const std = @import("std");
const Io = std.Io;

const types = @import("types.zig");
const render = @import("render.zig");
const api = @import("api.zig");

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
        try render.printUsage(stdout);

        std.process.exit(1);
    }

    var w: ?[]const u8 = null;

    var i: usize = 1;

    while (i < args.len) : (i += 1) {
        const arg = args[i];

        if (std.mem.startsWith(u8, arg, "-")) {
            if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
                try render.printUsage(stdout);

                std.process.exit(0);
            }

            try stderr.print("Unknown flag: {s}\n", .{arg});
        } else {
            w = arg;
        }
    }

    const word = w orelse {
        try render.printUsage(stdout);

        std.process.exit(1);
    };

    var client = std.http.Client{ .allocator = allo, .io = init.io };
    defer client.deinit();

    const parsed = api.fetch(allo, word, &client) catch |err| switch (err) {
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
}
