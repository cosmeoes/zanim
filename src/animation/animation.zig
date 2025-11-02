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
        };

        return .{
            .ptr = ptr,
            .updateFn = gen.update,
            .isFinishedFn = gen.isFinished,
        };
    }

    pub fn update(self: Animatable, dt: f32) void {
        self.updateFn(self.ptr, dt);
    }

    pub fn isFinished(self: Animatable) bool {
        return self.isFinishedFn(self.ptr);
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

    pub fn asAnimatable(self: *Create) Animatable {
        return Animatable.init(self);
    }
};

pub const TransformAnim = struct {
    anim: Animation,
    drawables: *Drawable,
    original_vertices: std.ArrayList(Vec3),
    allocator: std.mem.Allocator,
    transform: Transform,

    pub fn init(allocator: std.mem.Allocator, drawable: *Drawable, transform: Transform, duration: f32) !TransformAnim {
        const originalVertices = try drawable.vertices.clone(allocator);
        return .{
            .allocator = allocator,
            .anim = Animation.init(duration),
            .drawable = drawable,
            .original_vertices = originalVertices,
            .transform = transform,
        };
    }

    pub fn deinit(self: *TransformAnim) void {
        self.original_vertices.deinit(self.allocator);
    }

    pub fn update(self: *TransformAnim, dt: f32) void {
        self.anim.update(dt);
        const progress = self.anim.getProgress();

        const rotationAngle = self.transform.rotation.extractAxisAngle();
        const lerpedAngle = za.lerp(f32, 0, rotationAngle.angle, progress);
        const rotation = za.Quat.fromAxis(lerpedAngle, rotationAngle.axis);
        const lerpedScale = Vec3.lerp(Vec3.new(1, 1, 1), self.transform.scale, progress);

        for (0..self.drawable.vertices.items.len) |i| {
            var newVertex = rotation.rotateVec(self.original_vertices.items[i]);
            newVertex = newVertex.mul(lerpedScale);
            self.drawable.vertices.items[i] = newVertex;
        }
    }

    pub fn isFinished(self: TransformAnim) bool {
        return self.anim.isFinished();
    }

    pub fn asAnimatable(self: *TransformAnim) Animatable {
        return Animatable.init(self);
    }
};
