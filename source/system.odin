package imdd

import glm "core:math/linalg/glsl"
import gl "vendor:OpenGL"

@(private)
system: Debug_System

DEBUG_POINT_CAP :: 256
DEBUG_LINE_CAP :: 256
DEBUG_GRID_CAP :: 16
DEBUG_SHAPE_CAP :: 256
DEBUG_FRUSTUM_CAP :: 16

Debug_System :: struct {
    depth_texture: u32,

    // point
    point_data: [dynamic]Debug_Point,
    point_len: i32,
    point_vao: u32,
    point_vbo: u32,
    point_shader: Shader,

    // line
    line_data: [dynamic]Debug_Line,
    line_len: i32,
    line_vao: u32,
    line_vbo: u32,
    line_shader: Shader,

    // grid plane
    grid_data: [dynamic]Debug_Grid_Plane,
    grid_len: i32,
    grid_vao: u32,
    grid_vbo: u32,
    grid_shader: Shader,

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
    frustum_shader: Shader
}

debug_init :: proc() {
    init_point_rdr()
    init_line_rdr()
    init_grid_rdr()
    init_shape_rdr()
    init_frustum_rdr()
}

debug_free :: proc() {
    free_point_rdr()
    free_line_rdr()
    free_grid_rdr()
    free_shape_rdr()
    free_frustum_rdr()
}

debug_render :: proc(viewport: ^glm.ivec2, projection: ^glm.mat4, view: ^glm.mat4) {
    gl.Enable(gl.DEPTH_TEST); defer gl.Disable(gl.DEPTH_TEST)
    gl.Enable(gl.BLEND); defer gl.Disable(gl.BLEND)
    gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)

    gl.ActiveTexture(gl.TEXTURE0)
    gl.BindTexture(gl.TEXTURE_2D, system.depth_texture);

    render_point_rdr(viewport, projection, view)
    render_line_rdr(viewport, projection, view)
    render_shape_rdr(viewport, projection, view)
    render_frustum_rdr(viewport, projection, view)
    render_grid_rdr(viewport, projection, view)
}

debug_set_depth_texture :: proc(texture: u32) {
    system.depth_texture = texture
}
