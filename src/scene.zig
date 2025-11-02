const std = @import("std");
const Drawable = @import("drawables/drawable.zig").Drawable;
const Animatable = @import("animation/animation.zig").Animatable;

pub const Scene = struct {
    objects: std.ArrayList(*Drawable),
    animation_queue: std.ArrayList(Animatable),
    current_animation: ?Animatable,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !Scene {
        return Scene{
            .objects = .empty, 
            .animation_queue= .empty,
            .current_animation= null,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Scene) void {
        self.objects.deinit(self.allocator);
        self.animation_queue.deinit(self.allocator);
    }

    pub fn add(self: *Scene, drawable: *Drawable) !void {
        try self.objects.append(self.allocator, drawable);
    }

    pub fn play(self: *Scene, animation: Animatable) !void {
        try self.animation_queue.append(self.allocator, animation);
    }

    pub fn update(self: *Scene, dt: f32) void {
        if (self.current_animation == null) {
            if (self.animation_queue.items.len > 0) {
                // This might be slow if there are a lot of animations
                // maybe I shoud use a real queue instead if this becomes a problem
                self.current_animation = self.animation_queue.orderedRemove(0);
            } else {
                return;
            }
        }

        if (self.current_animation) |animation| {
            animation.update(dt);
            if (animation.isFinished()) {
                self.current_animation = null;
            }
        }
    }
};

