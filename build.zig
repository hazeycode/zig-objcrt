const std = @import("std");

pub fn build(b: *std.build.Builder) !void {
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const lib = b.addStaticLibrary("zig-objcrt", "src/main.zig");
    lib.setBuildMode(mode);
    lib.install();

    const main_tests = b.addTest("src/main.zig");
    main_tests.setBuildMode(mode);

    { // link obj-c stuff
        const host = try std.zig.system.NativeTargetInfo.detect(b.allocator, .{});
        const sdk = std.zig.system.darwin.getDarwinSDK(b.allocator, host.target) orelse return error.FailedToGetDarwinSDK;
        defer sdk.deinit(b.allocator);
        const framework_dir = try std.mem.concat(b.allocator, u8, &[_][]const u8{ sdk.path, "/System/Library/Frameworks" });
        main_tests.addFrameworkDir(framework_dir);
        main_tests.linkFramework("CoreFoundation");
    }

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);
}
