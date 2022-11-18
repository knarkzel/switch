const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const name = "switch";
    const libc = std.os.getenv("LIBC") orelse @panic("Make sure to set LIBC");
    const devkitpro = std.os.getenv("DEVKITPRO") orelse @panic("Make sure to set DEVKITPRO");

    const obj = b.addObject(name, "src/main.zig");
    obj.linkLibC();
    obj.setOutputDir("zig-out");
    obj.setLibCFile(std.build.FileSource{ .path = libc });
    obj.addIncludeDir(b.fmt("{s}/libnx/include", .{devkitpro}));
    obj.addIncludeDir(b.fmt("{s}/portlibs/switch/include", .{devkitpro}));
    obj.setTarget(.{
        .cpu_arch = .aarch64,
        .os_tag = .freestanding,
        .cpu_model = .{ .explicit = &std.Target.aarch64.cpu.cortex_a57 },
    });
    obj.setBuildMode(b.standardReleaseOptions());

    const elf = b.addSystemCommand(&(.{
        b.fmt("{s}/devkitA64/bin/aarch64-none-elf-gcc", .{devkitpro}),
        "-g",
        "-march=armv8-a+crc+crypto",
        "-mtune=cortex-a57",
        "-mtp=soft",
        "-fPIE",
        b.fmt("-Wl,-Map,zig-out/{s}.map", .{name}),
        b.fmt("-specs={s}/libnx/switch.specs", .{devkitpro}),
        b.fmt("zig-out/{s}.o", .{name}),
        b.fmt("-L{s}/libnx/lib", .{devkitpro}),
        b.fmt("-L{s}/portlibs/switch/lib", .{devkitpro}),
        "-lnx",
        "-o",
        b.fmt("zig-out/{s}.elf", .{name}),
    }));

    const nro = b.addSystemCommand(&.{
        b.fmt("{s}/tools/bin/elf2nro", .{devkitpro}),
        b.fmt("zig-out/{s}.elf", .{name}),
        b.fmt("zig-out/{s}.nro", .{name}),
    });

    b.default_step.dependOn(&nro.step);
    nro.step.dependOn(&elf.step);
    elf.step.dependOn(&obj.step);

    const run_step = b.step("run", "Run in Ryujinx");
    const ryujinx = b.addSystemCommand(&.{ "Ryujinx", b.fmt("zig-out/{s}.nro", .{name}) });
    run_step.dependOn(&nro.step);
    run_step.dependOn(&ryujinx.step);
}
