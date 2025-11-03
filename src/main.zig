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
const Arrow2D = @import("drawables/drawable_types.zig").Arrow2D;
const Grid2D = @import("drawables/drawable_types.zig").Grid2D;
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

    var args = try std.process.argsWithAllocator(baseAllocator);
    defer args.deinit();
    // skip program name
    _ = args.skip();
    var choice: []const u8 = undefined;
    if (args.next()) |arg| {
        choice = arg;
    } else {
        std.log.info("No option selected: 'shapes', 'vectors'", .{});
        return;
    }

    var engine = try Engine.init(baseAllocator);
    defer engine.deinit();

    var scene = try engine.createScene();
    defer scene.deinit();

    if (std.mem.eql(u8, choice, "shapes")) {
        try buildShapes(&scene);
    } else if (std.mem.eql(u8, choice, "vectors")) {
        try buildVectors(&scene);
    } else {
        std.log.info("No option '{s}' not found, options: 'shapes', 'vectors'", .{choice});
        return;
    }

    try engine.preview(&scene, .{
        .width = 1920,
        .height = 1080,
    });
}

pub fn buildShapes(scene: *Scene) !void {
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

    var animationsBuffer: [46]*TransformAnim = undefined; 
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
        const line = try scene.create(Line, try .init(scene.a, Vec3.new(-10.0, floatIndex, -0.01), Vec3.new(10, floatIndex, -0.01), color));
        if (i == 0) {
            color = Vec4.new(0.5, 0.5, 0.5, 1);
            line.setWidth(line.width*2);
        }
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
    var createTriangle = try scene.create(Create, try .init(scene.a, &triangle.base, 1));
    createTriangle.fromCenter();

    // rectangle grow animation
    var createRectangle = try scene.create(Create, try .init(scene.a, &rectangle.base, 1));

    // pentagon fade in
    var createPentagon = try scene.create(FadeAnimation, .init(&pentagon.base, 0, 1, 2));

    // Play them in parallel
    var createGroup = try scene.create(AnimationGroup, try .init(scene.a, &[_]Animatable{
        createTriangle.asAnimatable(),
        createRectangle.asAnimatable(),
        createPentagon.asAnimatable(),
    }));

    try scene.play(createGroup.asAnimatable());

    var rotateRect = Transform.init();
    rotateRect.rotate(-90, Vec3.new(0, 0, 1));
    var rectRotate = try scene.create(TransformAnim, .init(&rectangle.base, rotateRect, 2));
    var rotateGroup = try scene.create(AnimationGroup, try .init(scene.a, &[_]Animatable{
        rectRotate.asAnimatable(),
    }));
    try scene.play(rotateGroup.asAnimatable());

    // Wait 2 seconds
    try scene.wait(2);

    // Play in parallel all the transform animations
    var animationGroup = try scene.create(AnimationGroup, try .init(scene.a, animatables));
    try scene.play(animationGroup.asAnimatable());

    try scene.wait(1);
    var moveTransform = Transform.init();
    moveTransform.rotate(34, Vec3.new(0, 0, 1));
    moveTransform.scaleVec = Vec3.new(5, 5, 1);

    var moveTriangleAnimation = try scene.create(TransformAnim, .init(&triangle.base, moveTransform, 2));
    var rectangleFadeout = try scene.create(FadeAnimation, .init(&rectangle.base, 1, 0, 3));
    var pentagonFadeout = try scene.create(FadeAnimation, .init(&pentagon.base, 1, 0, 3));
    var endGroup = try scene.create(AnimationGroup, try .init(scene.a, &[_]Animatable{
        moveTriangleAnimation.asAnimatable(),
        rectangleFadeout.asAnimatable(),
        pentagonFadeout.asAnimatable(),
    }));
    try scene.play(endGroup.asAnimatable());
}

