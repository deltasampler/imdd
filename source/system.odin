package imdd

import glm "core:math/linalg/glsl"
import gl "vendor:OpenGL"

@(private)
system: Debug_System

DEBUG_POINT_CAP :: 64
DEBUG_ARROW_CAP :: 64
DEBUG_GRID_PLANE_CAP :: 64
DEBUG_SHAPE_CAP :: 64
DEBUG_FRUSTUM_CAP :: 64

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
    arrow_shader: Shader,

    // grid plane
    grid_plane_data: [dynamic]Debug_Grid_Plane,
    grid_plane_len: i32,
    grid_plane_vao: u32,
    grid_plane_vbo: u32,
    grid_plane_shader: Shader,

    // shape
    shape_len: i32,
    shape_vao: u32,
    shape_vbo: u32,
    shape_ibo: u32,
    shape_ubo: u32,
    shape_shader: Shader,

    // box
    box_data: [dynamic]Debug_Shape,
    box_len: i32,
    box_offset: Index_Offset,

    // cylinder
    cylinder_data: [dynamic]Debug_Shape,
    cylinder_len: i32,
    cylinder_offset: Index_Offset,

    // cone
    cone_data: [dynamic]Debug_Shape,
    cone_len: i32,
    cone_offset: Index_Offset,

    // sphere
    sphere_data: [dynamic]Debug_Shape,
    sphere_len: i32,
    sphere_offset: Index_Offset,

    // frustum
    frustum_data: [dynamic]Debug_Frustum,
    frustum_len: i32,
    frustum_vao: u32,
    frustum_vbo: u32,
    frustum_shader: Shader,
}

init_debug_system :: proc() {
    init_point_rdr()
    init_arrow_rdr()
    init_grid_plane_rdr()
    init_shape_rdr()
    init_frustum_rdr()
}

free_debug_system :: proc() {
    free_point_rdr()
    free_arrow_rdr()
    free_grid_plane_rdr()
    free_shape_rdr()
    free_frustum_rdr()
}

render_debug_system :: proc(viewport: ^glm.ivec2, projection: ^glm.mat4, view: ^glm.mat4) {
    gl.Enable(gl.DEPTH_TEST); defer gl.Disable(gl.DEPTH_TEST)
    gl.Enable(gl.BLEND); defer gl.Disable(gl.BLEND)
    gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)

    render_point_rdr(viewport, projection, view)
    render_arrow_rdr(viewport, projection, view)
    render_shape_rdr(viewport, projection, view)
    render_frustum_rdr(viewport, projection, view)
    render_grid_plane_rdr(viewport, projection, view)
}
