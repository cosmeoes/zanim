/// How vertices should be interpreted
pub const VertexMode = enum {
    /// Independent line segments (pairs of points)
    Lines,
    /// Connected line forming a path
    LineStrip,
    /// Connected line that closes back to start
    LineLoop,
    /// Filled triangles
    Triangles,
    /// Individual points
    Points,
};
