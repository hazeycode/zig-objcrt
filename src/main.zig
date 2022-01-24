//! This is the top level module that exposes type-safe Objective-C runtime bindings and convenience wrappers

const std = @import("std");

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
pub const class_addMethod = runtime.class_addMethod;
pub const class_replaceMethod = runtime.class_replaceMethod;
pub const class_addIvar = runtime.class_addIvar;
pub const allocateClassPair = runtime.allocateClassPair;
pub const registerClass = runtime.registerClass;
pub const disposeClassPair = runtime.disposeClassPair;
pub const method_setImplementation = runtime.method_setImplementation;

const message = @import("message.zig");
pub const msgSend = message.msgSend;

const type_encoding = @import("type-encoding.zig");

/// The same as calling msgSend except takes a selector name instead of a selector
pub fn msgSendByName(comptime ReturnType: type, target: anytype, sel_name: [:0]const u8, args: anytype) !ReturnType {
    const selector = try sel_getUid(sel_name);
    return msgSend(ReturnType, target, selector, args);
}

pub fn allocAndInit(class: Class) !id {
    // TODO(chris): cache these selectors
    const alloc_sel = try sel_getUid("alloc");
    const init_sel = try sel_getUid("init");
    return msgSend(id, msgSend(Class, class, alloc_sel, .{}), init_sel, .{});
}

pub fn dealloc(instance: id) !void {
    // TODO(chris): cache this selectors
    const dealloc_sel = try sel_getUid("dealloc");
    msgSend(void, instance, dealloc_sel, .{});
}

test {
    std.testing.refAllDecls(@This());
}

test "alloc/init/dealloc NSObject" {
    const NSObject = try getClass("NSObject");
    const new_obj = try allocAndInit(NSObject);
    try dealloc(new_obj);
}
