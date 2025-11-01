const std = @import("std");
const za = @import("zalgebra");
const Vec3 = za.Vec3; 
const Mat4 = za.Mat4; 
const geometry = @import("utils/geometry.zig");
const Transform = @import("utils/transform.zig").Transform;
const Drawable = @import("drawable.zig").Drawable;

pub const Polygon = struct {
    base: Drawable,
    vertices: []const Vec3,
    color: Vec3,

    pub fn new(vertices: []const Vec3, color: Vec3) !Polygon {
        var polygon = Polygon{
            .base = Drawable.init(.TriangleMesh),
            .vertices = vertices,
            .color = color,
        };

        try polygon.generateVertices();
        return polygon;
    }

    fn generateVertices(self: *Polygon) !void {
        const firstVertex = self.vertices[0];

        // Generate a fan of triangles with the given vertices
        for (self.vertices, 0..) |v1, i| {
            if (i == self.vertices.len - 1) break;

            const v2 = self.vertices[i+1];
            try self.base.appendVec3(firstVertex);
            try self.base.appendVec3(self.color);

            try self.base.appendVec3(v1);
            try self.base.appendVec3(self.color);

            try self.base.appendVec3(v2);
            try self.base.appendVec3(self.color);
        }
    }
};
