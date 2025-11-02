const Line = @import("../drawables/drawable_types.zig").Line;
const Polygon = @import("../drawables/drawable_types.zig").Polygon;
const Drawable = @import("../drawables/drawable.zig").Drawable;
const Transform = @import("../drawables/utils/transform.zig").Transform;
const za = @import("zalgebra");
const Vec3 = @import("zalgebra").Vec3;
const std = @import("std");

pub const Animatable = struct {
    ptr: *anyopaque,
    updateFn: *const fn (*anyopaque, f32) void,
    isFinishedFn: *const fn (*anyopaque) bool,
    getDurationFn: *const fn(*anyopaque) f32,

    pub fn init(ptr: anytype) Animatable {
        const T = @TypeOf(ptr.*);
        const gen = struct {
            fn update(pointer: *anyopaque, dt: f32) void {
                const self: *T = @ptrCast(@alignCast(pointer));
                self.update(dt);
            }
            fn isFinished(pointer: *anyopaque) bool {
                const self: *T = @ptrCast(@alignCast(pointer));
                return self.isFinished();
            }
            fn getDuration(pointer: *anyopaque) f32 {
                const self: *T = @ptrCast(@alignCast(pointer));
                return self.getDuration();
            }
        };

        return .{
            .ptr = ptr,
            .updateFn = gen.update,
            .isFinishedFn = gen.isFinished,
            .getDurationFn = gen.getDuration
        };
    }

    pub fn update(self: Animatable, dt: f32) void {
        self.updateFn(self.ptr, dt);
    }

    pub fn isFinished(self: Animatable) bool {
        return self.isFinishedFn(self.ptr);
    }

    pub fn getDuration(self: Animatable) f32 {
        return self.getDurationFn(self.ptr);
    }
};

pub const Animation = struct {
    duration: f32,
    elapsed: f32,
    finished: bool,

    pub fn init(duration: f32) Animation {
        return .{
            .duration = duration,
            .elapsed = 0.0,
            .finished = false,
        };
    }

    pub fn update(self: *Animation, dt: f32) void {
        self.elapsed += dt;
        if (self.elapsed >= self.duration) {
            self.elapsed = self.duration;
            self.finished = true;
        }
    }

    pub fn getProgress(self: Animation) f32 {
        return self.elapsed / self.duration;
    }

    pub fn isFinished(self: Animation) bool {
        return self.finished;
    }
};

pub const AnimationGroup = struct {
    anim: Animation,
    animations: std.ArrayList(Animatable),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, animations: []const Animatable) !AnimationGroup {
        var maxDuration: f32 = 0;
        for (animations) |anim| {
            maxDuration = @max(maxDuration, anim.getDuration());
        }
        var group = AnimationGroup{
            .anim = Animation.init(maxDuration),
            .animations = .empty,
            .allocator = allocator,
        };

        try group.animations.appendSlice(allocator, animations);
        return group;
    }

    pub fn deinit(self: *AnimationGroup) void {
        self.animations.deinit(self.allocator);
    }

    pub fn update(self: *AnimationGroup, dt: f32) void {
        self.anim.update(dt);

        for (self.animations.items) |animation| {
            if (!animation.isFinished()) {
                animation.update(dt);
            }
        }
    }

    pub fn isFinished(self: AnimationGroup) bool {
        return self.anim.isFinished();
    }

    pub fn getDuration(self: AnimationGroup) f32 {
        return self.anim.duration;
    }

    pub fn asAnimatable(self: *AnimationGroup) Animatable {
        return Animatable.init(self);
    }
};

pub const Wait = struct {
    anim: Animation,

    pub fn init(duration: f32) Wait {
        return .{
            .anim = Animation.init(duration),
        };
    }

    pub fn update(self: *Wait, dt: f32) void {
        self.anim.update(dt);
    }

    pub fn isFinished(self: Wait) bool {
        return self.anim.isFinished();
    }

    pub fn getDuration(self: Wait) f32 {
        return self.anim.duration;
    }

    pub fn asAnimatable(self: *Wait) Animatable {
        return Animatable.init(self);
    }
};

pub const Create = struct {
    anim: Animation,
    drawable: *Drawable,
    original_vertices: std.ArrayList(Vec3),
    allocator: std.mem.Allocator,
    source_point: Vec3,

    pub fn init(allocator: std.mem.Allocator, drawable: *Drawable, duration: f32) !Create {
        const originalVertices = try drawable.vertices.clone(allocator);
        return .{
            .allocator = allocator,
            .anim = Animation.init(duration),
            .drawable = drawable,
            .original_vertices = originalVertices,
            .source_point = originalVertices.items[0],
        };
    }

    pub fn deinit(self: *Create) void {
        self.original_vertices.deinit(self.allocator);
    }

    pub fn fromCenter(self: *Create) void {
        var center = Vec3.new(0, 0, 0);
        for (self.drawable.vertices.items) |vertex| {
            center = center.add(vertex);
        }
        self.source_point = center.scale(1/@as(f32, @floatFromInt(self.drawable.vertices.items.len)));
    }

    pub fn update(self: *Create, dt: f32) void {
        self.anim.update(dt);
        const progress = self.anim.getProgress();

        for (0..self.drawable.vertices.items.len) |i| {
            self.drawable.vertices.items[i] = Vec3.lerp(self.source_point, self.original_vertices.items[i], progress);
        }
    }

    pub fn isFinished(self: Create) bool {
        return self.anim.isFinished();
    }

    pub fn getDuration(self: Create) f32 {
        return self.anim.duration;
    }

    pub fn asAnimatable(self: *Create) Animatable {
        return Animatable.init(self);
    }
};

pub const TransformAnim = struct {
    anim: Animation,
    drawable: *Drawable,
    original_vertices: std.ArrayList(Vec3),
    original_tranform: Transform,
    allocator: std.mem.Allocator,
    transform: Transform,

    pub fn init(allocator: std.mem.Allocator, drawable: *Drawable, transform: Transform, duration: f32) !TransformAnim {
        const originalVertices = try drawable.vertices.clone(allocator);
        return .{
            .allocator = allocator,
            .anim = Animation.init(duration),
            .drawable = drawable,
            .original_vertices = originalVertices,
            .original_tranform = drawable.transform,
            .transform = transform,
        };
    }

    pub fn deinit(self: *TransformAnim) void {
        self.original_vertices.deinit(self.allocator);
    }

    pub fn update(self: *TransformAnim, dt: f32) void {
        self.anim.update(dt);
        const progress = self.anim.getProgress();

        // TODO: update drawable transform so the end of the animation
        // is the new world position.
        self.drawable.anim_transform.position = Vec3.lerp(
            Vec3.zero(),
            self.transform.position,
            progress
        );

        self.drawable.anim_transform.scale = Vec3.lerp(
            Vec3.one(),
            self.transform.scale,
            progress
        );

        self.drawable.anim_transform.rotation = za.Quat.slerp(
            za.Quat.identity(),
            self.transform.rotation,
            progress
        );
    }

    pub fn isFinished(self: TransformAnim) bool {
        return self.anim.isFinished();
    }

    pub fn getDuration(self: TransformAnim) f32 {
        return self.anim.duration;
    }

    pub fn asAnimatable(self: *TransformAnim) Animatable {
        return Animatable.init(self);
    }
};
