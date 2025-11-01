const Line = @import("../drawables/drawable_types.zig").Line;
const Polygon = @import("../drawables/drawable_types.zig").Polygon;
const Drawable = @import("../drawables/drawable.zig").Drawable;
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
