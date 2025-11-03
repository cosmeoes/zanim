const std = @import("std");
const za = @import("zalgebra");
const Vec3 = za.Vec3;
const Vec4 = za.Vec4;
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
    const DEFAULT_WIDTH: f32 = 0.01;
    base: Drawable,
    // Do not modify directly, use helper methods
    startPos: Vec3,
    endPos: Vec3,
    width: f32,

    pub fn init(allocator: std.mem.Allocator, startPos: Vec3, endPos: Vec3, color: Vec4) error{OutOfMemory}!Line {
        const vertices = lineToVertices(startPos, endPos, DEFAULT_WIDTH);

        var line = Line{
            .base = try Drawable.init(allocator, .TriangleMesh, .Line, &vertices),
            .startPos = startPos,
            .endPos = endPos,
            .width = DEFAULT_WIDTH,
        };

        line.base.setColor(color);
        return line;
    }

    pub fn deinit(self: *Line) void {
        self.base.deinit();
    }

    pub fn setStart(self: *Line, newValue: Vec3) void {
        self.startPos = newValue;
        self.updateVertices();
    }

    pub fn setEnd(self: *Line, newValue: Vec3) void {
        self.endPos = newValue;
        self.updateVertices();
    }

    pub fn setWidth(self: *Line, width: f32) void {
        self.width = width;
        self.updateVertices();
    }

    fn updateVertices(self: *Line) void {
        lineToVertices(self.startPos, self.endPos, self.width);
    }

    // Converts the two points that define a line into the
    // four points of a rectangle to draw a line width width.
    fn lineToVertices(startPos: Vec3, endPos: Vec3, width: f32) [4]Vec3 {
        var normal = Vec3.new(-1 * (endPos.y() - startPos.y()), endPos.x() - startPos.x(), 0).norm();
        normal = normal.scale(width / 2);

        const vertices = [_]Vec3{
            startPos.add(normal), startPos.sub(normal), endPos.sub(normal), endPos.add(normal),
        };

        return vertices;
    }

    pub fn generateVertices(drawable: *Drawable) !void {
        const topLeft = drawable.vertices.items[0];
        const bottomLeft = drawable.vertices.items[1];
        const bottomRight = drawable.vertices.items[2];
        const topRight = drawable.vertices.items[3];

        try drawable.appendVec3(topLeft);
        try drawable.appendColor(drawable.color);
        try drawable.appendVec3(bottomLeft);
        try drawable.appendColor(drawable.color);
        try drawable.appendVec3(topRight);
        try drawable.appendColor(drawable.color);

        try drawable.appendVec3(bottomLeft);
        try drawable.appendColor(drawable.color);
        try drawable.appendVec3(bottomRight);
        try drawable.appendColor(drawable.color);
        try drawable.appendVec3(topRight);
        try drawable.appendColor(drawable.color);
    }
};

pub const Polygon = struct {
    base: Drawable,

    pub fn init(allocator: std.mem.Allocator, vertices: []const Vec3, color: Vec4) error{OutOfMemory}!Polygon {
        var polygon = Polygon{
            .base = try Drawable.init(allocator, .TriangleMesh, .Polygon, vertices),
        };
        polygon.base.setColor(color);

        return polygon;
    }

    pub fn deinit(self: *Polygon) void {
        self.base.deinit();
    }

    pub fn generateVertices(drawable: *Drawable) !void {
        const firstVertex = drawable.vertices.items[0];

        // Generate a fan of triangles with the given vertices
        for (drawable.vertices.items, 0..) |v1, i| {
            if (i == drawable.vertices.items.len - 1) break;

            const v2 = drawable.vertices.items[i + 1];
            try drawable.appendVec3(firstVertex);
            try drawable.appendColor(drawable.color);

            try drawable.appendVec3(v1);
            try drawable.appendColor(drawable.color);

            try drawable.appendVec3(v2);
            try drawable.appendColor(drawable.color);
        }
    }
};
