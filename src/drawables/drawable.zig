const std = @import("std");
const za = @import("zalgebra");
const Vec3 = za.Vec3; 
const Mat4 = za.Mat4; 
const geometry = @import("utils/geometry.zig");
const Transform = @import("utils/transform.zig").Transform;

pub const Drawable = struct {
    vertex_mode: geometry.VertexMode ,
    transform: Transform,
    // Represents the data that will be used for rendering
    vertex_buffer: std.ArrayList(f32),

    var global_allocator: std.mem.Allocator = undefined;
    pub fn setUp(allocator: std.mem.Allocator) void {
        global_allocator = allocator;
    }

    pub fn getAllocator() std.mem.Allocator {
        return global_allocator;
    }

    pub fn init(mode: geometry.VertexMode) Drawable {
        return .{
            .vertex_mode = mode,
            .vertex_buffer = .empty,
            .transform = Transform.init(),
        };
    }

    pub fn deinit(self: *Drawable) void {
        self.vertex_buffer.deinit(global_allocator);
    }

    pub fn translate(self: *Drawable, pos: za.Vec3) void {
        self.transform.position = pos;
    }

    pub fn rotate(self: *Drawable, angle: f32, axis: za.Vec3) void {
        self.transform.rotation = za.Quat.fromAxis(angle, axis);
    }

    pub fn scale(self: *Drawable, scalar: f32) void {
        self.transform.scale = za.Vec3.new(1, 1, 1).scale(scalar);
    }

    pub fn getTransformMatrix(self: Drawable) za.Mat4 {
        return self.transform.toMatrix();
    }

    pub fn appendVec3(self: *Drawable, value: Vec3) !void {
        try self.vertex_buffer.append(Drawable.getAllocator(), value.x());
        try self.vertex_buffer.append(Drawable.getAllocator(), value.y());
        try self.vertex_buffer.append(Drawable.getAllocator(), value.z());
    }
};
