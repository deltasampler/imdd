package imdd

import glm "core:math/linalg/glsl"
import gl "vendor:OpenGL"

LINE_MODE_DEFAULT :: 0
LINE_MODE_ARROW :: 1

Debug_Line :: struct {
    start: glm.vec3,
    end: glm.vec3,
    width: f32,
    color: i32,
    bit: i32
}

debug_line :: proc(start: glm.vec3, end: glm.vec3, width: f32, color: i32) {
    line := &system.line_data[system.line_len]
    line.start = start
    line.end = end
    line.width = width
    line.color = color
    line.bit = LINE_MODE_DEFAULT << 0
    system.line_len = (system.line_len + 1) % DEBUG_LINE_CAP
}

debug_arrow :: proc(start: glm.vec3, end: glm.vec3, width: f32, color: i32) {
    line := &system.line_data[system.line_len]
    line.start = start
    line.end = end
    line.width = width
    line.color = color
    line.bit = LINE_MODE_ARROW << 0
    system.line_len = (system.line_len + 1) % DEBUG_LINE_CAP
}

// rendering
LINE_VS :: `#version 460 core

layout(location = 0) in vec3 i_start;
layout(location = 1) in vec3 i_end;
layout(location = 2) in float i_width;
layout(location = 3) in int i_color;
layout(location = 4) in int i_bit;

out Geometry_Data {
    vec3 start;
    vec3 end;
    float width;
    int color;
    int bit;
} v_gd;

void main() {
    v_gd.start = i_start;
    v_gd.end = i_end;
    v_gd.width = i_width;
    v_gd.color = i_color;
    v_gd.bit = i_bit;
}
`

LINE_GS :: `#version 460 core

#define LINE_MODE_DEFAULT 0
#define LINE_MODE_ARROW 1

layout (points) in;
layout (triangle_strip, max_vertices = 7) out;

out vec3 v_color;
out float v_depth;

uniform mat4 u_projection;
uniform mat4 u_view;

in Geometry_Data {
    vec3 start;
    vec3 end;
    float width;
    int color;
    int bit;
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
    float width = v_gd[0].width;
    int color = v_gd[0].color;
    int bit = v_gd[0].bit;

    vec3 start_view = (u_view * vec4(start, 1.0)).xyz;
    vec3 end_view = (u_view * vec4(end, 1.0)).xyz;

    vec3 line_dir = normalize(end_view - start_view);
    vec3 line_mid = (start_view + end_view) * 0.5;

    vec3 cam_dir = normalize(vec3(0, 0, 0) - line_mid);
    vec3 perp = normalize(cross(line_dir, cam_dir));

    float base_width = width / 2.0;
    float cap_width = base_width * 1.5;
    float cap_length = base_width * 3.0;
    vec3 cap_pos = bool(bit & LINE_MODE_ARROW) ? end_view - line_dir * cap_length : end_view;

    v_color = int_to_rgb(color);

    // base
    vec4 world_position = vec4(start_view - perp * base_width, 1.0);
    gl_Position = u_projection * world_position;
    v_depth = -world_position.z;
    EmitVertex();

    world_position = vec4(start_view + perp * base_width, 1.0);
    gl_Position = u_projection * world_position;
    v_depth = -world_position.z;
    EmitVertex();

    world_position = vec4(cap_pos - perp * base_width, 1.0);
    gl_Position = u_projection * world_position;
    v_depth = -world_position.z;
    EmitVertex();

    world_position = vec4(cap_pos + perp * base_width, 1.0);
    gl_Position = u_projection * world_position;
    v_depth = -world_position.z;
    EmitVertex();

    // cap
    if (bool(bit & LINE_MODE_ARROW)) {
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
}
`

LINE_FS :: `#version 460 core
precision highp float;

in vec3 v_color;
in float v_depth;

out vec4 o_frag_color;

uniform vec2 u_resolution;
uniform sampler2D sa_depth;

void main() {
    #ifdef USE_DEPTH
        vec2 rm_uv = vec2(gl_FragCoord.x, u_resolution.y - gl_FragCoord.y) / u_resolution;
        float rm_depth = texture(sa_depth, rm_uv).x;

        if (rm_depth < v_depth) {
            discard;
        }
    #endif

    o_frag_color = vec4(v_color, 1.0);
}
`

init_line_rdr :: proc() {
    // data
    system.line_data = make([dynamic]Debug_Line, DEBUG_LINE_CAP, DEBUG_LINE_CAP)

    // vao
    gl.GenVertexArrays(1, &system.line_vao)
    gl.BindVertexArray(system.line_vao)

    // vbo
    gl.GenBuffers(1, &system.line_vbo)
    gl.BindBuffer(gl.ARRAY_BUFFER, system.line_vbo)
    gl.BufferData(gl.ARRAY_BUFFER, size_of(Debug_Line) * DEBUG_LINE_CAP, nil, gl.DYNAMIC_DRAW)

    // attributes
    offset: uintptr = 0

    gl.EnableVertexAttribArray(0)
    gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of(Debug_Line), offset)
    offset += size_of(glm.vec3)

    gl.EnableVertexAttribArray(1)
    gl.VertexAttribPointer(1, 3, gl.FLOAT, false, size_of(Debug_Line), offset)
    offset += size_of(glm.vec3)

    gl.EnableVertexAttribArray(2)
    gl.VertexAttribPointer(2, 1, gl.FLOAT, false, size_of(Debug_Line), offset)
    offset += size_of(f32)

    gl.EnableVertexAttribArray(3)
    gl.VertexAttribIPointer(3, 1, gl.INT, size_of(Debug_Line), offset)
    offset += size_of(i32)

    gl.EnableVertexAttribArray(4)
    gl.VertexAttribIPointer(4, 1, gl.INT, size_of(Debug_Line), offset)

    // shaders
    make_shader(&system.line_shader, load_shaders_source(LINE_VS, LINE_GS, LINE_FS))
}

free_line_rdr :: proc() {
    delete(system.line_data)
    gl.DeleteVertexArrays(1, &system.line_vao)
    gl.DeleteBuffers(1, &system.line_vbo)
    delete_shader(&system.line_shader)
}

render_line_rdr :: proc(projection: ^glm.mat4, view: ^glm.mat4) {
    if system.line_len == 0 {
        return
    }

    uniforms := &system.line_shader.uniforms

    use_shader(&system.line_shader)
    gl.Uniform2f(uniforms["u_resolution"] - 1, f32(system.width), f32(system.height))
    gl.UniformMatrix4fv(uniforms["u_projection"] - 1, 1, false, &projection[0][0])
    gl.UniformMatrix4fv(uniforms["u_view"] - 1, 1, false, &view[0][0])

    gl.BindVertexArray(system.line_vao)
    gl.BindBuffer(gl.ARRAY_BUFFER, system.line_vbo)
    gl.BufferSubData(gl.ARRAY_BUFFER, 0, size_of(Debug_Line) * DEBUG_LINE_CAP, &system.line_data[0])

    gl.DrawArrays(gl.POINTS, 0, system.line_len)

    system.line_len = 0
}
