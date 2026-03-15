const std = @import("std");
const Io = std.Io;

const types = @import("types.zig");

const Error = error{ NotFound, BadResponse };

const base_url = "https://api.dictionaryapi.dev/api/v2/entries/en/";

pub fn fetch(
    allo: std.mem.Allocator,
    word: []const u8,
    client: *std.http.Client,
) !std.json.Parsed([]types.Entry) {
    const url = try std.mem.concat(
        allo,
        u8,
        &.{ base_url, word },
    );
    defer allo.free(url);

    var body: Io.Writer.Allocating = .init(allo);
    defer body.deinit();

    const response = try client.fetch(.{
        .method = .GET,
        .location = .{ .url = url },
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
