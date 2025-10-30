const std = @import("std");
const zig_manim = @import("zig_manim");
const c = @cImport({
    @cDefine("GLFW_INCLUDE_NONE", "1");
    @cInclude("GLFW/glfw3.h");
});

/// Default GLFW error handling callback

pub fn main() !void {
    // Prints to stderr, ignoring potential errors.
    //glfw.setErrorCallback(errorCallback);
    if (c.glfwInit() != c.GLFW_TRUE) {
        return;
    }
    defer c.glfwTerminate();

    //const GLSL_VERSION = "#version 130";
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 3);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 0);

    const window = c.glfwCreateWindow(600, 800, "example_glfw_opengl3", null, null);
    if (window == null) {
        return;
    }
    defer c.glfwDestroyWindow(window);

    c.glfwMakeContextCurrent(window);
    c.glfwSwapInterval(1);

    // Wait for the user to close the window.
    while (c.glfwWindowShouldClose(window) != c.GLFW_TRUE) {
        c.glfwSwapBuffers(window);

        // Render your graphics here

        c.glfwPollEvents();
    }
}
