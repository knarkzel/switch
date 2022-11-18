const std = @import("std");
const builtin = @import("builtin");

const name = "switch";
const flags = .{"-lnx"};
const devkitpro = "result";

pub fn build(b: *std.build.Builder) void {
    const mode = b.standardReleaseOptions();

    const obj = b.addObject(name, "src/main.zig");
    obj.linkLibC();
    obj.setLibCFile(std.build.FileSource{ .path = "libc.txt" });
    obj.addIncludeDir(devkitpro ++ "/libnx/include");
    obj.addIncludeDir(devkitpro ++ "/portlibs/switch/include");
    obj.setTarget(.{
        .cpu_arch = .aarch64,
        .os_tag = .freestanding,
        .cpu_model = .{ .explicit = &std.Target.aarch64.cpu.cortex_a57 },
    });
    obj.setBuildMode(mode);

    const elf = b.addSystemCommand(&(.{
        devkitpro ++ "/devkitA64/bin/aarch64-none-elf-gcc",
        "-g",
        "-march=armv8-a+crc+crypto",
        "-mtune=cortex-a57",
        "-mtp=soft",
        "-fPIE",
        "-Wl,-Map,zig-out/" ++ name ++ ".map",
        "-specs=" ++ devkitpro ++ "/libnx/switch.specs",
        "zig-out/" ++ name ++ ".o",
        "-L" ++ devkitpro ++ "/libnx/lib",
        "-L" ++ devkitpro ++ "/portlibs/switch/lib",
    } ++ flags ++ .{
        "-o",
        "zig-out/" ++ name ++ ".elf",
    }));

    const nro = b.addSystemCommand(&.{
        devkitpro ++ "/tools/bin/elf2nro",
        "zig-out/" ++ name ++ ".elf",
        "zig-out/" ++ name ++ ".nro",
    });

    b.default_step.dependOn(&nro.step);
    nro.step.dependOn(&elf.step);
    elf.step.dependOn(&obj.step);

    const run_step = b.step("run", "Run in Ryujinx");
    const ryujinx = b.addSystemCommand(&.{ "ryujinx", "zig-out/" ++ name ++ ".nro" });
    run_step.dependOn(&nro.step);
    run_step.dependOn(&ryujinx.step);
}
