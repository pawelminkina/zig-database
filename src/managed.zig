const std = @import("std");

pub fn Managed(comptime T: type) type {
    return struct {
        value: T,
        arena: *std.heap.ArenaAllocator,

        const Self = @This();

        pub fn fromJson(parsed: std.json.Parsed(T)) Self {
            return .{
                .arena = parsed.arena,
                .value = parsed.value,
            };
        }

        pub fn deinit(self: Self) void {
            const arena = self.arena;
            const allocator = arena.child_allocator;
            arena.deinit();
            allocator.destroy(arena);
        }
    };
}
