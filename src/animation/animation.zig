const Line = @import("../drawables/line.zig").Line;
const Vec3 = @import("zalgebra").Vec3;

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


pub const CreateLine = struct {
    anim: Animation,
    line: *Line,
    original_end: Vec3,

    pub fn init(line: *Line, duration: f32) CreateLine {
        const origEnd = line.end;
        line.end = line.start;
        return .{
            .anim = Animation.init(duration),
            .line = line,
            .original_end = origEnd,
        };
    }

    pub fn update(self: *CreateLine, dt: f32) void {
        self.anim.update(dt);
        const progress = self.anim.getProgress();
        self.line.end = Vec3.lerp(self.line.start, self.original_end, progress);
    }

    pub fn isFinished(self: CreateLine) bool {
        return self.anim.isFinished();
    }

    pub fn asAnimatable(self: *CreateLine) Animatable {
        return Animatable.init(self);
    }
};
