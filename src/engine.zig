const std = @import("std");
const Previewer = @import("preview/previewer.zig").Previewer;
const PreviewConfig = @import("preview/previewer.zig").PreviewConfig;
const Scene = @import("scene.zig").Scene;

pub const Engine = struct {
    allocator: std.mem.Allocator,
    arenas: std.ArrayList(*std.heap.ArenaAllocator),

    pub fn init(allocator: std.mem.Allocator) !Engine {
        return .{
            .allocator = allocator,
            .arenas = .empty,
        };
    }

    pub fn deinit(self: *Engine) void {
        for (self.arenas.items) |arena| {
            self.allocator.destroy(arena);
        }

        self.arenas.deinit(self.allocator);
    }

    pub fn createScene(self: *Engine) !Scene {
        const arena = try self.allocator.create(std.heap.ArenaAllocator);
        arena.* = std.heap.ArenaAllocator.init(self.allocator);
        try self.arenas.append(self.allocator, arena);
        return try Scene.init(arena);
    }

    pub fn preview(self: *Engine, scene: *Scene, config: PreviewConfig) !void {
        var previewer = try Previewer.init(self.allocator, config);
        defer previewer.deinit();

        try previewer.run(scene);
    }
};
