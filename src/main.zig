const std = @import("std");
const foo = @import("foo.zig");
pub fn main() void {
    _ = foo.foo();
    std.debug.print("Hello, World!\n", .{});
}
