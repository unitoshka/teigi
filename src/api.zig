const std = @import("std");
const Io = std.Io;

const types = @import("types.zig");

const Error = error{ NotFound, BadResponse };

pub fn fetch(
    allo: std.mem.Allocator,
    io: Io,
    word: []const u8,
) !std.json.Parsed([]types.Entry) {
    var client = std.http.Client{ .allocator = allo, .io = io };

    defer client.deinit();

    const url = try std.mem.concat(
        allo,
        u8,
        &.{ "https://api.dictionaryapi.dev/api/v2/entries/en/", word },
    );

    defer allo.free(url);

    const uri = try std.Uri.parse(url);

    var body = Io.Writer.Allocating.init(allo);

    defer body.deinit();

    const response = try client.fetch(.{
        .method = .GET,
        .location = .{ .uri = uri },
        .headers = .{
            .accept_encoding = .{ .override = "application/json" },
        },
        .response_writer = &body.writer,
    });

    switch (response.status) {
        .ok => {},
        .not_found => return Error.NotFound,
        else => return Error.BadResponse,
    }

    return std.json.parseFromSlice(
        []types.Entry,
        allo,
        body.written(),
        .{ .ignore_unknown_fields = true },
    );
}
