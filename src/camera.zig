const za = @import("zalgebra");
const Vec3 = za.Vec3;
const Mat4 = za.Mat4;
const std = @import("std");
const math = std.math;

const YAW : f64 = -90.0;
const PITCH: f64 =  0.0;
const SPEED: f32 =  2.5;
const SENSITIVITY: f32 =  0.1;
const ZOOM: f32 =  45.0;

pub const Camera = struct {
    position: Vec3,
    front: Vec3 = Vec3.new(0, 0, -1),
    up: Vec3 = Vec3.up(),
    right: Vec3 = Vec3.new(0, 0, 0),
    worldUp: Vec3 = Vec3.up(),

    speed: f32 = SPEED,
    yaw: f64 = YAW,
    pitch: f64 = PITCH,
    sensitivity: f32 = SENSITIVITY,
    zoom: f32 = ZOOM,

    pub fn new(position: Vec3) Camera {
        var camera = Camera {
            .position = position,
            .worldUp = Vec3.up(),
        };
        camera.updateCameraVectors();

        return camera;
    }

    pub fn moveFoward(self: *Camera, deltaTime: f32) void {
        const velocity = self.speed * deltaTime;
        self.position = self.position.add(self.front.scale(velocity));
    }

    pub fn moveBack(self: *Camera, deltaTime: f32) void {
        const velocity = self.speed * deltaTime;
        self.position = self.position.sub(self.front.scale(velocity));
    }

    pub fn moveRight(self: *Camera, deltaTime: f32) void {
        const velocity = self.speed * deltaTime;
        self.position = self.position.add(self.right.scale(velocity));
    }

    pub fn moveLeft(self: *Camera, deltaTime: f32) void {
        const velocity = self.speed * deltaTime;
        self.position = self.position.sub(self.right.scale(velocity));
    }

    pub fn processMovement(self: *Camera, xoffset: f32, yoffset: f32) void {
        self.yaw += xoffset * self.sensitivity;
        self.pitch += yoffset * self.sensitivity;

        // make sure that when pitch is out of bounds, screen doesn't get flipped
        if (self.pitch > 89.0) {
            self.pitch = 89.0;
        }
        if (self.pitch < -89.0) {
            self.pitch = -89.0;
        }

        self.updateCameraVectors();
    }

    pub fn updateCameraVectors(self: *Camera) void {
        // calculate the new Front vector
        self.front = Vec3.new(
            @floatCast(math.cos(za.toRadians(self.yaw)) * math.cos(za.toRadians(self.pitch))),
            @floatCast(math.sin(za.toRadians(self.pitch))),
            @floatCast(math.sin(za.toRadians(self.yaw)) * math.cos(za.toRadians(self.pitch))),
        ).norm();

        self.right = self.front.cross(self.worldUp).norm();
        self.up = self.right.cross(self.front).norm();
    }

    pub fn viewMatrix(self: Camera) Mat4 {
        return Mat4.lookAt(self.position, self.position.add(self.front), self.up);
    }
};

