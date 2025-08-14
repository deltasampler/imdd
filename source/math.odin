package imdd

import glm "core:math/linalg/glsl"

quat_rotation_xyz :: proc(rotation: glm.vec3) -> glm.quat {
    return glm.quatAxisAngle({1, 0, 0}, rotation.x) * glm.quatAxisAngle({0, 1, 0}, rotation.y) * glm.quatAxisAngle({0, 0, -1}, rotation.z)
}

quat_rotation_dir :: proc(dir: glm.vec3) -> glm.quat {
    return glm.quatFromMat4(glm.mat4Orientation(dir, {0, 1, 0}))
}
