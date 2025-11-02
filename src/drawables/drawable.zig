const std = @import("std");
const za = @import("zalgebra");
const Vec3 = za.Vec3; 
const Mat4 = za.Mat4; 
const geometry = @import("utils/geometry.zig");
const Transform = @import("utils/transform.zig").Transform;
const drawableTypes = @import("drawable_types.zig");

pub const Drawable = struct {
    vertex_mode: geometry.VertexMode ,
    transform: Transform,
    // Tranfrom used for animations
    anim_transform: Transform,
    // Represents the points that define the shape
    vertices: std.ArrayList(Vec3),
    color: Vec3,
    // Represents the data that will be used for rendering
    vertex_buffer: std.ArrayList(f32),
    drawableType: drawableTypes.DrawableType,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, mode: geometry.VertexMode, drawableType: drawableTypes.DrawableType, vertices: []const Vec3) !Drawable {
        var drawable = Drawable{
            .drawableType = drawableType,
            .vertices = .empty,
            .vertex_mode = mode,
            .vertex_buffer = .empty,
            .transform = Transform.init(),
            .anim_transform = Transform.init(),
            .color  = Vec3.new(1, 1, 1),
            .allocator = allocator,
        };

        try drawable.vertices.appendSlice(allocator, vertices);
        return drawable;
    }

    pub fn setColor(self: *Drawable, color: Vec3) void {
        self.color = color;
    }

    pub fn deinit(self: *Drawable) void {
        self.vertex_buffer.deinit(self.allocator);
        self.vertices.deinit(self.allocator);
    }

    pub fn translate(self: *Drawable, pos: za.Vec3) void {
        self.transform.translate(pos);
    }

    pub fn rotate(self: *Drawable, angle: f32, axis: za.Vec3) void {
        self.transform.rotate(angle, axis);
    }

    pub fn scale(self: *Drawable, scalar: f32) void {
        self.transform.scale(scalar);
    }

    pub fn getTransformMatrix(self: Drawable) za.Mat4 {
        const baseMatrix = self.transform.toMatrix();
        const animMatrix = self.anim_transform.toMatrix();
        return animMatrix.mul(baseMatrix);
    }

    pub fn clearVertexBuffer(self: *Drawable) void {
        self.vertex_buffer.clearRetainingCapacity();
    }

    pub fn appendVec3(self: *Drawable, value: Vec3) !void {
        try self.vertex_buffer.append(self.allocator, value.x());
        try self.vertex_buffer.append(self.allocator, value.y());
        try self.vertex_buffer.append(self.allocator, value.z());
    }

    pub fn generateVertexBuffer(self: *Drawable) !void {
        self.clearVertexBuffer();
        try drawableTypes.generateVerticesUsingType(self);
    }
};
