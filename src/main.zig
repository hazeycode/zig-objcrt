//! This is the top level module that exposes type-safe Objective-C runtime bindings and convenient wrappers

const std = @import("std");
const testing = std.testing;

const objc = @import("objc.zig");
pub const object = objc.object;
pub const Class = objc.Class;
pub const id = objc.id;
pub const SEL = objc.SEL;
pub const IMP = objc.IMP;
pub const sel_registerName = objc.sel_registerName;
pub const sel_getUid = objc.sel_getUid;

const runtime = @import("runtime.zig");
pub const Method = runtime.Method;
pub const Ivar = runtime.Ivar;
pub const Category = runtime.Category;
pub const Property = runtime.Property;
pub const object_getClass = runtime.object_getClass;
pub const getClass = runtime.getClass;
pub const getMetaClass = runtime.getMetaClass;
pub const lookUpClass = runtime.lookUpClass;
pub const allocateClassPair = runtime.allocateClassPair;
pub const registerClassPair = runtime.registerClassPair;
pub const disposeClassPair = runtime.disposeClassPair;
pub const class_addMethod = runtime.class_addMethod;
pub const class_replaceMethod = runtime.class_replaceMethod;
pub const class_addIvar = runtime.class_addIvar;
pub const method_setImplementation = runtime.method_setImplementation;

const message = @import("message.zig");
pub const msgSend = message.msgSend;

const type_encoding = @import("type-encoding.zig");
const writeEncodingForType = type_encoding.writeEncodingForType;

pub const Error = error{
    FailedToAddIvarToClass,
};

/// The same as calling msgSend except takes a selector name instead of a selector
pub fn msgSendByName(comptime ReturnType: type, target: anytype, sel_name: [:0]const u8, args: anytype) !ReturnType {
    const selector = try sel_getUid(sel_name);
    return msgSend(ReturnType, target, selector, args);
}

/// Convenience fn for sending an alloc message to a Class object followed by an init message to the returned Class instance
pub fn allocAndInit(class: Class) !id {
    const alloc_sel = try sel_getUid("alloc");
    const init_sel = try sel_getUid("init");
    return msgSend(id, msgSend(Class, class, alloc_sel, .{}), init_sel, .{});
}

/// Convenience fn for sending a dealloc message to object
pub fn dealloc(instance: id) !void {
    const dealloc_sel = try sel_getUid("dealloc");
    msgSend(void, instance, dealloc_sel, .{});
}

pub const IvarDesc = struct {
    name: [:0]const u8,
    @"type": type,
};

/// Convenience fn for defining and registering a new Class
pub fn defineAndRegisterClass(name: [:0]const u8, superclass: Class, comptime ivars: []const IvarDesc, methods: anytype) !Class {
    const class = try allocateClassPair(superclass, name, 0);
    errdefer disposeClassPair(class);

    var type_encoding_buf = [_]u8{0} ** 256;

    inline for (ivars) |ivar| {
        const type_enc_str = encode: {
            var fbs = std.io.fixedBufferStream(&type_encoding_buf);
            try writeEncodingForType(ivar.type, fbs.writer());
            const len = fbs.getWritten().len + 1;
            break :encode type_encoding_buf[0..len :0];
        };
        if (class_addIvar(class, ivar.name, @sizeOf(ivar.type), @alignOf(ivar.type), type_enc_str) == false) {
            return error.FailedToAddIvarToClass;
        }
        std.mem.set(u8, &type_encoding_buf, 0);
    }

    inline for (methods) |m| {
        const FnType = @TypeOf(m);
        const type_enc_str = encode: {
            var fbs = std.io.fixedBufferStream(&type_encoding_buf);
            try writeEncodingForType(FnType, fbs.writer());
            const len = fbs.getWritten().len + 1;
            break :encode type_encoding_buf[0..len :0];
        };
        std.debug.print("{s}\n", .{type_enc_str});
        const selector = try sel_getUid(@typeName(FnType));
        if (class_addMethod(class, selector, m, type_enc_str) == false) {
            return error.FailedToAddMethodToClass;
        }
        std.mem.set(u8, &type_encoding_buf, 0);
    }

    registerClassPair(class);

    return class;
}

test {
    testing.refAllDecls(@This());
}

test "alloc/init/dealloc NSObject" {
    const NSObject = try getClass("NSObject");
    const new_obj = try allocAndInit(NSObject);
    try dealloc(new_obj);
}

test "register/call/deregister Objective-C Class" {
    try struct {
        pub fn runTest() !void {
            const NSObject = try getClass("NSObject");

            const TestClass = try defineAndRegisterClass(
                "TestClass",
                NSObject,
                &.{
                    .{ .name = "foo", .type = c_int },
                },
                .{
                    add,
                },
            );

            const instance = try allocAndInit(TestClass);

            try testing.expectEqual(
                @as(c_int, 3),
                try msgSendByName(c_int, instance, "add", .{ @as(c_int, 1), @as(c_int, 2) }),
            );

            try dealloc(instance);
        }

        fn add(_: id, _: SEL, a: c_int, b: c_int) callconv(.C) c_int {
            return a + b;
        }
    }.runTest();
}
