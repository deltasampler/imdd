package imdd

import glm "core:math/linalg/glsl"
import gl "vendor:OpenGL"

Debug_Arrow :: struct {
    start: glm.vec3,
    end: glm.vec3,
    radius: f32,
    color: i32
}

debug_arrow :: proc(start: glm.vec3, end: glm.vec3, radius: f32, color: i32) {
    arrow := &system.arrow_data[system.arrow_len]
    arrow.start = start
    arrow.end = end
    arrow.radius = radius
    arrow.color = color
    system.arrow_len = (system.arrow_len + 1) % DEBUG_ARROW_CAP
}

// rendering
ARROW_VS :: `#version 460 core

layout(location = 0) in vec3 i_start;
layout(location = 1) in vec3 i_end;
layout(location = 2) in float i_radius;
layout(location = 3) in int i_color;

out Geometry_Data {
    vec3 start;
    vec3 end;
    float radius;
    int color;
} v_gd;

void main() {
    v_gd.start = i_start;
    v_gd.end = i_end;
    v_gd.radius = i_radius;
    v_gd.color = i_color;
}
`

ARROW_GS :: `#version 460 core

layout (points) in;
layout (triangle_strip, max_vertices = 7) out;

out vec3 v_color;
out float v_depth;

uniform mat4 u_projection;
uniform mat4 u_view;

in Geometry_Data {
    vec3 start;
    vec3 end;
    float radius;
    int color;
} v_gd[];

vec3 int_to_rgb(int i) {
    return vec3(
        (i >> 16) & 0xFF,
        (i >> 8) & 0xFF,
        i & 0xFF
    ) / 255.0;
}

void main() {
    vec3 start = v_gd[0].start;
    vec3 end = v_gd[0].end;
    float radius = v_gd[0].radius;
    int color = v_gd[0].color;

    vec3 start_view = (u_view * vec4(start, 1.0)).xyz;
    vec3 end_view = (u_view * vec4(end, 1.0)).xyz;

    vec3 line_dir = normalize(end_view - start_view);
    vec3 line_mid = (start_view + end_view) * 0.5;

    vec3 cam_dir = normalize(vec3(0, 0, 0) - line_mid);
    vec3 perp = normalize(cross(line_dir, cam_dir));

    float cap_width = radius * 2.0;
    float cap_length = radius * 4.0;
    vec3 cap_pos = end_view - line_dir * cap_length;

    v_color = int_to_rgb(color);

    // base
    vec4 world_position = vec4(start_view - perp * radius, 1.0);
    gl_Position = u_projection * world_position;
    v_depth = -world_position.z;
    EmitVertex();

    world_position = vec4(start_view + perp * radius, 1.0);
    gl_Position = u_projection * world_position;
    v_depth = -world_position.z;
    EmitVertex();

    world_position = vec4(cap_pos - perp * radius, 1.0);;
    gl_Position = u_projection * world_position;
    v_depth = -world_position.z;
    EmitVertex();

    world_position = vec4(cap_pos + perp * radius, 1.0);
    gl_Position = u_projection * world_position;
    v_depth = -world_position.z;
    EmitVertex();

    // cap
    world_position = vec4(cap_pos - perp * cap_width, 1.0);
    gl_Position = u_projection * world_position;
    v_depth = -world_position.z;
    EmitVertex();

    world_position = vec4(cap_pos + perp * cap_width, 1.0);
    gl_Position = u_projection * world_position;
    v_depth = -world_position.z;
    EmitVertex();

    world_position = vec4(end_view, 1.0);
    gl_Position = u_projection * world_position;
    v_depth = -world_position.z;
    EmitVertex();
}
`

ARROW_FS :: `#version 460 core
precision highp float;

in vec3 v_color;
in float v_depth;

out vec4 o_frag_color;

void main() {
    o_frag_color = vec4(v_color, 1.0);
}
`

init_arrow_rdr :: proc() {
    // data
    system.arrow_data = make([dynamic]Debug_Arrow, DEBUG_ARROW_CAP, DEBUG_ARROW_CAP)

    // vao
    gl.GenVertexArrays(1, &system.arrow_vao)
    gl.BindVertexArray(system.arrow_vao)

    // vbo
    gl.GenBuffers(1, &system.arrow_vbo)
    gl.BindBuffer(gl.ARRAY_BUFFER, system.arrow_vbo)
    gl.BufferData(gl.ARRAY_BUFFER, size_of(Debug_Arrow) * DEBUG_ARROW_CAP, nil, gl.DYNAMIC_DRAW)

    // attributes
    offset: uintptr = 0

    gl.EnableVertexAttribArray(0)
    gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of(Debug_Arrow), offset)
    offset += size_of(glm.vec3)

    gl.EnableVertexAttribArray(1)
    gl.VertexAttribPointer(1, 3, gl.FLOAT, false, size_of(Debug_Arrow), offset)
    offset += size_of(glm.vec3)

    gl.EnableVertexAttribArray(2)
    gl.VertexAttribPointer(2, 1, gl.FLOAT, false, size_of(Debug_Arrow), offset)
    offset += size_of(f32)

    gl.EnableVertexAttribArray(3)
    gl.VertexAttribIPointer(3, 1, gl.INT, size_of(Debug_Arrow), offset)

    // shaders
    make_shader(&system.arrow_shader, load_shaders_source(ARROW_VS, ARROW_GS, ARROW_FS))
}

free_arrow_rdr :: proc() {
    delete(system.arrow_data)
    gl.DeleteVertexArrays(1, &system.arrow_vao)
    gl.DeleteBuffers(1, &system.arrow_vbo)
    delete_shader(&system.arrow_shader)
}

render_arrow_rdr :: proc(viewport: ^glm.ivec2, projection: ^glm.mat4, view: ^glm.mat4) {
    if system.arrow_len == 0 {
        return
    }

    uniforms := &system.arrow_shader.uniforms

    use_shader(&system.arrow_shader)
    gl.UniformMatrix4fv(uniforms["u_projection"] - 1, 1, false, &projection[0][0])
    gl.UniformMatrix4fv(uniforms["u_view"] - 1, 1, false, &view[0][0])

    gl.BindVertexArray(system.arrow_vao);
    gl.BindBuffer(gl.ARRAY_BUFFER, system.arrow_vbo)
    gl.BufferSubData(gl.ARRAY_BUFFER, 0, size_of(Debug_Arrow) * DEBUG_ARROW_CAP, &system.arrow_data[0])

    gl.DrawArrays(gl.POINTS, 0, system.arrow_len)

    system.arrow_len = 0
}
