# zig-objcrt

Objective-C Runtime bindings for Zig 

Provides thin, type-safe API bindings

Also provides higher-level wrappers to make working with the objc runtime nicer. Let's you write code like this:

```zig
pub fn main() anyerror!void {
    const NSObject = try objc.getClass("NSObject");
    const NSApplication = try objc.getClass("NSApplication");

    const application = try objc.msgSendByName(objc.id, NSApplication, "sharedApplication", .{});

    const AppDelegate = try objc.defineAndRegisterClass(
        "AppDelegate",
        NSObject,
        .{},
        .{
            .{ "applicationDidFinishLaunching:", applicationDidFinishLaunching },
        },
    );

    const app_delegate = try objc.new(AppDelegate);

    try objc.msgSendByName(void, application, "setDelegate:", .{app_delegate});
    try objc.msgSendByName(void, application, "run", .{});
}

pub fn applicationDidFinishLaunching(_: objc.id, _: objc.SEL, _: objc.id) callconv(.C) void {
    std.debug.print("hello objective c!\n", .{});
}
```

WARNING: Still quite early in development. Does not yet have full API coverage and needs more testing
