const std = @import("std");
const bun = @import("root").bun;
const Allocator = std.mem.Allocator;

pub const css = @import("./css_parser.zig");

const Printer = css.Printer;
const PrintErr = css.PrintErr;
const VendorPrefix = css.VendorPrefix;

/// Target browsers and features to compile.
pub const Targets = struct {
    /// Browser targets to compile the CSS for.
    browsers: ?Browsers = null,
    /// Features that should always be compiled, even when supported by targets.
    include: Features = .{},
    /// Features that should never be compiled, even when unsupported by targets.
    exclude: Features = .{},

    /// Set a sane default for bundler
    pub fn browserDefault() Targets {
        return .{
            .browsers = Browsers.browserDefault,
        };
    }

    /// Set a sane default for bundler
    pub fn runtimeDefault() Targets {
        return .{
            .browsers = null,
        };
    }

    pub fn forBundlerTarget(target: bun.transpiler.options.Target) Targets {
        return switch (target) {
            .node, .bun => runtimeDefault(),
            .browser, .bun_macro, .bake_server_components_ssr => browserDefault(),
        };
    }

    pub fn prefixes(this: *const Targets, prefix: css.VendorPrefix, feature: css.prefixes.Feature) css.VendorPrefix {
        if (prefix.contains(css.VendorPrefix{ .none = true }) and !this.exclude.contains(css.targets.Features{ .vendor_prefixes = true })) {
            if (this.include.contains(css.targets.Features{ .vendor_prefixes = true })) {
                return css.VendorPrefix.all();
            } else {
                return if (this.browsers) |b| feature.prefixesFor(b) else prefix;
            }
        } else {
            return prefix;
        }
    }

    pub fn shouldCompileLogical(this: *const Targets, feature: css.compat.Feature) bool {
        return this.shouldCompile(feature, css.Features{ .logical_properties = true });
    }

    pub fn shouldCompile(this: *const Targets, feature: css.compat.Feature, flag: Features) bool {
        return this.include.contains(flag) or (!this.exclude.contains(flag) and !this.isCompatible(feature));
    }

    pub fn shouldCompileSame(this: *const Targets, comptime compat_feature: css.compat.Feature) bool {
        const target_feature: css.targets.Features = target_feature: {
            var feature: css.targets.Features = .{};
            @field(feature, @tagName(compat_feature)) = true;
            break :target_feature feature;
        };

        return shouldCompile(this, compat_feature, target_feature);
    }

    pub fn shouldCompileSelectors(this: *const Targets) bool {
        return this.include.intersects(Features.selectors) or
            (!this.exclude.intersects(Features.selectors) and this.browsers != null);
    }

    pub fn isCompatible(this: *const Targets, feature: css.compat.Feature) bool {
        if (this.browsers) |*targets| {
            return feature.isCompatible(targets.*);
        }
        return true;
    }
};

/// Autogenerated by build-prefixes.js
///
/// Browser versions to compile CSS for.
///
/// Versions are represented as a single 24-bit integer, with one byte
/// per `major.minor.patch` component.
///
/// # Example
///
/// This example represents a target of Safari 13.2.0.
///
/// ```
/// const Browsers = struct {
///   safari: ?u32 = (13 << 16) | (2 << 8),
///   ..Browsers{}
/// };
/// ```
pub const Browsers = struct {
    android: ?u32 = null,
    chrome: ?u32 = null,
    edge: ?u32 = null,
    firefox: ?u32 = null,
    ie: ?u32 = null,
    ios_saf: ?u32 = null,
    opera: ?u32 = null,
    safari: ?u32 = null,
    samsung: ?u32 = null,
    pub usingnamespace BrowsersImpl(@This());
};

/// Autogenerated by build-prefixes.js
/// Features to explicitly enable or disable.
pub const Features = packed struct(u32) {
    nesting: bool = false,
    not_selector_list: bool = false,
    dir_selector: bool = false,
    lang_selector_list: bool = false,
    is_selector: bool = false,
    text_decoration_thickness_percent: bool = false,
    media_interval_syntax: bool = false,
    media_range_syntax: bool = false,
    custom_media_queries: bool = false,
    clamp_function: bool = false,
    color_function: bool = false,
    oklab_colors: bool = false,
    lab_colors: bool = false,
    p3_colors: bool = false,
    hex_alpha_colors: bool = false,
    space_separated_color_notation: bool = false,
    font_family_system_ui: bool = false,
    double_position_gradients: bool = false,
    vendor_prefixes: bool = false,
    logical_properties: bool = false,
    __unused: u12 = 0,

    pub const selectors = Features.fromNames(&.{ "nesting", "not_selector_list", "dir_selector", "lang_selector_list", "is_selector" });
    pub const media_queries = Features.fromNames(&.{ "media_interval_syntax", "media_range_syntax", "custom_media_queries" });
    pub const colors = Features.fromNames(&.{ "color_function", "oklab_colors", "lab_colors", "p3_colors", "hex_alpha_colors", "space_separated_color_notation" });

    pub usingnamespace css.Bitflags(@This());
    pub usingnamespace FeaturesImpl(@This());
};

