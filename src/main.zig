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
const TransformAnim = @import("animation/animation.zig").TransformAnim;
const AnimationGroup = @import("animation/animation.zig").AnimationGroup;
const Animatable = @import("animation/animation.zig").Animatable;
const Transform = @import("drawables/utils/transform.zig").Transform;
const Engine = @import("engine.zig").Engine;
const Wait = @import("animation/animation.zig").Wait;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    Drawable.setUp(allocator);
    // Initialize the library
    var engine = try Engine.init(allocator);
    // Create your scene
    var scene = try engine.createScene();
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

    var rectangle = try Polygon.new(
        &[_]Vec3{ 
            Vec3.new(5, 2, 0),
            Vec3.new(5, 1, 0),
            Vec3.new(-5, 1, 0),
            Vec3.new(-5, 2, 0),
        },
        Vec3.new(0, 1, 0),
    );
    defer rectangle.base.deinit();
    rectangle.base.rotate(90, Vec3.new(0, 0, 1));

    var gridLines: std.ArrayList(Line) = try .initCapacity(allocator, 44);
    defer gridLines.deinit(allocator);
    var animations: std.ArrayList(TransformAnim) = try .initCapacity(allocator, 44);
    defer animations.deinit(allocator);

    var transform = Transform.init();
    transform.rotate(-34, Vec3.new(0, 0, 1));
    transform.scaleVec = Vec3.new(0.8, 0.4, 1);

    const transformTriangle = try TransformAnim.init(allocator, &triangle.base, transform, 2);
    const transformRectangle = try TransformAnim.init(allocator, &rectangle.base, transform, 2);
    animations.appendAssumeCapacity(transformTriangle);
    animations.appendAssumeCapacity(transformRectangle);

    try scene.add(&triangle.base);
    try scene.add(&rectangle.base);

    // X axis
    var i: i32 = -10;
    while (i < 11) : (i += 1) {
        const floatIndex: f32 = @floatFromInt(i);
        var color = Vec3.new(0, 1, 1);
        if (i == 0) {
            color = Vec3.new(0.5, 0.5, 0.5);
        }

        const line = try Line.new(Vec3.new(-10.0, floatIndex, 0), Vec3.new(10, floatIndex, 0), color);
        gridLines.appendAssumeCapacity(line);
        const linePtr = &gridLines.items[gridLines.items.len - 1];

        const transformAnim = try TransformAnim.init(allocator, &linePtr.base, transform, 2);
        animations.appendAssumeCapacity(transformAnim);

        try scene.add(&linePtr.base);
    }

    // Y axis
    i = -10;
    while (i < 11) : (i += 1) {
        const floatIndex: f32 = @floatFromInt(i);
        var color = Vec3.new(0, 1, 1);
        if (i == 0) {
            color = Vec3.new(0.5, 0.5, 0.5);
        }

        const line = try Line.new(Vec3.new(floatIndex, -10, 0), Vec3.new(floatIndex, 10, 0), color);

        gridLines.appendAssumeCapacity(line);
        const linePtr = &gridLines.items[gridLines.items.len - 1];

        const transformAnim = try TransformAnim.init(allocator, &linePtr.base, transform, 2);
        animations.appendAssumeCapacity(transformAnim);

        try scene.add(&linePtr.base);
    }

    const animatables: []Animatable = try allocator.alloc(Animatable, animations.items.len);
    defer allocator.free(animatables);
    for (animations.items, 0..) |*trans, index| {
        animatables[index] = trans.asAnimatable();
    }

    // Triangle grow animation
    var createTriangle = try Create.init(scene.allocator, &triangle.base, 1);
    defer createTriangle.deinit();
    createTriangle.fromCenter();

    // rectangle grow animation
    var createRectangle = try Create.init(scene.allocator, &rectangle.base, 1);
    defer createRectangle.deinit();

    // Play them in parallel
    var createGroup = try AnimationGroup.init(allocator, &[_]Animatable{
        createTriangle.asAnimatable(),
        createRectangle.asAnimatable(),
    });
    defer createGroup.deinit();
    try scene.play(createGroup.asAnimatable());

    var rotateRect = Transform.init();
    rotateRect.rotate(-90, Vec3.new(0, 0, 1));
    var rectRotate = try TransformAnim.init(allocator, &rectangle.base, rotateRect, 2);
    defer rectRotate.deinit();
    try scene.play(rectRotate.asAnimatable());

    // Wait 2 seconds
    var waitAnim = Wait.init(2);
    try scene.play(waitAnim.asAnimatable());

    // Play in parallel all the transform animations
    var animationGroup = try AnimationGroup.init(allocator, animatables);
    defer animationGroup.deinit();
    try scene.play(animationGroup.asAnimatable());

    try engine.preview(&scene, .{
        .width = 1280,
        .height = 720,
    });

    for (gridLines.items) |*item| {
        item.base.deinit();
    }

    for (animations.items) |*item| {
        item.deinit();
    }
}
