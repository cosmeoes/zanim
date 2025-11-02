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


    var global_allocator: std.mem.Allocator = undefined;
    pub fn setUp(allocator: std.mem.Allocator) void {
        global_allocator = allocator;
    }

    pub fn getAllocator() std.mem.Allocator {
        return global_allocator;
    }

    pub fn init(mode: geometry.VertexMode, drawableType: drawableTypes.DrawableType, vertices: []const Vec3) !Drawable {
        var drawable = Drawable{
            .drawableType = drawableType,
            .vertices = .empty,
            .vertex_mode = mode,
            .vertex_buffer = .empty,
            .transform = Transform.init(),
            .anim_transform = Transform.init(),
            .color  = Vec3.new(1, 1, 1),
        };

        try drawable.vertices.appendSlice(global_allocator, vertices);
        return drawable;
    }

    pub fn setColor(self: *Drawable, color: Vec3) void {
        self.color = color;
    }

    pub fn deinit(self: *Drawable) void {
        self.vertex_buffer.deinit(global_allocator);
        self.vertices.deinit(global_allocator);
    }

    pub fn translate(self: *Drawable, pos: za.Vec3) void {
        self.transform.position = pos;
    }

    pub fn rotate(self: *Drawable, angle: f32, axis: za.Vec3) void {
        // the rotation gets applied around the world origin, insted of the
        // objects own center, (when you translate the object).
        // This will cause issues in the future but it's fine for now.
        self.transform.rotation = za.Quat.fromAxis(angle, axis);
    }

    pub fn scale(self: *Drawable, scalar: f32) void {
        self.transform.scale = za.Vec3.new(1, 1, 1).scale(scalar);
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
        try self.vertex_buffer.append(Drawable.getAllocator(), value.x());
        try self.vertex_buffer.append(Drawable.getAllocator(), value.y());
        try self.vertex_buffer.append(Drawable.getAllocator(), value.z());
    }

    pub fn generateVertexBuffer(self: *Drawable) !void {
        self.clearVertexBuffer();
        try drawableTypes.generateVerticesUsingType(self);
    }
};
