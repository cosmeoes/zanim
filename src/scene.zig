const std = @import("std");
const Drawable = @import("drawables/drawable.zig").Drawable;
const Animatable = @import("animation/animation.zig").Animatable;
const DrawableType = @import("drawables/drawable_types.zig").DrawableType;
const AnimationGroup = @import("animation/animation.zig").AnimationGroup;
const Wait = @import("animation/animation.zig").Wait;

pub const Scene = struct {
    objects: std.ArrayList(*Drawable),
    animation_queue: std.ArrayList(Animatable),
    current_animation: ?Animatable,
    arena: *std.heap.ArenaAllocator,
    a: std.mem.Allocator,

    pub fn init(arena: *std.heap.ArenaAllocator) !Scene {
        return .{
            .objects = .empty,
            .animation_queue = .empty,
            .current_animation = null,
            .arena = arena,
            .a = arena.allocator(),
        };
    }

    pub fn deinit(self: *Scene) void {
        self.arena.deinit();
    }

    pub fn add(self: *Scene, drawable: *Drawable) !void {
        try self.objects.append(self.a, drawable);
    }

    pub fn play(self: *Scene, animation: Animatable) !void {
        try self.animation_queue.append(self.a, animation);
    }

    pub fn playGroup(self: *Scene, animations: []const Animatable) !void {
        const group = try self.create(AnimationGroup, try .init(self.a, animations));
        try self.animation_queue.append(self.a, group.asAnimatable());
    }

    pub fn wait(self: *Scene, duration: f32) error{OutOfMemory}!void {
        const waitAnim = try self.create(Wait, .init(duration));
        try self.play(waitAnim.asAnimatable());
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
                animation.finalize();
                self.current_animation = null;
            }
        }
    }

    pub fn create(self: *Scene, comptime wanted: type, value: wanted) error{OutOfMemory}!*wanted {
        const created = try self.a.create(wanted);
        created.* = value;
        return created;
    }
};

