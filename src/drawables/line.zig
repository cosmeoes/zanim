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
            .base = Drawable{
                .vertex_mode = .LineSegments,
                .vertices = std.ArrayList(f32){},
                .transform = Transform.init(),
            },
            .start = start,
            .end = end,
            .color = color,
        };

        try line.generateVertices();
        return line;
    }

    fn generateVertices(self: *Line) !void {
        try self.base.vertices.append(Drawable.getAllocator(), self.start.x());
        try self.base.vertices.append(Drawable.getAllocator(), self.start.y());
        try self.base.vertices.append(Drawable.getAllocator(), self.start.z());
        try self.base.vertices.append(Drawable.getAllocator(), self.color.x());
        try self.base.vertices.append(Drawable.getAllocator(), self.color.y());
        try self.base.vertices.append(Drawable.getAllocator(), self.color.z());

        try self.base.vertices.append(Drawable.getAllocator(), self.end.x());
        try self.base.vertices.append(Drawable.getAllocator(), self.end.y());
        try self.base.vertices.append(Drawable.getAllocator(), self.end.z());
        try self.base.vertices.append(Drawable.getAllocator(), self.color.x());
        try self.base.vertices.append(Drawable.getAllocator(), self.color.y());
        try self.base.vertices.append(Drawable.getAllocator(), self.color.z());
    }
};
