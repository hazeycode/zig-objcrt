//! This is the top level module that exposes type-safe Objective-C runtime bindings and convenience wrappers

const std = @import("std");

const objc = @import("objc.zig");
pub const object = objc.object;
pub const Class = objc.Class;
pub const id = objc.id;
pub const SEL = objc.SEL;
pub const sel_registerName = objc.sel_registerName;
pub const sel_getUid = objc.sel_getUid;

const runtime = @import("runtime.zig");
pub const getClass = runtime.getClass;
pub const getMetaClass = runtime.getMetaClass;
pub const lookUpClass = runtime.lookUpClass;
pub const allocateClassPair = runtime.allocateClassPair;
pub const registerClass = runtime.registerClass;
pub const disposeClassPair = runtime.disposeClassPair;

const message = @import("message.zig");
pub const msgSend = message.msgSend;

const type_encoding = @import("type-encoding.zig");

pub fn allocAndInit(class: Class) id {
    return msgSend(msgSend(class, "alloc", .{}, Class), "init", .{}, id);
}

test {
    std.testing.refAllDecls(@This());
}
