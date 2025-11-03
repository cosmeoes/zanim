const za = @import("zalgebra");
const std = @import("std");

pub const Transform = struct {
    position: za.Vec3,
    rotation: za.Quat,
    scaleVec: za.Vec3,

    pub fn init() Transform {
        return Transform{
            .position = za.Vec3.zero(),
            .rotation = za.Quat.identity(),
            .scaleVec = za.Vec3.one(),
        };
    }

    pub fn toMatrix(self: Transform) za.Mat4 {
        return za.Mat4.fromTranslate(self.position)
            .mul(self.rotation.toMat4())
            .mul(za.Mat4.fromScale(self.scaleVec));
    }

    pub fn translate(self: *Transform, pos: za.Vec3) void {
        self.position = pos;
    }

    pub fn rotate(self: *Transform, angle: f32, axis: za.Vec3) void {
        // the rotation gets applied around the world origin, insted of the
        // objects own center, (when you translate the object).
        // This will cause issues in the future but it's fine for now.
        self.rotation = za.Quat.fromAxis(angle, axis);
    }

    pub fn scale(self: *Transform, scalar: f32) void {
        self.scaleVec = za.Vec3.new(1, 1, 1).scale(scalar);
    }

    pub fn combine(self: Transform, second: Transform) Transform {
        return .{
            .rotation = za.Quat.mul(self.rotation, second.rotation),
            .position = self.position.add(
                // Rotate then scale
                self.rotation.rotateVec(second.position.mul(self.scaleVec))
            ),
            .scaleVec = self.scaleVec.mul(second.scaleVec),
        };
    }
};
