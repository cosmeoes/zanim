const std = @import("std");
const Scene = @import("../scene.zig").Scene;
const c = @cImport({
    @cDefine("GLFW_INCLUDE_NONE", "1");
    @cInclude("glad/glad.h");
    @cInclude("GLFW/glfw3.h");
});
const Shader = @import("../render/shader.zig").Shader;
const Camera = @import("../render/camera.zig").Camera;
const Renderer = @import("../render/render.zig").Renderer;
const za = @import("zalgebra");
const Vec3 = za.Vec3;
const assert = std.debug.assert;

pub const PreviewConfig = struct {
    width: u32 = 1280,
    height: u32 = 720,
    title: []const u8 = "Animation Preview"
};

// Global camera because I don't want to fix it right now
// should work for while, maybe forever.
// Probs fixable with a hashmap from window -> Previewer instance
var g_first_mouse: bool = true;
var g_last_mouse_x: f64 = 0.0;
var g_last_mouse_y: f64 = 0.0;
var g_camera_move: bool = false;

var camera = Camera.new(Vec3.new(0.0, 0.0, 10.0));
const g_camera: *Camera = &camera;

pub const Previewer = struct {
    allocator: std.mem.Allocator,
    config: PreviewConfig,
    window: ?*c.GLFWwindow,
    shader: *Shader,
    renderer: Renderer,
    input_state: InputState,

    pub fn init(allocator: std.mem.Allocator, config: PreviewConfig) !Previewer {

        if (c.glfwInit() != c.GLFW_TRUE) {
            return error.GlfwInitFailed;
        }

        c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 3);
        c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 3);
        c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);

        const window = c.glfwCreateWindow(@intCast(config.width), @intCast(config.height), config.title.ptr, null, null);
        if (window == null) {
            c.glfwTerminate();
            return error.WindowCreationFailed;
        }

        c.glfwMakeContextCurrent(window);
        _ = c.glfwSetFramebufferSizeCallback(window, framebuffer_size_callback);
        c.glfwSwapInterval(1);

        if (c.gladLoadGLLoader(@ptrCast(&c.glfwGetProcAddress)) == 0) {
            return error.GLADLoadingFailed;
        }
        _ = c.glfwSetErrorCallback(error_callback);
        _ = c.glfwSetCursorPosCallback(window, mouse_callback);
        var shader = try Shader.new("shaders/vertex.vs", "shaders/frag.fs");

        // Camera
        g_last_mouse_x = @as(f64, @floatFromInt(config.width)) / 2.0;
        g_last_mouse_y = @as(f64, @floatFromInt(config.height)) / 2.0;

        return .{
            .allocator = allocator,
            .config = config,
            .window = window,
            .shader = &shader,
            .renderer = Renderer.new(shader),
            .input_state = InputState.init(),
        };
    }

    pub fn deinit(self: *Previewer) void {
        if (self.window) |window| c.glfwDestroyWindow(window);
        self.shader.deinit();
        c.glfwTerminate();
    }

    pub fn run(self: *Previewer, scene: *Scene) !void {
        var delta_time: f32 = 0.0;
        var last_frame: f32 = 0.0;

        while (c.glfwWindowShouldClose(self.window) != c.GLFW_TRUE) {
            const current_frame: f32 = @floatCast(c.glfwGetTime());
            delta_time = current_frame - last_frame;
            last_frame = current_frame;

            self.processInput(delta_time);

            scene.update(delta_time);

            try self.render(scene);

            c.glfwSwapBuffers(self.window);
            c.glfwPollEvents();
        }
    }

    fn processInput(self: *Previewer, delta_time: f32) void {
        self.input_state.update(self.window.?);

        // Toggle camera mode
        if (self.input_state.justPressed(c.GLFW_KEY_C)) {
            g_camera_move = !g_camera_move;
            if (g_camera_move) {
                c.glfwSetInputMode(self.window, c.GLFW_CURSOR, c.GLFW_CURSOR_DISABLED);
            } else {
                c.glfwSetInputMode(self.window, c.GLFW_CURSOR, c.GLFW_CURSOR_NORMAL);
            }
        }

        // Camera movement
        if (g_camera_move) {
            if (self.input_state.isPressed(c.GLFW_KEY_W)) g_camera.moveFoward(delta_time);
            if (self.input_state.isPressed(c.GLFW_KEY_S)) g_camera.moveBack(delta_time);
            if (self.input_state.isPressed(c.GLFW_KEY_A)) g_camera.moveLeft(delta_time);
            if (self.input_state.isPressed(c.GLFW_KEY_D)) g_camera.moveRight(delta_time);
        }
    }

    fn render(self: *Previewer, scene: *Scene) !void {
        self.renderer.clear(0, 0, 0);
        Renderer.enableDepthTest();

        var width: c_int = undefined;
        var height: c_int = undefined;
        c.glfwGetFramebufferSize(self.window, &width, &height);

        const aspect = @as(f32, @floatFromInt(width)) / @as(f32, @floatFromInt(height));
        const projection = za.perspective(45.0, aspect, 0.1, 100.0);

        self.renderer.setViewMatrix(g_camera.viewMatrix());
        self.renderer.setProjectionMatrix(projection);

        for (scene.objects.items) |object| {
            try object.generateVertexBuffer();
            self.renderer.drawDrawable(object.*);
        }
    }

    pub fn framebuffer_size_callback(_: ?*c.GLFWwindow, width: c_int, height: c_int ) callconv(.c) void {
        c.glViewport(0, 0, width, height);
    }

    pub fn error_callback(errCode: c_int, message: [*c]const u8)  callconv(.c) void {
        std.log.err("GLFW error: {d}, {s}", .{errCode, message});
    }

    pub fn mouse_callback(_: ?*c.GLFWwindow, xpos: f64, ypos: f64) callconv(.c) void {
       if (g_first_mouse) {
           g_last_mouse_x = xpos; 
           g_last_mouse_y = ypos; 
           g_first_mouse = false;
        }

        const xoffset = xpos - g_last_mouse_x;
        const yoffset = g_last_mouse_y - ypos; 
        g_last_mouse_x = xpos; 
        g_last_mouse_y = ypos; 

        if (!g_camera_move) return;
        g_camera.processMovement(@floatCast(xoffset), @floatCast(yoffset));
    }
};

const InputState = struct {
    const KEY_COUNT = c.GLFW_KEY_LAST + 1;
    key_is_down: [KEY_COUNT]bool,
    key_was_down: [KEY_COUNT]bool,

    fn init() InputState {
        return InputState{
            .key_is_down = .{false} ** KEY_COUNT,
            .key_was_down = .{false} ** KEY_COUNT,
        };
    }

    fn update(self: *InputState, window: ?*c.GLFWwindow) void {
        // Update printable keys
        for (32..97) |key| {
            self.key_was_down[key] = self.key_is_down[key];
            self.key_is_down[key] = c.glfwGetKey(window, @intCast(key)) == c.GLFW_PRESS;
        }

        // Update special keys
        for (256..KEY_COUNT) |key| {
            self.key_was_down[key] = self.key_is_down[key];
            self.key_is_down[key] = c.glfwGetKey(window, @intCast(key)) == c.GLFW_PRESS;
        }
    }

    pub fn justPressed(self: InputState, key: usize) bool {
        assert(key >= 0);
        assert(key < KEY_COUNT);
        return self.key_is_down[key] and !self.key_was_down[key];
    }

    pub fn isPressed(self: InputState, key: usize) bool {
        assert(key >= 0);
        assert(key < KEY_COUNT);
        return self.key_is_down[key];
    }
};
