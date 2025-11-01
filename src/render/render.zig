const Shader = @import("shader.zig").Shader;
const c = @cImport({
    @cInclude("glad/glad.h");
});
const Camera = @import("camera.zig").Camera;
const za = @import("zalgebra");
const std = @import("std");
const geometry = @import("../drawables/utils/geometry.zig");
const Mat4 = za.Mat4; 

pub const Renderer = struct {
    shader: Shader,
    vao: c_uint,
    vbo: c_uint,
    projection_matrix: Mat4,
    view_matrix: Mat4,
    model_matrix: Mat4,
    pub fn new(shader: Shader) Renderer {
        var vao: c_uint = undefined;
        var vbo: c_uint = undefined;
        c.glGenVertexArrays(1, &vao);
        c.glGenBuffers(1, &vbo);

        const projection = za.perspective(45.0, 1, 0.1, 100.0);
        return Renderer {
            .shader = shader,
            .vao = vao,
            .vbo = vbo,
            .projection_matrix = projection,
            .view_matrix = Mat4.identity(),
            .model_matrix = Mat4.identity(),
        };
    }

    pub fn setAspectRatio(self: *Renderer, aspectRatio: f64) void {
        self.aspectRatio = aspectRatio;
        self.projection_matrix = za.perspective(45.0, self.aspectRatio, 0.1, 100.0);
    }

    pub fn deinit(self: *Renderer) void {
        c.glDeleteVertexArrays(1, &self.vao);
        c.glDeleteBuffers(1, &self.vbo);
        self.shader.deinit();
    }

    pub fn clear(_: Renderer, r: f32, g: f32, b: f32) void {
        c.glClearColor(r, g, b, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT);
    }

    pub fn setViewMatrix(self: *Renderer, viewMatrix: Mat4) void {
        self.view_matrix = viewMatrix;
    }

    pub fn setProjectionMatrix(self: *Renderer, projectionMatrix: Mat4) void {
        self.projection_matrix = projectionMatrix;
    }

    pub fn setModelMatrix(self: *Renderer, modelMatrix: Mat4) void {
        self.model_matrix = modelMatrix;
    }

    pub fn resetModelMatrix(self: *Renderer) void {
        self.model_matrix = Mat4.identity();
    }

    pub fn draw(self: *Renderer, vertices: []const f32, vertexMode: geometry.VertexMode) void {
        if (vertices.len == 0) return;

        self.shader.use();
        self.shader.setMat4("view", self.view_matrix);
        self.shader.setMat4("projection", self.projection_matrix);
        self.shader.setMat4("model", self.model_matrix);

        c.glBindVertexArray(self.vao);
        c.glBindBuffer(c.GL_ARRAY_BUFFER, self.vbo);
        c.glBufferData(
            c.GL_ARRAY_BUFFER,
            @intCast(vertices.len * @sizeOf(f32)),
            vertices.ptr,
            c.GL_DYNAMIC_DRAW,
        );

        c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, 6 * @sizeOf(f32), null);
        c.glEnableVertexAttribArray(0);
        c.glVertexAttribPointer(1, 3, c.GL_FLOAT, c.GL_FALSE, 6 * @sizeOf(f32), @ptrFromInt(3 * @sizeOf(f32)));
        c.glEnableVertexAttribArray(1);

        c.glDrawArrays(primitiveToGLMode(vertexMode), 0, @intCast(vertices.len));
        c.glBindVertexArray(0);
        self.resetModelMatrix();
    }

    fn primitiveToGLMode(mode: geometry.VertexMode) c_uint {
        return switch (mode) {
            .LineSegments => c.GL_LINES,
            .LinePath => c.GL_LINE_STRIP,
            .LineLoop => c.GL_LINE_LOOP,
            .TriangleMesh => c.GL_TRIANGLES,
            .Points => c.GL_POINTS,
        };
    }
};
