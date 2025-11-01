const std = @import("std");
const zig_manim = @import("zig_manim");
const za = @import("zalgebra");
const Vec3 = za.Vec3;
const Mat4 = za.Mat4;
const Shader = @import("render/shader.zig").Shader;
const Camera = @import("render/camera.zig").Camera;
const Line = @import("drawables/drawable_types.zig").Line;
const Polygon = @import("drawables/drawable_types.zig").Polygon;
const Render = @import("render/render.zig").Renderer;
const Drawable = @import("drawables/drawable.zig").Drawable;
const Scene = @import("scene.zig").Scene;
const Create = @import("animation/animation.zig").Create;
const Engine = @import("engine.zig").Engine;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    Drawable.setUp(allocator);
    // Initialize the library
    var manim = try Engine.init(allocator);

    // Create your scene
    var scene = try manim.createScene();
    defer scene.deinit();

    var triangle = try Polygon.new(
        &[_]Vec3{
            Vec3.new(0, 1, 0),
            Vec3.new(1, 0, 0),
            Vec3.new(-1, 0, 0),
        },
        Vec3.new(1, 1, 0),
    );
    defer triangle.base.deinit();
    var createTriangle = try Create.init(scene.allocator, &triangle.base, 1);
    defer createTriangle.deinit();
    createTriangle.fromCenter();
    try scene.add(&triangle.base);
    try scene.play(createTriangle.asAnimatable());

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
    rectangle.base.translate(Vec3.new(-1, 0, -1));
    rectangle.base.rotate(-90, Vec3.new(0, 0, 1));
    rectangle.base.scale(1.0/5.0);
    try scene.add(&rectangle.base);
    var createRectangle = try Create.init(scene.allocator, &rectangle.base, 1);
    defer createRectangle.deinit();
    try scene.play(createRectangle.asAnimatable());

    var line = try Line.new(Vec3.new(-0.5, -0.5, 0), Vec3.new(0.5, 0.5, 0), Vec3.new(1, 0, 0));
    defer line.base.deinit();
    var createLine = try Create.init(scene.allocator, &line.base, 14);
    defer createLine.deinit();
    try scene.add(&line.base);
    try scene.play(createLine.asAnimatable());

    try manim.preview(&scene, .{
        .width = 1280,
        .height = 720,
    });
}
