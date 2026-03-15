const std = @import("std");
const Io = std.Io;

const types = @import("types.zig");

const ansi = struct {
    const reset = "\x1b[0m";
    const italic_blue = "\x1b[3;34m";
    const bold_purple = "\x1b[1;35m";
    const bg_blue = "\x1b[37;44m";
};

pub fn printEntry(w: *Io.Writer, entry: types.Entry) !void {
    try w.print(
        ansi.bg_blue ++ " {s} " ++ ansi.reset,
        .{entry.word},
    );

    if (entry.findPhonetic()) |phonetic| {
        try w.print(" - ", .{});

        try w.print(ansi.italic_blue ++ "{s}" ++ ansi.reset, .{phonetic});
    }

    try w.print("\n\n", .{});

    for (entry.meanings) |meaning| {
        try w.print(ansi.bold_purple ++ "{s}" ++ ansi.reset ++ "\n", .{meaning.partOfSpeech});

        for (meaning.definitions, 1..) |def, index| {
            try w.print(" {d}. {s}\n", .{
                index,
                def.definition,
            });
        }

        try w.print("\n", .{});
    }
}
