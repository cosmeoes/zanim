const std = @import("std");
const Drawable = @import("drawables/drawable.zig").Drawable;

pub const Scene = struct {
    objects: std.ArrayList(*Drawable),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !Scene {
        return Scene{
            .objects = .empty, 
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Scene) void {
        self.objects.deinit(self.allocator);
    }

    pub fn add(self: *Scene, drawable: *Drawable) !void {
        try self.objects.append(self.allocator, drawable);
    }
};
