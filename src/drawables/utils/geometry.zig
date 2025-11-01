/// How vertices should be interpreted
pub const VertexMode = enum {
    /// Independent line segments (pairs of points)
    LineSegments,
    /// Connected line forming a path
    LinePath,
    /// Connected line that closes back to start
    LineLoop,
    /// Filled triangles
    TriangleMesh,
    /// Individual points
    Points,
};
