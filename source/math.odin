package imdd

import glm "core:math/linalg/glsl"

quat_rotation_xyz :: proc(rotation: glm.vec3) -> glm.quat {
    return glm.quatAxisAngle({1, 0, 0}, rotation.x) * glm.quatAxisAngle({0, 1, 0}, rotation.y) * glm.quatAxisAngle({0, 0, -1}, rotation.z)
}

quat_rotation_dir :: proc(dir: glm.vec3) -> glm.quat {
    return glm.quatFromMat4(glm.mat4Orientation(dir, {0, 1, 0}))
}

rgb :: proc(r: u32, g: u32, b: u32) -> u32 {
    return (r << 24) | (g << 16) | (b << 8) | 255
}

rgba :: proc(r: u32, g: u32, b: u32, a: u32 = 255) -> u32 {
    return (r << 24) | (g << 16) | (b << 8) | a
}

rgb_f32 :: proc(r: f32, g: f32, b: f32) -> u32 {
    return (u32(r * 255) << 24) | (u32(g * 255) << 16) | (u32(b * 255) << 8) | 255
}

rgba_f32 :: proc(r: f32, g: f32, b: f32, a: f32 = 1) -> u32 {
    return (u32(r * 255) << 24) | (u32(g * 255) << 16) | (u32(b * 255) << 8) | u32(a * 255)
}

rgb_uvec3 :: proc(c: glm.uvec3) -> u32 {
    return (c.r << 24) | (c.g << 16) | (c.b << 8) | 255
}

rgba_uvec4 :: proc(c: glm.uvec4) -> u32 {
    return (c.r << 24) | (c.g << 16) | (c.b << 8) | c.a
}

rgb_vec3 :: proc(c: glm.vec3) -> u32 {
    return (u32(c.r * 255) << 24) | (u32(c.g * 255) << 16) | (u32(c.b * 255) << 8) | 255
}

rgba_vec4 :: proc(c: glm.vec4) -> u32 {
    return (u32(c.r * 255) << 24) | (u32(c.g * 255) << 16) | (u32(c.b * 255) << 8) | u32(c.a * 255)
}
