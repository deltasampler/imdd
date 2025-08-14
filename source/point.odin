package imdd

import glm "core:math/linalg/glsl"
import gl "vendor:OpenGL"

Debug_Point :: struct {
    position: glm.vec3,
    radius: f32,
    color: i32
}

debug_point :: proc(position: glm.vec3, radius: f32, color: i32) {
    point := &system.point_data[system.point_len]
    point.position = position
    point.radius = radius
    point.color = color
    system.point_len = (system.point_len + 1) % DEBUG_POINT_CAP
}

// rendering
POINT_VS :: `#version 460 core

    layout(location = 0) in vec3 i_position;
    layout(location = 1) in float i_radius;
    layout(location = 2) in int i_color;

    out vec3 v_color;
    out vec2 v_tex_coord;
    out float v_depth;

    uniform mat4 u_projection;
    uniform mat4 u_view;

    const vec2 positions[4] = vec2[](
        vec2(-1.0, -1.0),
        vec2(1.0, -1.0),
        vec2(-1.0, 1.0),
        vec2(1.0, 1.0)
    );

    const vec2 tex_coords[4] = vec2[](
        vec2(0.0, 0.0),
        vec2(1.0, 0.0),
        vec2(0.0, 1.0),
        vec2(1.0, 1.0)
    );

    vec3 int_to_rgb(int i) {
        return vec3(
            (i >> 16) & 0xFF,
            (i >> 8) & 0xFF,
            i & 0xFF
        ) / 255.0;
    }

    void main() {
        vec4 position = vec4(transpose(mat3(u_view)) * vec3(positions[gl_VertexID] * i_radius, 0.0) + i_position, 1.0);

        gl_Position = u_projection * u_view * position;
        v_color = int_to_rgb(i_color);
        v_tex_coord = tex_coords[gl_VertexID];
        v_depth = -(u_view * position).z;
    }
`

POINT_FS :: `#version 460 core
precision highp float;

in vec3 v_color;
in vec2 v_tex_coord;
in float v_depth;

out vec4 o_frag_color;

void main() {
    vec2 uv = v_tex_coord;
    vec2 cp = uv * 2.0 - 1.0;

    if (cp.x * cp.x + cp.y * cp.y > 1.0) {
        discard;
    }

    o_frag_color = vec4(v_color, 1.0);
}
`

init_point_rdr :: proc() {
    // data
    system.point_data = make([dynamic]Debug_Point, DEBUG_POINT_CAP, DEBUG_POINT_CAP)

    // vao
    gl.GenVertexArrays(1, &system.point_vao)
    gl.BindVertexArray(system.point_vao)

    // vbo
    gl.GenBuffers(1, &system.point_vbo)
    gl.BindBuffer(gl.ARRAY_BUFFER, system.point_vbo)
    gl.BufferData(gl.ARRAY_BUFFER, size_of(Debug_Point) * DEBUG_POINT_CAP, nil, gl.DYNAMIC_DRAW)

    // attributes
    offset: uintptr = 0

    gl.EnableVertexAttribArray(0)
    gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of(Debug_Point), offset)
    gl.VertexAttribDivisor(0, 1)
    offset += size_of(glm.vec3)

    gl.EnableVertexAttribArray(1)
    gl.VertexAttribPointer(1, 1, gl.FLOAT, false, size_of(Debug_Point), offset)
    gl.VertexAttribDivisor(1, 1)
    offset += size_of(f32)

    gl.EnableVertexAttribArray(2)
    gl.VertexAttribIPointer(2, 1, gl.INT, size_of(Debug_Point), offset)
    gl.VertexAttribDivisor(2, 1)

    // shaders
    make_shader(&system.point_shader, gl.load_shaders_source(POINT_VS, POINT_FS))
}

free_point_rdr :: proc() {
    delete(system.point_data)
    gl.DeleteVertexArrays(1, &system.point_vao)
    gl.DeleteBuffers(1, &system.point_vbo)
    delete_shader(&system.point_shader)
}

render_point_rdr :: proc(viewport: ^glm.ivec2, projection: ^glm.mat4, view: ^glm.mat4) {
    if system.point_len == 0 {
        return
    }

    uniforms := &system.point_shader.uniforms

    use_shader(&system.point_shader)
    gl.UniformMatrix4fv(uniforms["u_projection"] - 1, 1, false, &projection[0][0])
    gl.UniformMatrix4fv(uniforms["u_view"] - 1, 1, false, &view[0][0])

    gl.BindVertexArray(system.point_vao)
    gl.BindBuffer(gl.ARRAY_BUFFER, system.point_vbo)
    gl.BufferSubData(gl.ARRAY_BUFFER, 0, size_of(Debug_Point) * DEBUG_POINT_CAP, &system.point_data[0])

    gl.DrawArraysInstanced(gl.TRIANGLE_STRIP, 0, 4, system.point_len)

    system.point_len = 0
}
