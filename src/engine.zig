const std = @import("std");
const Previewer = @import("preview/previewer.zig").Previewer;
const PreviewConfig = @import("preview/previewer.zig").PreviewConfig;
const Scene = @import("scene.zig").Scene;

pub const Engine = struct {
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !Engine {
        return .{
            .allocator = allocator,
        };
    }

    pub fn createScene(self: *Engine) !Scene {
        return Scene.init(self.allocator);
    }

    pub fn preview(self: *Engine, scene: *Scene, config: PreviewConfig) !void {
        var previewer = try Previewer.init(self.allocator, config);
        defer previewer.deinit();

        try previewer.run(scene);
    }
};
