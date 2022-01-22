const std = @import("std");
const testing = std.testing;

pub const types = @import("types.zig");
const Object = types.Object;
const id = types.id;
const Class = types.Class;
const SEL = types.SEL;

/// https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html
const TypeEncodingToken = enum(u8) {
    char = 'c',
    int = 'i',
    short = 's',
    long = 'l', // treated as a 32-bit quantity on 64-bit programs
    long_long = 'q',
    unsigned_char = 'C',
    unsigned_int = 'I',
    unsigned_short = 'S',
    unsigned_long = 'L',
    unsigned_long_long = 'Q',
    float = 'f',
    double = 'd',
    bool = 'B', // A C++ bool or a C99 _Bool
    void = 'v',
    char_string = '*', // A character string (char *)
    object = '@', // An object (whether statically typed or typed id)
    class = '#', // A class object (Class)
    selector = ':', // A method selector (SEL)
    array_begin = '[',
    array_end = ']',
    struct_begin = '{',
    struct_end = '}',
    union_begin = '(',
    union_end = ')',
    pair_separator = '=', // Used to separate name-types pairs in structures and unions
    bitfield = 'b', // Precedes a number representing the size of the bitfield
    pointer = '^', // Precedes a typecode to represent a pointer to type
    unknown = '?', // An unknown type (among other things, this code is used for function pointers)
};

pub fn writeEncodingForType(comptime T: type, writer: anytype) !void {
    var levels_of_indirection: u32 = 0;
    return writeEncodingForTypeInternal(T, &levels_of_indirection, writer);
}

fn writeEncodingForTypeInternal(comptime T: type, levels_of_indirection: *u32, writer: anytype) !void {
    switch (T) {
        i8 => try writer.writeByte(@enumToInt(TypeEncodingToken.char)),
        c_int => try writer.writeByte(@enumToInt(TypeEncodingToken.int)),
        c_short => try writer.writeByte(@enumToInt(TypeEncodingToken.short)),
        c_long => try writer.writeByte(@enumToInt(TypeEncodingToken.long)),
        c_longlong => try writer.writeByte(@enumToInt(TypeEncodingToken.long_long)),
        u8 => try writer.writeByte(@enumToInt(TypeEncodingToken.unsigned_char)),
        c_uint => try writer.writeByte(@enumToInt(TypeEncodingToken.unsigned_int)),
        c_ushort => try writer.writeByte(@enumToInt(TypeEncodingToken.unsigned_short)),
        c_ulong => try writer.writeByte(@enumToInt(TypeEncodingToken.unsigned_long)),
        c_ulonglong => try writer.writeByte(@enumToInt(TypeEncodingToken.unsigned_long_long)),
        f32 => try writer.writeByte(@enumToInt(TypeEncodingToken.float)),
        f64 => try writer.writeByte(@enumToInt(TypeEncodingToken.double)),
        bool => try writer.writeByte(@enumToInt(TypeEncodingToken.bool)),
        void => try writer.writeByte(@enumToInt(TypeEncodingToken.void)),
        [*c]u8, [*c]const u8 => try writer.writeByte(@enumToInt(TypeEncodingToken.char_string)),
        id => try writer.writeByte(@enumToInt(TypeEncodingToken.object)),
        Class => try writer.writeByte(@enumToInt(TypeEncodingToken.class)),
        SEL => try writer.writeByte(@enumToInt(TypeEncodingToken.selector)),
        Object => {
            try writer.writeByte(@enumToInt(TypeEncodingToken.struct_begin));
            try writer.writeAll(@typeName(T));
            try writer.writeByte(@enumToInt(TypeEncodingToken.pair_separator));
            try writer.writeByte(@enumToInt(TypeEncodingToken.class));
            try writer.writeByte(@enumToInt(TypeEncodingToken.struct_end));
        },
        else => switch (@typeInfo(T)) {
            .Fn => |_| try writer.writeByte(@enumToInt(TypeEncodingToken.unknown)),
            .Array => |arr_info| {
                try writer.writeByte(@enumToInt(TypeEncodingToken.array_begin));
                try writer.print("{d}", .{arr_info.len});
                try writeEncodingForTypeInternal(arr_info.child, levels_of_indirection, writer);
                try writer.writeByte(@enumToInt(TypeEncodingToken.array_end));
            },
            .Struct => |struct_info| {
                try writer.writeByte(@enumToInt(TypeEncodingToken.struct_begin));
                try writer.writeAll(@typeName(T));
                if (levels_of_indirection.* < 2) {
                    try writer.writeByte(@enumToInt(TypeEncodingToken.pair_separator));
                    inline for (struct_info.fields) |field| try writeEncodingForTypeInternal(field.field_type, levels_of_indirection, writer);
                }
                try writer.writeByte(@enumToInt(TypeEncodingToken.struct_end));
            },
            .Union => |union_info| {
                try writer.writeByte(@enumToInt(TypeEncodingToken.union_begin));
                try writer.writeAll(@typeName(T));
                if (levels_of_indirection.* < 2) {
                    try writer.writeByte(@enumToInt(TypeEncodingToken.pair_separator));
                    inline for (union_info.fields) |field| try writeEncodingForTypeInternal(field.field_type, levels_of_indirection, writer);
                }
                try writer.writeByte(@enumToInt(TypeEncodingToken.union_end));
            },
            .Pointer => |ptr_info| switch (ptr_info.size) {
                .One => {
                    levels_of_indirection.* += 1;
                    try writer.writeByte(@enumToInt(TypeEncodingToken.pointer));
                    try writeEncodingForTypeInternal(ptr_info.child, levels_of_indirection, writer);
                },
                else => @compileError("Unsupported type"),
            },
            else => @compileError("Unsupported type"),
        },
    }
}

test "write encoding for array" {
    var buffer: [0x100]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&buffer);

    try writeEncodingForType([12]*f32, fbs.writer());
    try testing.expectEqualSlices(u8, "[12^f]", fbs.getWritten());
}

test "write encoding for struct, pointer to struct and pointer to pointer to struct" {
    const Example = struct {
        anObject: id,
        aString: [*c]u8,
        anInt: c_int,
    };

    var buffer: [0x100]u8 = undefined;

    {
        var fbs = std.io.fixedBufferStream(&buffer);
        try writeEncodingForType(Example, fbs.writer());
        try testing.expectEqualSlices(u8, "{Example=@*i}", fbs.getWritten());
    }

    {
        var fbs = std.io.fixedBufferStream(&buffer);
        try writeEncodingForType(*Example, fbs.writer());
        try testing.expectEqualSlices(u8, "^{Example=@*i}", fbs.getWritten());
    }

    {
        var fbs = std.io.fixedBufferStream(&buffer);
        try writeEncodingForType(**Example, fbs.writer());
        const res = fbs.getWritten();
        std.debug.print("{s}\n", .{res});
        try testing.expectEqualSlices(u8, "^^{Example}", res);
    }
}

// TODO(hazeycode): more tests
