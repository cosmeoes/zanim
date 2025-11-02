const std = @import("std");
const za = @import("zalgebra");
const Vec3 = za.Vec3; 
const Mat4 = za.Mat4; 
const Drawable = @import("drawable.zig").Drawable;
const geometry = @import("utils/geometry.zig");

pub const DrawableType = enum {
    Line,
    Polygon,
};

pub fn generateVerticesUsingType(drawable: *Drawable) !void {
    try switch (drawable.drawableType) {
        .Line => Line.generateVertices(drawable),
        .Polygon => Polygon.generateVertices(drawable),
    };
}

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
