const std = @import("std");
const zig_manim = @import("zig_manim");
const za = @import("zalgebra");
const Vec3 = za.Vec3;
const Vec4 = za.Vec4;
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
const FadeAnimation = @import("animation/animation.zig").FadeAnimation;
const AnimationGroup = @import("animation/animation.zig").AnimationGroup;
const Animatable = @import("animation/animation.zig").Animatable;
const Transform = @import("drawables/utils/transform.zig").Transform;
const Engine = @import("engine.zig").Engine;
const Wait = @import("animation/animation.zig").Wait;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const baseAllocator = gpa.allocator();

    // Initialize the library
    var engine = try Engine.init(baseAllocator);
    defer engine.deinit();
    // Create your scene
    var scene = try engine.createScene();
    defer scene.deinit();

    var triangle = try scene.create(Polygon, try .init(
        scene.a,
        &[_]Vec3{
            Vec3.new(0, 1, 0),
            Vec3.new(1, 0, 0),
            Vec3.new(-1, 0, 0),
        },
        Vec4.new(1, 1, 0, 1),
    ));

    var rectangle = try scene.create(Polygon, try .init(
        scene.a,
        &[_]Vec3{ 
            Vec3.new(5, 2, 0),
            Vec3.new(5, 1, 0),
            Vec3.new(-5, 1, 0),
            Vec3.new(-5, 2, 0),
        },
        Vec4.new(0, 1, 0, 1),
    ));
    rectangle.base.rotate(90, Vec3.new(0, 0, 1));
    rectangle.base.translate(Vec3.new(0, 1, 0));

    var pentagon = try scene.create(Polygon, try .init(
        scene.a,
        &[_]Vec3{
            Vec3.new(-0.5, 1, 0),
            Vec3.new(-1, 0.5, 0),
            Vec3.new(-1, 0, 0),
            Vec3.new(-0.5, -0.5, 0),

            Vec3.new(0.5, -0.5, 0),
            Vec3.new(1, 0, 0),
            Vec3.new(1, 0.5, 0),
            Vec3.new(0.5, 1, 0),
        },
        Vec4.new(1, 0.4, 0, 1),
    ));
    pentagon.base.translate(Vec3.new(0, -2, 0));

    var animationsBuffer: [45]*TransformAnim = undefined; 
    var animations: std.ArrayList(*TransformAnim) = .initBuffer(&animationsBuffer);

    var transform = Transform.init();
    transform.rotate(-34, Vec3.new(0, 0, 1));
    transform.scaleVec = Vec3.new(0.8, 0.4, 1);

    const transformTriangle = try scene.create(TransformAnim, .init(&triangle.base, transform, 2));
    const transformRectangle = try scene.create(TransformAnim, .init(&rectangle.base, transform, 2));
    const transformPentagon = try scene.create(TransformAnim, .init(&pentagon.base, transform, 2));
    animations.appendAssumeCapacity(transformTriangle);
    animations.appendAssumeCapacity(transformRectangle);
    animations.appendAssumeCapacity(transformPentagon);

    // X axis
    var i: i32 = -10;
    while (i < 11) : (i += 1) {
        const floatIndex: f32 = @floatFromInt(i);
        var color = Vec4.new(0, 1, 1, 1);
        if (i == 0) {
            color = Vec4.new(0.5, 0.5, 0.5, 1);
        }
        const line = try scene.create(Line, try .init(scene.a, Vec3.new(-10.0, floatIndex, -0.01), Vec3.new(10, floatIndex, -0.01), color));
        const transformAnim = try scene.create(TransformAnim, .init(&line.base, transform, 2));
        animations.appendAssumeCapacity(transformAnim);

        try scene.add(&line.base);
    }

    // Y axis
    i = -10;
    while (i < 11) : (i += 1) {
        const floatIndex: f32 = @floatFromInt(i);
        var color = Vec4.new(0, 1, 1, 1);
        if (i == 0) {
            color = Vec4.new(0.5, 0.5, 0.5, 1);
        }
        const line = try scene.create(Line, try .init(scene.a, Vec3.new(floatIndex, -10, -0.01), Vec3.new(floatIndex, 10, -0.01), color));
        const transformAnim = try scene.create(TransformAnim, .init(&line.base, transform, 2));
        animations.appendAssumeCapacity(transformAnim);

        try scene.add(&line.base);
    }

    try scene.add(&triangle.base);
    try scene.add(&rectangle.base);
    try scene.add(&pentagon.base);

    const animatables: []Animatable = try scene.a.alloc(Animatable, animations.items.len);
    for (animations.items, 0..) |trans, index| {
        animatables[index] = trans.asAnimatable();
    }

    // Triangle grow animation
    var createTriangle = try Create.init(scene.a, &triangle.base, 1);
    createTriangle.fromCenter();

    // rectangle grow animation
    var createRectangle = try Create.init(scene.a, &rectangle.base, 1);

    // pentagon fade in
    var createPentagon = FadeAnimation.init(&pentagon.base, 0, 1, 2);

    // Play them in parallel
    var createGroup = try AnimationGroup.init(scene.a, &[_]Animatable{
        createTriangle.asAnimatable(),
        createRectangle.asAnimatable(),
        createPentagon.asAnimatable(),
    });
    try scene.play(createGroup.asAnimatable());

    var rotateRect = Transform.init();
    rotateRect.rotate(-90, Vec3.new(0, 0, 1));
    var rectRotate = TransformAnim.init(&rectangle.base, rotateRect, 2);
    try scene.play(rectRotate.asAnimatable());

    // Wait 2 seconds
    try scene.wait(2);

    // Play in parallel all the transform animations
    var animationGroup = try AnimationGroup.init(scene.a, animatables);
    try scene.play(animationGroup.asAnimatable());

    try scene.wait(1);
    var moveTransform = Transform.init(); 
    moveTransform.rotate(34, Vec3.new(0, 0, 1));
    moveTransform.scaleVec = Vec3.new(5, 5, 1);

    var moveTriangleAnimation = TransformAnim.init(&triangle.base, moveTransform, 2);
    var rectangleFadeout = FadeAnimation.init(&rectangle.base, 1, 0, 3);
    var pentagonFadeout = FadeAnimation.init(&pentagon.base, 1, 0, 3);
    var endGroup = try AnimationGroup.init(scene.a, &[_]Animatable{
        moveTriangleAnimation.asAnimatable(),
        rectangleFadeout.asAnimatable(),
        pentagonFadeout.asAnimatable(),
    });
    try scene.play(endGroup.asAnimatable());

    try engine.preview(&scene, .{
        .width = 1920,
        .height = 1080,
    });
}
