//! This is the top level module that exposes type-safe Objective-C runtime bindings and convenience wrappers

const std = @import("std");

const objc = @import("objc.zig");
pub const object = objc.object;
pub const Class = objc.Class;
pub const id = objc.id;
pub const SEL = objc.SEL;
pub const sel_registerName = objc.sel_registerName;
pub const sel_getUid = objc.sel_getUid;

const message = @import("message.zig");
pub const msgSend = message.msgSend;

const type_encoding = @import("type-encoding.zig");

const c = @import("c.zig");

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

// Adding classes

pub fn allocateClassPair(superclass: Class, class_name: [:0]const u8) !Class {
    return c.objc_allocateClassPair(superclass, class_name, 0) orelse error.FailedToAllocateClassPair;
}

pub fn registerClass(class: Class) void {
    c.objc_registerClassPair(class);
}

pub fn disposeClassPair(class: Class) void {
    c.objc_disposeClassPair(class);
}

test {
    std.testing.refAllDecls(@This());
}
