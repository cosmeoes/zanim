const std = @import("std");
const zig_manim = @import("zig_manim");
const c = @cImport({
    @cDefine("GLFW_INCLUDE_NONE", "1");
    @cInclude("glad/glad.h");
    @cInclude("GLFW/glfw3.h");
});
const za = @import("zalgebra");
const Vec3 = za.Vec3;
const Mat4 = za.Mat4;
const Shader = @import("render/shader.zig").Shader;
const Camera = @import("render/camera.zig").Camera;
const Line = @import("drawables/line.zig").Line;
const Polygon = @import("drawables/polygon.zig").Polygon;
const Render = @import("render/render.zig").Renderer;
const Drawable = @import("drawables/drawable.zig").Drawable;
const assert = std.debug.assert;

const WindowSize = struct {
    pub var width: c_int = 800;
    pub var height: c_int = 600;
};

const PreviewState = struct {
    pub var camara_move: bool = false;
};

const InputState = struct {
    const KEY_COUNT = c.GLFW_KEY_LAST + 1;
    pub var key_is_down: [KEY_COUNT]bool = .{false} ** KEY_COUNT;
    pub var key_was_down: [KEY_COUNT]bool = .{false} ** KEY_COUNT;

    pub fn update(key: usize, newValue: bool) void {
        assert(key >= 0);
        assert(key < KEY_COUNT);

        key_was_down[key] = key_is_down[key];
        key_is_down[key] = newValue;
    }

    pub fn justPressed(key: usize) bool {
        assert(key >= 0);
        assert(key < KEY_COUNT);
        return key_is_down[key] and !key_was_down[key];
    }

    pub fn isPressed(key: usize) bool {
        assert(key >= 0);
        assert(key < KEY_COUNT);
        return key_is_down[key];
    }
};

pub fn framebuffer_size_callback(_: ?*c.GLFWwindow, width: c_int, height: c_int ) callconv(.c) void {
    WindowSize.width = width;
    WindowSize.height = height;
    c.glViewport(0, 0, width, height);
}

pub fn error_callback(errCode: c_int, message: [*c]const u8)  callconv(.c) void {
    std.log.err("GLFW error: {d}, {s}", .{errCode, message});
}

var firstMouse = true;
var lastX: f64 = 800.0 / 2.0;
var lastY: f64 = 600.0 / 2.0;

pub fn mouse_callback(_: ?*c.GLFWwindow, xpos: f64, ypos: f64) callconv(.c) void {
   if (firstMouse) {
        lastX = xpos;
        lastY = ypos;
        firstMouse = false;
    }
  
    const xoffset = xpos - lastX;
    const yoffset = lastY - ypos; 
    lastX = xpos;
    lastY = ypos;

    if (!PreviewState.camara_move) return;
    camera.processMovement(@floatCast(xoffset), @floatCast(yoffset));
}

