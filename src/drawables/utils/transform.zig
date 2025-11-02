const za = @import("zalgebra");

pub const Transform = struct {
    position: za.Vec3,
    rotation: za.Quat,
    scale: za.Vec3,

    pub fn init() Transform {
        return Transform{
            .position = za.Vec3.zero(),
            .rotation = za.Quat.identity(),
            .scale = za.Vec3.one(),
        };
    }

    pub fn toMatrix(self: Transform) za.Mat4 {
        return za.Mat4.fromTranslate(self.position)
            .mul(self.rotation.toMat4())
            .mul(za.Mat4.fromScale(self.scale));
    }
};
