const std = @import("std");
const Drawable = @import("drawables/drawable.zig").Drawable;
const Animatable = @import("animation/animation.zig").Animatable;

pub const Scene = struct {
    objects: std.ArrayList(*Drawable),
    animations: std.ArrayList(Animatable),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !Scene {
        return Scene{
            .objects = .empty, 
            .animations = .empty,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Scene) void {
        self.objects.deinit(self.allocator);
        self.animations.deinit(self.allocator);
    }

    pub fn add(self: *Scene, drawable: *Drawable) !void {
        try self.objects.append(self.allocator, drawable);
    }

    pub fn play(self: *Scene, animation: Animatable) !void {
        try self.animations.append(self.allocator, animation);
    }

    pub fn update(self: *Scene, dt: f32) void {
        var i: usize = 0;
        while (i < self.animations.items.len) {
            var anim = self.animations.items[i];
            anim.update(dt);

            if (anim.isFinished()) {
                _ = self.animations.orderedRemove(i);
            } else {
                i += 1;
            }
        }
    }
};

