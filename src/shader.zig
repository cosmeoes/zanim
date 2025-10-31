const std = @import("std");
const c = @cImport({
    @cInclude("glad/glad.h");
});
const Mat4 = @import("zalgebra").Mat4;

pub const Shader = struct {
    id: c_uint,
    pub fn build(vertexPath: []const u8, fragmentPath: []const u8) !Shader {
       // Initiate allocator
       var gpa = std.heap.GeneralPurposeAllocator(.{}){};
       defer _ = gpa.deinit();
       const alloc = gpa.allocator();

       const cwd = std.fs.cwd();
       const vertexCode = try cwd.readFileAlloc(alloc, vertexPath, 4096);
       defer alloc.free(vertexCode);

       const fragmentCode = try cwd.readFileAlloc(alloc, fragmentPath, 4096);
       defer alloc.free(fragmentCode);

       const vertexShader = c.glCreateShader(c.GL_VERTEX_SHADER);
       c.glShaderSource(vertexShader, 1, @ptrCast(&vertexCode), null);
       c.glCompileShader(vertexShader);
       // check for compilation errors
       var success: c_int = undefined;
       var infoLog: [512] u8 = undefined;
       c.glGetShaderiv(vertexShader, c.GL_COMPILE_STATUS, &success);
       if (success != c.GL_TRUE) {
           c.glGetShaderInfoLog(vertexShader, 512, null, &infoLog[0]);
           std.log.err("Error: vertex shader compilation failed: {s}" , .{infoLog});
           return error.SomethingWentWrong;
       }

       // fragment Shader
       const fragmentShader = c.glCreateShader(c.GL_FRAGMENT_SHADER);
       c.glShaderSource(fragmentShader, 1, @ptrCast(&fragmentCode), null);
       c.glCompileShader(fragmentShader);
       c.glGetShaderiv(fragmentShader, c.GL_COMPILE_STATUS, &success);
       if (success != c.GL_TRUE) {
           c.glGetShaderInfoLog(fragmentShader, 512, null, &infoLog);
           std.log.err("Error: fragment shader compilation failed: {s}" , .{infoLog});
           return error.SomethingWentWrong;
       }

       const shaderProgram = c.glCreateProgram();
       c.glAttachShader(shaderProgram, vertexShader);
       c.glAttachShader(shaderProgram, fragmentShader);
       c.glLinkProgram(shaderProgram);
       c.glGetProgramiv(shaderProgram, c.GL_LINK_STATUS, &success);
       if (success != c.GL_TRUE) {
           c.glGetProgramInfoLog(shaderProgram, 512, null, &infoLog);
           std.log.err("Error: program linking failed: {s}", .{infoLog});
           return error.SomethingWentWrong;
       }
       c.glDeleteShader(vertexShader);
       c.glDeleteShader(fragmentShader);

        return Shader{
            .id = shaderProgram,
        };
    }

    pub fn use(self: Shader) void {
        c.glUseProgram(self.id);
    }

    pub fn setMat4(self: Shader, name: []const u8, value: Mat4) void {
        c.glUniformMatrix4fv(c.glGetUniformLocation(self.id, @ptrCast(name)), 1, c.GL_FALSE, @ptrCast(&value.data[0][0]));
    }

    pub fn setBool(self: Shader, name: []const u8, value: bool) void {
        c.glUniform1i(c.glGetUniformLocation(self.id, @ptrCast(name)), @intFromBool(value));
    }

    pub fn setInt(self: Shader, name: []const u8, value: i32) void {
        c.glUniform1i(c.glGetUniformLocation(self.id, @ptrCast(name)), @intCast(value));
    }

    pub fn setFloat(self: Shader, name: []const u8, value: f32) void {
        c.glUniform1f(c.glGetUniformLocation(self.id, @ptrCast(name)), value);
    }
};