pub fn BrowsersImpl(comptime T: type) type {
    return struct {
        pub const browserDefault = convertFromString(&.{
            "es2020", // support import.meta.url
            "edge88",
            "firefox78",
            "chrome87",
            "safari14",
        }) catch |e| std.debug.panic("WOOPSIE: {s}\n", .{@errorName(e)});

        // pub const bundlerDefault = T{
        //     .chrome = 80 << 16,
        //     .edge = 80 << 16,
        //     .firefox = 78 << 16,
        //     .safari = 14 << 16,
        //     .opera = 67 << 16,
        // };

        /// Ported from here:
        /// https://github.com/vitejs/vite/blob/ac329685bba229e1ff43e3d96324f817d48abe48/packages/vite/src/node/plugins/css.ts#L3335
        pub fn convertFromString(esbuild_target: []const []const u8) anyerror!T {
            var browsers: T = .{};

            for (esbuild_target) |str| {
                var entries_buf: [5][]const u8 = undefined;
                const entries_without_es: [][]const u8 = entries_without_es: {
                    if (str.len <= 2 or !(str[0] == 'e' and str[1] == 's')) {
                        entries_buf[0] = str;
                        break :entries_without_es entries_buf[0..1];
                    }

                    const number_part = str[2..];
                    const year = try std.fmt.parseInt(u16, number_part, 10);
                    switch (year) {
                        // https://caniuse.com/?search=es2015
                        2015 => {
                            entries_buf[0..5].* = .{ "chrome49", "edge13", "safari10", "firefox44", "opera36" };
                            break :entries_without_es entries_buf[0..5];
                        },
                        // https://caniuse.com/?search=es2016
                        2016 => {
                            entries_buf[0..5].* = .{ "chrome50", "edge13", "safari10", "firefox43", "opera37" };
                            break :entries_without_es entries_buf[0..5];
                        },
                        // https://caniuse.com/?search=es2017
                        2017 => {
                            entries_buf[0..5].* = .{ "chrome58", "edge15", "safari11", "firefox52", "opera45" };
                            break :entries_without_es entries_buf[0..5];
                        },
                        // https://caniuse.com/?search=es2018
                        2018 => {
                            entries_buf[0..5].* = .{ "chrome63", "edge79", "safari12", "firefox58", "opera50" };
                            break :entries_without_es entries_buf[0..5];
                        },
                        // https://caniuse.com/?search=es2019
                        2019 => {
                            entries_buf[0..5].* = .{ "chrome73", "edge79", "safari12.1", "firefox64", "opera60" };
                            break :entries_without_es entries_buf[0..5];
                        },
                        // https://caniuse.com/?search=es2020
                        2020 => {
                            entries_buf[0..5].* = .{ "chrome80", "edge80", "safari14.1", "firefox80", "opera67" };
                            break :entries_without_es entries_buf[0..5];
                        },
                        // https://caniuse.com/?search=es2021
                        2021 => {
                            entries_buf[0..5].* = .{ "chrome85", "edge85", "safari14.1", "firefox80", "opera71" };
                            break :entries_without_es entries_buf[0..5];
                        },
                        // https://caniuse.com/?search=es2022
                        2022 => {
                            entries_buf[0..5].* = .{ "chrome94", "edge94", "safari16.4", "firefox93", "opera80" };
                            break :entries_without_es entries_buf[0..5];
                        },
                        // https://caniuse.com/?search=es2023
                        2023 => {
                            entries_buf[0..4].* = .{ "chrome110", "edge110", "safari16.4", "opera96" };
                            break :entries_without_es entries_buf[0..4];
                        },
                        else => {
                            if (@inComptime()) {
                                @compileLog("Invalid target: " ++ str);
                            }
                            return error.UnsupportedCSSTarget;
                        },
                    }
                };

                for_loop: for (entries_without_es) |entry| {
                    if (bun.strings.eql(entry, "esnext")) continue;
                    const maybe_idx: ?usize = maybe_idx: {
                        for (entry, 0..) |c, i| {
                            if (std.ascii.isDigit(c)) break :maybe_idx i;
                        }
                        break :maybe_idx null;
                    };

                    if (maybe_idx) |idx| {
                        const Browser = enum {
                            chrome,
                            edge,
                            firefox,
                            ie,
                            ios_saf,
                            opera,
                            safari,
                            no_mapping,
                        };
                        const Map = bun.ComptimeStringMap(Browser, .{
                            .{ "chrome", Browser.chrome },
                            .{ "edge", Browser.edge },
                            .{ "firefox", Browser.firefox },
                            .{ "hermes", Browser.no_mapping },
                            .{ "ie", Browser.ie },
                            .{ "ios", Browser.ios_saf },
                            .{ "node", Browser.no_mapping },
                            .{ "opera", Browser.opera },
                            .{ "rhino", Browser.no_mapping },
                            .{ "safari", Browser.safari },
                        });
                        const browser = Map.get(entry[0..idx]);
                        if (browser == null or browser.? == .no_mapping) continue; // No mapping available

                        const major, const minor = major_minor: {
                            const version_str = entry[idx..];
                            const dot_index = std.mem.indexOfScalar(u8, version_str, '.') orelse version_str.len;
                            const major = std.fmt.parseInt(u16, version_str[0..dot_index], 10) catch continue;
                            const minor = if (dot_index < version_str.len)
                                std.fmt.parseInt(u16, version_str[dot_index + 1 ..], 10) catch 0
                            else
                                0;
                            break :major_minor .{ major, minor };
                        };

                        const version: u32 = (@as(u32, major) << 16) | @as(u32, minor << 8);
                        switch (browser.?) {
                            inline else => |browser_name| {
                                if (@field(browsers, @tagName(browser_name)) == null or
                                    version < @field(browsers, @tagName(browser_name)).?)
                                {
                                    @field(browsers, @tagName(browser_name)) = version;
                                }
                                continue :for_loop;
                            },
                        }
                    }
                }
            }

            return browsers;
        }
    };
}

pub fn FeaturesImpl(comptime T: type) type {
    _ = T; // autofix
    return struct {};
}
