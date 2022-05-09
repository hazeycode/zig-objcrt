# zig-objcrt

Objective-C Runtime bindings for Zig 

Provides thin API bindings with a little added type-safety and error handling

Also provides higher-level wrappers to make working with the objc runtime a little bit nicer


**NOTE:** This is for working with the runtime API, user-friendly bindings to Apple Frameworks are not provided by this library but may be built ontop.


**WARNING:** In early development. Does not yet have full API coverage and needs more testing. The higher-level APIs, i.e. `defineAndRegisterClass` are very WIP as there are some things to be worked out regarding memory management. Open to suggestions and issues and PRs are most welcome.


**NOTE:** Currently uses translate-c on the objective-c headers that are vendored with Zig. It's perhaps better not to rely on these and replace with extern definitions?


### Example usage

```zig
const objc = @import("zig-objcrt");

const NSInteger = c_long;
const NSApplicationActivationPolicyRegular: NSInteger = 0;

var application: objc.id = undefined;

pub fn main() anyerror!void {
    const NSObject = try objc.getClass("NSObject");
    const NSApplication = try objc.getClass("NSApplication");

    application = try objc.msgSendByName(objc.id, NSApplication, "sharedApplication", .{});

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
    objc.msgSendByName(void, application, "setActivationPolicy:", .{NSApplicationActivationPolicyRegular}) catch unreachable;

    objc.msgSendByName(void, application, "activateIgnoringOtherApps:", .{true}) catch unreachable;

    std.debug.print("Hello from Objective-C!\n", .{});
}
```