pub fn buildVectors(scene: *Scene) !void {
    const grid = try scene.create(Grid2D, try .init(scene.a, za.Vec2.new(-10, 10), za.Vec2.new(-10, 10), Vec4.new(0, 1, 1, 1)));
    grid.base.transform.translate(Vec3.new(0, 0, -0.01));

    var redArrow = try scene.create(Arrow2D, try .init(
        scene.a, Vec3.new(0, 0, 0), Vec3.new(-1, 1, 0), Vec4.new(0.9, 0.1, 0.1, 1),
    ));
    redArrow.setLineWidth(0.05);
    redArrow.setHeadSize(0.2, 0.2);

    var blueArrow = try scene.create(Arrow2D, try .init(
        scene.a, Vec3.new(0, 0, 0), Vec3.new(1, 1, 0), Vec4.new(0.1, 0.1, 0.9, 0), // Alpha 0 to hide
    ));
    blueArrow.setLineWidth(0.05);
    blueArrow.setHeadSize(0.2, 0.2);

    var greenArrow = try scene.create(Arrow2D, try .init(
        scene.a, redArrow.end_pos, blueArrow.end_pos, Vec4.new(0.1, 0.9, 0.1, 0), // Alpha 0 to hide
    ));
    greenArrow.base.translate(Vec3.new(0, 0, 0.01));
    greenArrow.setLineWidth(0.05);
    greenArrow.setHeadSize(0.2, 0.2);

    const rotation = za.Quat.fromAxis(45, Vec3.new(0, 0, 1));
    var greenArrow2 = try scene.create(Arrow2D, try .init(
        scene.a, rotation.rotateVec(redArrow.end_pos), blueArrow.end_pos, Vec4.new(0.1, 0.9, 0.1, 0), // Alpha 0 to hide
    ));
    greenArrow2.base.translate(Vec3.new(0, 0, 0.02));
    greenArrow2.setLineWidth(0.05);
    greenArrow2.setHeadSize(0.2, 0.2);

    try scene.add(&grid.base);
    try scene.add(&redArrow.base);
    try scene.add(&blueArrow.base);
    try scene.add(&greenArrow.base);
    try scene.add(&greenArrow2.base);

    // Animations
    const createRedArrow = try scene.create(Create, try .init(scene.a, &redArrow.base, 2));
    try scene.play(createRedArrow.asAnimatable());
    try scene.wait(2);

    const createBlueArrow = try scene.create(FadeAnimation, .init(&blueArrow.base, 0, 1, 2));
    try scene.play(createBlueArrow.asAnimatable());
    try scene.wait(2);

    const createGreenArrow = try scene.create(FadeAnimation, .init(&greenArrow.base, 0, 1, 2));
    try scene.play(createGreenArrow.asAnimatable());
    try scene.wait(2);

    var scaleDown = Transform.init(); 
    scaleDown.scale(0);
    const greenArrowFadeout = try scene.create(TransformAnim, .init(&greenArrow.base, scaleDown, 1.5));
    try scene.play(greenArrowFadeout.asAnimatable());
    try scene.wait(2);

    var globalTransform = Transform.init();
    globalTransform.rotate(45, Vec3.new(0, 0, 1));

    var gridAnimation = try scene.create(TransformAnim, .init(&grid.base, globalTransform, 2));
    var arrowAnimation = try scene.create(TransformAnim, .init(&redArrow.base, globalTransform, 2));
    try scene.playGroup(&[_]Animatable{
        gridAnimation.asAnimatable(),
        arrowAnimation.asAnimatable(),
    });

    const createGreenArrow2 = try scene.create(FadeAnimation, .init(&greenArrow2.base, 0, 1, 2));
    try scene.play(createGreenArrow2.asAnimatable());
    try scene.wait(2);

    var fullRotation = Transform.init();
    fullRotation.rotate(-70, Vec3.new(1, 0.5, 0));

    const duration: f32 = 10;
    var gridSquish = try scene.create(TransformAnim, .init(&grid.base, fullRotation, duration));
    var redArrowSquish = try scene.create(TransformAnim, .init(&redArrow.base, fullRotation, duration));
    var blueArrowSquish = try scene.create(TransformAnim, .init(&blueArrow.base, fullRotation, duration));
    var greenArrowSquish = try scene.create(TransformAnim, .init(&greenArrow2.base, fullRotation, duration));
    try scene.playGroup(&[_]Animatable{
        gridSquish.asAnimatable(),
        redArrowSquish.asAnimatable(),
        blueArrowSquish.asAnimatable(),
        greenArrowSquish.asAnimatable(),
    });
}
