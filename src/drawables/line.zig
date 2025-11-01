const std = @import("std");
const za = @import("zalgebra");
const Vec3 = za.Vec3; 
const Mat4 = za.Mat4; 
const geometry = @import("utils/geometry.zig");
const Transform = @import("utils/transform.zig").Transform;
const Drawable = @import("drawable.zig").Drawable;

pub const Line = struct {
    base: Drawable,

    pub fn new(startPos: Vec3, endPos: Vec3, color: Vec3) !Line {
        const vertices = [_]Vec3{startPos, endPos};
        var line = Line{
            .base = try Drawable.init(.LineSegments, .Line, &vertices),
        };
        line.base.setColor(color);

        return line;
    }

    pub fn setStart(self: *Line, newValue: Vec3) void {
        self.base.vertices.items[0] = newValue;
    }

    pub fn start(self: *Line) Vec3 {
        return self.base.vertices.items[0];
    }

    pub fn setEnd(self: *Line, newValue: Vec3) void {
        self.base.vertices.items[1] = newValue;
    }

    pub fn end(self: *Line) Vec3 {
        return self.base.vertices.items[1];
    }

    pub fn generateVertices(drawable: *Drawable) !void {
        try drawable.appendVec3(drawable.vertices.items[0]);
        try drawable.appendVec3(drawable.color);

        try drawable.appendVec3(drawable.vertices.items[1]);
        try drawable.appendVec3(drawable.color);
    }
};
