package imdd

import glm "core:math/linalg/glsl"
import gl "vendor:OpenGL"

@(private)
system: Debug_System

DEBUG_POINT_CAP :: 64
DEBUG_ARROW_CAP :: 64

Debug_System :: struct {
    // point
    point_data: [dynamic]Debug_Point,
    point_len: i32,
    point_vao: u32,
    point_vbo: u32,
    point_shader: Shader,

    // arrow
    arrow_data: [dynamic]Debug_Arrow,
    arrow_len: i32,
    arrow_vao: u32,
    arrow_vbo: u32,
    arrow_shader: Shader
}

init_debug_system :: proc() {
    init_point_rdr()
    init_arrow_rdr()
}

free_debug_system :: proc() {
    free_point_rdr()
    free_arrow_rdr()
}

render_debug_system :: proc(viewport: ^glm.ivec2, projection: ^glm.mat4, view: ^glm.mat4) {
    gl.Enable(gl.DEPTH_TEST); defer gl.Disable(gl.DEPTH_TEST)

    render_point_rdr(viewport, projection, view)
    render_arrow_rdr(viewport, projection, view)
}
