// Zig wrapper for objc runtime. Rather unsafe, use will caution

const std = @import("std");

const c = @cImport({
    @cInclude("objc/message.h");
});

pub const id = c.id;
pub const Class = c.Class;
pub const SEL = c.SEL;

pub fn lookupClass(class_name: [:0]const u8) !Class {
    return c.objc_lookUpClass(class_name) orelse error.NotFound;
}

pub fn getClass(class_name: [:0]const u8) !Class {
    return c.objc_getClass(class_name) orelse error.NotFound;
}

pub fn getMetaClass(class_name: [:0]const u8) !Class {
    return c.objc_getMetaClass(class_name) orelse error.NotFound;
}

pub fn getInstanceVariable(comptime T: type, obj: id, name: [:0]const u8) !T {
    var res: T = undefined;
    if (c.object_getInstanceVariable(obj, name, @ptrCast([*c]?*anyopaque, &res))) |_| {} else return error.NotFound;
    return res;
}

pub fn allocAndInit(class: Class) id {
    return msgSend(msgSend(class, "alloc", .{}, Class), "init", .{}, id);
}

pub fn msgSend(obj: anytype, sel_name: [:0]const u8, args: anytype, comptime ReturnType: type) ReturnType {
    const args_meta = @typeInfo(@TypeOf(args)).Struct.fields;

    const FnType = blk: {
        {
            // NOTE(hazeycode): The following commented out code crashes the compiler :( last tested with Zig 0.9.0
            // https://github.com/ziglang/zig/issues/9526
            // comptime var fn_args: [2 + args_meta.len]std.builtin.TypeInfo.FnArg = undefined;
            // fn_args[0] = .{
            //     .is_generic = false,
            //     .is_noalias = false,
            //     .arg_type = @TypeOf(obj),
            // };
            // fn_args[1] = .{
            //     .is_generic = false,
            //     .is_noalias = false,
            //     .arg_type = SEL,
            // };
            // inline for (args_meta) |a, i| {
            //     fn_args[2 + i] = .{
            //         .is_generic = false,
            //         .is_noalias = false,
            //         .arg_type = a.field_type,
            //     };
            // }
            // break :blk @Type(.{ .Fn = .{
            //     .calling_convention = .C,
            //     .alignment = 0,
            //     .is_generic = false,
            //     .is_var_args = false,
            //     .return_type = ReturnType,
            //     .args = &fn_args,
            // } });
        }
        {
            // TODO(hazeycode): replace this hack with the more generalised code above once it doens't crash the compiler
            break :blk switch (args_meta.len) {
                0 => fn (@TypeOf(obj), SEL) callconv(.C) ReturnType,
                1 => fn (@TypeOf(obj), SEL, args_meta[0].field_type) callconv(.C) ReturnType,
                2 => fn (@TypeOf(obj), SEL, args_meta[0].field_type, args_meta[1].field_type) callconv(.C) ReturnType,
                3 => fn (@TypeOf(obj), SEL, args_meta[0].field_type, args_meta[1].field_type, args_meta[2].field_type) callconv(.C) ReturnType,
                4 => fn (@TypeOf(obj), SEL, args_meta[0].field_type, args_meta[1].field_type, args_meta[2].field_type, args_meta[3].field_type) callconv(.C) ReturnType,
                else => @compileError("Unsupported number of args"),
            };
        }
    };

    // NOTE: func is a var because making it const causes a compile error which I believe is a compiler bug
    var func = @ptrCast(FnType, c.objc_msgSend);
    const sel = c.sel_getUid(sel_name);

    return @call(.{}, func, .{ obj, sel } ++ args);
}

pub fn allocateClassPair(superclass: Class, class_name: [:0]const u8) !Class {
    return c.objc_allocateClassPair(superclass, class_name, 0) orelse error.FailedToAllocateClassPair;
}

pub fn registerClass(class: Class) void {
    c.objc_registerClassPair(class);
}

test {
    std.testing.refAllDecls(@This());
}
