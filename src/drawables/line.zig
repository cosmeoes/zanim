const std = @import("std");
const za = @import("zalgebra");
const Vec3 = za.Vec3; 
const Mat4 = za.Mat4; 
const geometry = @import("utils/geometry.zig");
const Transform = @import("utils/transform.zig").Transform;
const Drawable = @import("drawable.zig").Drawable;

pub const Line = struct {
    base: Drawable,
    start: Vec3,
    end: Vec3,
    color: Vec3,

    pub fn new(start: Vec3, end: Vec3, color: Vec3) !Line {
        var line = Line {
            .base = Drawable.init(.LineSegments),
            .start = start,
            .end = end,
            .color = color,
        };

        try line.generateVertices();
        return line;
    }

    pub fn generateVertices(self: *Line) !void {
        try self.base.appendVec3(self.start);
        try self.base.appendVec3(self.color);

        try self.base.appendVec3(self.end);
        try self.base.appendVec3(self.color);
    }
};
