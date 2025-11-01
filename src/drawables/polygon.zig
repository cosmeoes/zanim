const std = @import("std");
const za = @import("zalgebra");
const Vec3 = za.Vec3; 
const Mat4 = za.Mat4; 
const geometry = @import("utils/geometry.zig");
const Transform = @import("utils/transform.zig").Transform;
const Drawable = @import("drawable.zig").Drawable;

pub const Polygon = struct {
    base: Drawable,

    pub fn new(vertices: []const Vec3, color: Vec3) !Polygon {
        var polygon = Polygon{
            .base = try Drawable.init(.TriangleMesh, .Polygon, vertices),
        };
        polygon.base.setColor(color);

        return polygon;
    }

    pub fn generateVertices(drawable: *Drawable) !void {
        const firstVertex = drawable.vertices.items[0];

        // Generate a fan of triangles with the given vertices
        for (drawable.vertices.items, 0..) |v1, i| {
            if (i == drawable.vertices.items.len - 1) break;

            const v2 = drawable.vertices.items[i+1];
            try drawable.appendVec3(firstVertex);
            try drawable.appendVec3(drawable.color);

            try drawable.appendVec3(v1);
            try drawable.appendVec3(drawable.color);

            try drawable.appendVec3(v2);
            try drawable.appendVec3(drawable.color);
        }
    }
};
