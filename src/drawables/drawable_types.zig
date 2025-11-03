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
    Arrow2D,
};

pub fn generateVerticesUsingType(drawable: *Drawable) !void {
    try switch (drawable.drawableType) {
        .Line => Line.generateVertices(drawable),
        .Polygon => Polygon.generateVertices(drawable),
        .Arrow2D => Arrow2D.generateVertices(drawable),
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
            .base = try Drawable.init(allocator, .Line, &vertices),
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
        self.base.vertices.items = lineToVertices(self.startPos, self.endPos, self.width);
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
            .base = try Drawable.init(allocator, .Polygon, vertices),
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

pub const Arrow2D = struct {
    const DEFAULT_LINE_WIDTH: f32 = 0.01;
    const DEFAULT_HEAD_WIDTH: f32 = 0.1;
    const DEFAULT_HEAD_HEIGHT: f32 = 0.1;
    base: Drawable,
    // use helper methods to modify this guys
    start_pos: Vec3,
    end_pos: Vec3,
    line_width: f32,
    head_width: f32,
    head_height: f32,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, startPos: Vec3, endPos: Vec3, color: Vec4) !Arrow2D {
        const vertices = toVertices(
            startPos,
            endPos,
            DEFAULT_LINE_WIDTH,
            DEFAULT_HEAD_WIDTH,
            DEFAULT_HEAD_HEIGHT,
        );

        var arrow2d = Arrow2D{
            .base = try Drawable.init(allocator, .Arrow2D, &vertices),
            .start_pos = startPos,
            .end_pos = endPos,
            .line_width = DEFAULT_LINE_WIDTH,
            .head_width = DEFAULT_HEAD_WIDTH,
            .head_height = DEFAULT_HEAD_HEIGHT,
            .allocator = allocator,
        };

        arrow2d.base.setColor(color);
        return arrow2d;
    }

    pub fn deinit(self: *Arrow2D) void {
        self.base.deinit();
    }

    pub fn setHeadSize(self: *Arrow2D, headWidth: f32, headHeight: f32) void {
        self.head_width = headWidth;
        self.head_height = headHeight;
        self.updateVertices();
    }

    pub fn setLineWidth(self: *Arrow2D, lineWidth: f32) void {
        self.line_width = lineWidth;
        self.updateVertices();
    }

    fn updateVertices(self: *Arrow2D) void {
        self.base.vertices.clearRetainingCapacity();
        const newVertices = toVertices(self.start_pos, self.end_pos, self.line_width, self.head_width, self.head_height);
        self.base.vertices.appendSliceAssumeCapacity(&newVertices);
    }

    // Generates the vertices for the given parameters
    fn toVertices(startPos: Vec3, endPos: Vec3, lineWidth: f32, headWidth: f32, headHeight: f32) [7]Vec3 {
        const normal = Vec3.new(-1 * (endPos.y() - startPos.y()), endPos.x() - startPos.x(), 0).norm();
        const lineWidthVector = normal.scale(lineWidth / 2);
        const headWidthVector = normal.scale(headWidth / 2);
        const direction = endPos.norm();

        const vertices = [_]Vec3{
            // line
            startPos.add(lineWidthVector),
            startPos.sub(lineWidthVector),
            // So it doesnt overlap with the arrow head
            endPos.sub(lineWidthVector).sub(direction.scale(headHeight)),
            endPos.add(lineWidthVector).sub(direction.scale(headHeight)),
            // arrow head
            endPos.sub(direction.scale(headHeight)).sub(headWidthVector),
            endPos.sub(direction.scale(headHeight)).add(headWidthVector),
            endPos,
        };

        std.log.info("Vertices: {any} {any} {any} {any}", .{ vertices[0].data, vertices[1].data, vertices[2].data, vertices[3].data });
        std.log.info("Vertices: {} {any} {any} ", .{ vertices[4].data, vertices[5].data, vertices[6].data });
        return vertices;
    }

    pub fn generateVertices(drawable: *Drawable) !void {
        // Line
        try Line.generateVertices(drawable);

        // Head
        const headLeft = drawable.vertices.items[4];
        const headRight = drawable.vertices.items[5];
        const tip = drawable.vertices.items[6];
        try drawable.appendVec3(headLeft);
        try drawable.appendColor(drawable.color);
        try drawable.appendVec3(headRight);
        try drawable.appendColor(drawable.color);
        try drawable.appendVec3(tip);
        try drawable.appendColor(drawable.color);
    }
};