var camera: Camera = undefined;
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
     defer _ = gpa.deinit();
     const allocator = gpa.allocator();
     Drawable.setUp(allocator);

    if (c.glfwInit() != c.GLFW_TRUE) {
        return;
    }
    defer c.glfwTerminate();

    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 3);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 3);
    c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);

    const window = c.glfwCreateWindow(WindowSize.width, WindowSize.height, "zig_manim", null, null);
    if (window == null) {
        return;
    }
    defer c.glfwDestroyWindow(window);

    c.glfwMakeContextCurrent(window);
    _ = c.glfwSetFramebufferSizeCallback(window, framebuffer_size_callback);
    c.glfwSwapInterval(1);

    if (c.gladLoadGLLoader(@ptrCast(&c.glfwGetProcAddress)) == 0)
    {
        std.log.err("Failed to initialize GLAD", .{});
        return;
    }
    _ = c.glfwSetErrorCallback(error_callback);
    _ = c.glfwSetCursorPosCallback(window, mouse_callback);
    const ourShader = try Shader.new("shaders/vertex.vs", "shaders/frag.fs");
    defer ourShader.deinit();

    c.glBindVertexArray(0);
    var deltaTime: f32 = 0.0;	// Time between current frame and last frame
    var lastFrame: f32 = 0.0; // Time of last frame
    camera = Camera.new(Vec3.new(0.0, 0.0, 3.0));
    var render = Render.new(ourShader);
    var line = try Line.new(Vec3.new(-0.5, -0.5, -0.5), Vec3.new(0.5, 0.5, 0.5), Vec3.new(1, 0, 0));
    defer line.base.deinit();

    var triangle = try Polygon.new(
        &[_]Vec3{
            Vec3.new(0, 1, 0),
            Vec3.new(1, 0, 0),
            Vec3.new(-1, 0, 0),
        },
        Vec3.new(1, 1, 0),
    );
    defer triangle.base.deinit();
    var rectangle = try Polygon.new(
        &[_]Vec3{ 
            Vec3.new(5, 1, 0),
            Vec3.new(5, 0, 0),
            Vec3.new(-5, 0, 0),
            Vec3.new(-5, 1, 0),
        },
        Vec3.new(0, 1, 0),
    );
    defer rectangle.base.deinit();

    while (c.glfwWindowShouldClose(window) != c.GLFW_TRUE) {
        updateInput(window);
        // render.clear(0.2, 0.3, 0.3);
        render.clear(0, 0, 0);

        const currentFrame: f32 = @floatCast(c.glfwGetTime());
        deltaTime = currentFrame - lastFrame;
        lastFrame = currentFrame;

        if (InputState.justPressed(@intCast(c.GLFW_KEY_C))) {
            PreviewState.camara_move = !PreviewState.camara_move;
            if (PreviewState.camara_move) {
                c.glfwSetInputMode(window, c.GLFW_CURSOR, c.GLFW_CURSOR_HIDDEN);
            } else {
                c.glfwSetInputMode(window, c.GLFW_CURSOR, c.GLFW_CURSOR_NORMAL);
            }
        }

        if (PreviewState.camara_move) {
            if (InputState.isPressed(c.GLFW_KEY_W)) {
                camera.moveFoward(deltaTime);
            }
            if (InputState.isPressed(c.GLFW_KEY_S)) {
                camera.moveBack(deltaTime);
            }
            if (InputState.isPressed(c.GLFW_KEY_A)) {
                camera.moveLeft(deltaTime);
            }
            if (InputState.isPressed(c.GLFW_KEY_D)) {
                camera.moveRight(deltaTime);
            }
        }

        const projection = za.perspective(45.0, @as(f32, @floatFromInt(WindowSize.width)) / @as(f32, @floatFromInt(WindowSize.height)), 0.1, 100.0);
        render.setViewMatrix(camera.viewMatrix());
        render.setProjectionMatrix(projection);

        c.glEnable(c.GL_DEPTH_TEST);

        const angle: f32 = @floatCast(c.glfwGetTime()*50);
        line.base.rotate(angle, Vec3.new(1.0, 0.3, 0.5));
        render.setModelMatrix(line.base.getTransformMatrix());
        render.drawDrawable(line.base);

        triangle.base.scale(std.math.sin(za.toRadians(angle)));
        render.setModelMatrix(triangle.base.getTransformMatrix());
        render.drawDrawable(triangle.base);

        rectangle.base.translate(Vec3.new(-1, -5, -1));
        rectangle.base.rotate(angle, Vec3.new(0, 0, 1));
        render.setModelMatrix(rectangle.base.getTransformMatrix());
        render.drawDrawable(rectangle.base);

        c.glfwSwapBuffers(window);
        c.glfwPollEvents();
    }
}

pub fn updateInput(window: ?*c.GLFWwindow) void {
    // --- 1. Loop over Printable Keys (ASCII-based, e.g., A-Z, 0-9, etc.) ---
    // Range is typically GLFW_KEY_SPACE (32) up to GLFW_KEY_GRAVE_ACCENT (96)
    for (32..97) |keyCode| {
        InputState.update(keyCode, c.glfwGetKey(window, @intCast(keyCode)) == c.GLFW_PRESS);
    }

    // --- 2. Loop over Special Keys (e.g., F1-F12, Arrows, Escape, etc.) ---
    // Range is typically GLFW_KEY_ESCAPE (256) up to GLFW_KEY_LAST (348)
    for (256..InputState.KEY_COUNT) |keyCode| {
        InputState.update(keyCode, c.glfwGetKey(window, @intCast(keyCode)) == c.GLFW_PRESS);
    }
}
