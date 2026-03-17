const std = @import("std");
const Io = std.Io;

const types = @import("types.zig");

const ansi = struct {
    const reset = "\x1b[0m";
    const word = "\x1b[1;97;44m";
    const phonetic = "\x1b[3;34m";
    const pos = "\x1b[1;35m";
    const index = "\x1b[2;37m";
    const example = "\x1b[3;2;37m";
};

const Flags = struct {
    examples: bool,
};

fn printPhonetic(w: *Io.Writer, entry: types.Entry) !void {
    if (entry.findPhonetic()) |phonetic| {
        try w.print(" - " ++ ansi.phonetic ++ "{s}" ++ ansi.reset, .{phonetic});
    }
}

fn printMeaning(
    w: *Io.Writer,
    meaning: types.Meaning,
    flags: Flags,
) !void {
    try w.print(ansi.pos ++ "{s}" ++ ansi.reset ++ "\n", .{meaning.partOfSpeech});

    for (meaning.definitions, 1..) |def, index| {
        try w.print(ansi.index ++ " {d}. " ++ ansi.reset ++ "{s}\n", .{
            index,
            def.definition,
        });

        if (flags.examples) {
            if (def.example) |example| {
                try w.print(ansi.example ++ "  \"{s}\"\n" ++ ansi.reset, .{example});
            }
        }
    }

    try w.print("\n", .{});
}

pub fn printEntry(
    w: *Io.Writer,
    entry: types.Entry,
    flags: Flags,
) !void {
    try w.print(ansi.word ++ " {s} " ++ ansi.reset, .{entry.word});

    try printPhonetic(w, entry);

    try w.print("\n\n", .{});

    for (entry.meanings) |meaning| {
        try printMeaning(w, meaning, flags);
    }

    try w.flush();
}

pub fn printUsage(w: *Io.Writer) !void {
    try w.writeAll(
        \\teigi — dictionary navigator
        \\
        \\Usage:
        \\  teigi <word> [options]
        \\
        \\Options:
        \\  -h, --help       Print this help
        \\  -e, --examples   Examples of the use of the word
        \\
        \\Examples:
        \\  teigi search
        \\  teigi -e search
    );

    try w.flush();
}
