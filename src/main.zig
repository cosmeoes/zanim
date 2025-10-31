const std = @import("std");
const zig_manim = @import("zig_manim");
const c = @cImport({
    @cDefine("GLFW_INCLUDE_NONE", "1");
    @cInclude("glad/glad.h");
    @cInclude("GLFW/glfw3.h");
});

const vertexShaderSource: [*c]const u8 = 
    \\ #version 330 core
    \\ layout (location = 0) in vec3 aPos;
    \\ void main() 
    \\ {
    \\  gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
    \\ }
;

const fragmentShaderSource: [*c]const u8 = 
    \\ #version 330 core
    \\ out vec4 FragColor;
    \\ void main() 
    \\ {
    \\  FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);
    \\ }
;

const WindowSize = struct {
    pub const width: u32 = 800;
    pub const height: u32 = 600;
};

pub fn framebuffer_size_callback(_: ?*c.GLFWwindow, width: c_int, height: c_int ) callconv(.c) void {
    std.log.info("Resize callback: {d}, {d}", .{width, height});
}
pub fn main() !void {
    // Prints to stderr, ignoring potential errors.
    //glfw.setErrorCallback(errorCallback);
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

    // vertex shader
    const vertexShader = c.glCreateShader(c.GL_VERTEX_SHADER);
    c.glShaderSource(vertexShader, 1, &vertexShaderSource, null);
    c.glCompileShader(vertexShader);
    // check for compilation errors
    var success: c_int = undefined;
    var infoLog: [512] u8 = undefined;
    c.glGetShaderiv(vertexShader, c.GL_COMPILE_STATUS, &success);
    if (success != c.GL_TRUE) {
        c.glGetShaderInfoLog(vertexShader, 512, null, &infoLog[0]);
        std.log.err("Error: vertex shader compilation failed: {s}" , .{infoLog});
        return;
    }

    // fragment Shader
    const fragmentShader = c.glCreateShader(c.GL_FRAGMENT_SHADER);
    c.glShaderSource(fragmentShader, 1, &fragmentShaderSource, null);
    c.glCompileShader(fragmentShader);
    c.glGetShaderiv(fragmentShader, c.GL_COMPILE_STATUS, &success);
    if (success != c.GL_TRUE) {
        c.glGetShaderInfoLog(fragmentShader, 512, null, &infoLog);
        std.log.err("Error: fragment shader compilation failed: {s}" , .{infoLog});
        return;
    }

    const shaderProgram = c.glCreateProgram();
    c.glAttachShader(shaderProgram, vertexShader);
    c.glAttachShader(shaderProgram, fragmentShader);
    c.glLinkProgram(shaderProgram);

    c.glGetProgramiv(shaderProgram, c.GL_LINK_STATUS, &success);
    if (success != c.GL_TRUE) {
        c.glGetProgramInfoLog(shaderProgram, 512, null, &infoLog);
        std.log.err("Error: program linking failed: {s}", .{infoLog});
        return;
    }
    c.glDeleteShader(vertexShader);
    c.glDeleteShader(fragmentShader);
    defer c.glDeleteProgram(shaderProgram);

    const vertices = [_]f32{
        0.5,  0.5, 0.0,  // top right
        0.5, -0.5, 0.0,  // bottom right
       -0.5, -0.5, 0.0,  // bottom left
       -0.5,  0.5, 0.0,  // top left 
    };

    const indices = [_]c_int{
        0, 1, 3,  // first triangle
        1, 2, 3 // second triangle
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

    c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, EBO);
    c.glBufferData(c.GL_ELEMENT_ARRAY_BUFFER, indices.len * @sizeOf(c_int), @constCast(&indices), c.GL_STATIC_DRAW);

    c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, 3 * @sizeOf(f32), null);
    c.glEnableVertexAttribArray(0);

    // note that this is allowed, the call to glVertexAttribPointer registered VBO as the vertex attribute's bound vertex buffer object so afterwards we can safely unbind
    c.glBindBuffer(c.GL_ARRAY_BUFFER, 0);

    // remember: do NOT unbind the EBO while a VAO is active as the bound element buffer object IS stored in the VAO; keep the EBO bound.
    //glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    
    c.glBindVertexArray(0);

    // Wait for the user to close the window.
    while (c.glfwWindowShouldClose(window) != c.GLFW_TRUE) {

        c.glClearColor(0.2, 0.3, 0.3, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT);

        c.glUseProgram(shaderProgram);
        c.glBindVertexArray(VAO);
        c.glDrawElements(c.GL_TRIANGLES, 6, c.GL_UNSIGNED_INT, null);

        c.glfwSwapBuffers(window);
        c.glfwPollEvents();
    }
}
