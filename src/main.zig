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
const Shader = @import("shader.zig").Shader;
const Camera = @import("camera.zig").Camera;

const WindowSize = struct {
    pub var width: c_int = 800;
    pub var height: c_int = 600;
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

    camera.processMovement(@floatCast(xoffset), @floatCast(yoffset));
}

// var cameraPos = Vec3.new(0.0, 0.0, 3.0);
// var cameraFront = Vec3.new(0, 0, -1);
// const cameraUp = Vec3.up(); 

var camera: Camera = undefined;
pub fn main() !void {
    if (c.glfwInit() != c.GLFW_TRUE) {
        return;
    }
    defer c.glfwTerminate();

    //const GLSL_VERSION = "#version 130";
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 3);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 3);
    c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);

    const window = c.glfwCreateWindow(WindowSize.width, WindowSize.height, "example_glfw_opengl3", null, null);
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

    defer c.glDeleteProgram(ourShader.id);

     const vertices = [_]f32 {
        -0.5, -0.5, -0.5,  0.0, 0.0, 0.0,
        0.5, -0.5, -0.5,  1.0, 0.0, 0.0,
        0.5,  0.5, -0.5,  1.0, 1.0, 0.0,
        0.5,  0.5, -0.5,  1.0, 1.0, 0.0,
        -0.5,  0.5, -0.5,  0.0, 1.0, 0.0,
        -0.5, -0.5, -0.5,  0.0, 0.0, 0.0,

        -0.5, -0.5,  0.5,  0.0, 0.0, 0.0,
        0.5, -0.5,  0.5,  1.0, 0.0, 0.0,
        0.5,  0.5,  0.5,  1.0, 1.0, 0.0,
        0.5,  0.5,  0.5,  1.0, 1.0, 0.0,
        -0.5,  0.5,  0.5,  0.0, 1.0, 0.0,
        -0.5, -0.5,  0.5,  0.0, 0.0, 0.0,

        -0.5,  0.5,  0.5,  1.0, 0.0, 0.0,
        -0.5,  0.5, -0.5,  1.0, 1.0, 0.0,
        -0.5, -0.5, -0.5,  0.0, 1.0, 0.0,
        -0.5, -0.5, -0.5,  0.0, 1.0, 0.0,
        -0.5, -0.5,  0.5,  0.0, 0.0, 0.0,
        -0.5,  0.5,  0.5,  1.0, 0.0, 0.0,

        0.5,  0.5,  0.5,  1.0, 0.0, 0.0,
        0.5,  0.5, -0.5,  1.0, 1.0, 0.0,
        0.5, -0.5, -0.5,  0.0, 1.0, 0.0,
        0.5, -0.5, -0.5,  0.0, 1.0, 0.0,
        0.5, -0.5,  0.5,  0.0, 0.0, 0.0,
        0.5,  0.5,  0.5,  1.0, 0.0, 0.0,

        -0.5, -0.5, -0.5,  0.0, 1.0, 0.0,
        0.5, -0.5, -0.5,  1.0, 1.0, 0.0,
        0.5, -0.5,  0.5,  1.0, 0.0, 0.0,
        0.5, -0.5,  0.5,  1.0, 0.0, 0.0,
        -0.5, -0.5,  0.5,  0.0, 0.0, 0.0,
        -0.5, -0.5, -0.5,  0.0, 1.0, 0.0,

        -0.5,  0.5, -0.5,  0.0, 1.0, 0.0,
        0.5,  0.5, -0.5,  1.0, 1.0, 0.0,
        0.5,  0.5,  0.5,  1.0, 0.0, 0.0,
        0.5,  0.5,  0.5,  1.0, 0.0, 0.0,
        -0.5,  0.5,  0.5,  0.0, 0.0, 0.0,
        -0.5,  0.5, -0.5,  0.0, 1.0, 0.0
    };

    const indices = [_]c_int{
        0, 1, 3,  // first triangle
        1, 2, 3 // second triangle
    };

    const cubePositions = [_]Vec3 {
        Vec3.new( 0.0,  0.0,  0.0),
        Vec3.new( 2.0,  5.0, -15.0),
        Vec3.new(-1.5, -2.2, -2.5),
        Vec3.new(-3.8, -2.0, -12.3),
        Vec3.new( 2.4, -0.4, -3.5),
        Vec3.new(-1.7,  3.0, -7.5),
        Vec3.new( 1.3, -2.0, -2.5),
        Vec3.new( 1.5,  2.0, -2.5),
        Vec3.new( 1.5,  0.2, -1.5),
        Vec3.new(-1.3,  1.0, -1.5)
    };

    var VAO: c_uint = undefined;
    var VBO: c_uint = undefined;
    var EBO: c_uint = undefined;
    c.glGenVertexArrays(1, &VAO);
    c.glGenBuffers(1, &VBO);
    c.glGenBuffers(1, &EBO);

    c.glBindVertexArray(VAO);
    c.glBindBuffer(c.GL_ARRAY_BUFFER, VBO);
    c.glBufferData(c.GL_ARRAY_BUFFER, vertices.len * @sizeOf(f32), @constCast(&vertices), c.GL_STATIC_DRAW);

    c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, 6 * @sizeOf(f32), null);
    c.glEnableVertexAttribArray(0);
    c.glVertexAttribPointer(1, 3, c.GL_FLOAT, c.GL_FALSE, 6 * @sizeOf(f32), @ptrFromInt(3 * @sizeOf(f32)));
    c.glEnableVertexAttribArray(1);

    c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, EBO);
    c.glBufferData(c.GL_ELEMENT_ARRAY_BUFFER, indices.len * @sizeOf(c_int), @constCast(&indices), c.GL_STATIC_DRAW);

    // note that this is allowed, the call to glVertexAttribPointer registered VBO as the vertex attribute's bound vertex buffer object so afterwards we can safely unbind
    c.glBindBuffer(c.GL_ARRAY_BUFFER, 0);

    c.glfwSetInputMode(window, c.GLFW_CURSOR, c.GLFW_CURSOR_DISABLED);
    // remember: do NOT unbind the EBO while a VAO is active as the bound element buffer object IS stored in the VAO; keep the EBO bound.
    //glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    
    c.glBindVertexArray(0);
    //trans = trans.scale(za.Vec3.new(0.5, 0.5, 0.5));
    // Wait for the user to close the window.
    var deltaTime: f32 = 0.0;	// Time between current frame and last frame
    var lastFrame: f32 = 0.0; // Time of last frame
    camera = Camera.new(Vec3.new(0.0, 0.0, 3.0));
    while (c.glfwWindowShouldClose(window) != c.GLFW_TRUE) {
        c.glClearColor(0.2, 0.3, 0.3, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT);
        const currentFrame: f32 = @floatCast(c.glfwGetTime());
        deltaTime = currentFrame - lastFrame;
        lastFrame = currentFrame;  

        ourShader.use();
        if (c.glfwGetKey(window, c.GLFW_KEY_W) == c.GLFW_PRESS) {
            camera.moveFoward(deltaTime);
        }
        if (c.glfwGetKey(window, c.GLFW_KEY_S) == c.GLFW_PRESS) {
            camera.moveBack(deltaTime);
        }
        if (c.glfwGetKey(window, c.GLFW_KEY_A) == c.GLFW_PRESS) {
            camera.moveLeft(deltaTime);
        }
        if (c.glfwGetKey(window, c.GLFW_KEY_D) == c.GLFW_PRESS) {
            camera.moveRight(deltaTime);
        }

        if (c.glfwGetKey(window, c.GLFW_KEY_ESCAPE) == c.GLFW_PRESS) {
            c.glfwSetInputMode(window, c.GLFW_CURSOR, c.GLFW_CURSOR_NORMAL);
        }

        const view = camera.viewMatrix(); 
        const projection = za.perspective(45.0, @as(f32, @floatFromInt(WindowSize.width)) / @as(f32, @floatFromInt(WindowSize.height)), 0.1, 100.0);
        ourShader.setMat4("view", view);
        ourShader.setMat4("projection", projection);

        c.glEnable(c.GL_DEPTH_TEST);
        c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT);

        c.glBindVertexArray(VAO);
        for (cubePositions, 0..) |position, i| {
            var model = Mat4.identity();
            model = model.translate(position);
            var angle: f32 = 20.0 * @as(f32, @floatFromInt(i));
            if (i%3 == 0) {
                angle = @floatCast(c.glfwGetTime()*50);
            }
            model = model.rotate(angle, Vec3.new(1.0, 0.3, 0.5));
            ourShader.setMat4("model", model);
            c.glDrawArrays(c.GL_TRIANGLES, 0, 36);
        }

        c.glfwSwapBuffers(window);
        c.glfwPollEvents();
    }
}
