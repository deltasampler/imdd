package imdd

import glm "core:math/linalg/glsl"
import gl "vendor:OpenGL"

Debug_Mesh_Vertex :: struct {
    position: glm.vec3,
    normal: glm.vec3,
    color: i32
}

Debug_Mesh_Triangle :: struct {
    a: u32,
    b: u32,
    c: u32
}

Debug_Mesh :: struct {
    // cpu
    vertices: [dynamic]Debug_Mesh_Vertex,
    indices: [dynamic]Debug_Mesh_Triangle,

    // gpu
    vao: u32,
    vbo: u32,
    ibo: u32
}

debug_mesh :: proc(mesh: ^Debug_Mesh) {
    system.mesh_data[system.mesh_len] = mesh
    system.mesh_len = (system.mesh_len + 1) % DEBUG_MESH_CAP
}

debug_mesh_box :: proc(mesh: ^Debug_Mesh, position: glm.vec3, size: glm.vec3) {
    index := u32(len(mesh.vertices))

    min := position - size / 2
    max := position + size / 2

    append(&mesh.vertices,
        // left
        Debug_Mesh_Vertex{{min.x, min.y, min.z}, {-1, 0, 0}, 0xff0000},
        Debug_Mesh_Vertex{{min.x, min.y, max.z}, {-1, 0, 0}, 0xff0000},
        Debug_Mesh_Vertex{{min.x, max.y, max.z}, {-1, 0, 0}, 0xff0000},
        Debug_Mesh_Vertex{{min.x, max.y, min.z}, {-1, 0, 0}, 0xff0000},

        // right
        Debug_Mesh_Vertex{{max.x, min.y, max.z}, {1, 0, 0}, 0x00ff00},
        Debug_Mesh_Vertex{{max.x, min.y, min.z}, {1, 0, 0}, 0x00ff00},
        Debug_Mesh_Vertex{{max.x, max.y, min.z}, {1, 0, 0}, 0x00ff00},
        Debug_Mesh_Vertex{{max.x, max.y, max.z}, {1, 0, 0}, 0x00ff00},

        // bottom
        Debug_Mesh_Vertex{{min.x, min.y, min.z}, {0, -1, 0}, 0x0000ff},
        Debug_Mesh_Vertex{{max.x, min.y, min.z}, {0, -1, 0}, 0x0000ff},
        Debug_Mesh_Vertex{{max.x, min.y, max.z}, {0, -1, 0}, 0x0000ff},
        Debug_Mesh_Vertex{{min.x, min.y, max.z}, {0, -1, 0}, 0x0000ff},

        // top
        Debug_Mesh_Vertex{{min.x, max.y, max.z}, {0, 1, 0}, 0xffff00},
        Debug_Mesh_Vertex{{max.x, max.y, max.z}, {0, 1, 0}, 0xffff00},
        Debug_Mesh_Vertex{{max.x, max.y, min.z}, {0, 1, 0}, 0xffff00},
        Debug_Mesh_Vertex{{min.x, max.y, min.z}, {0, 1, 0}, 0xffff00},

        // back
        Debug_Mesh_Vertex{{min.x, min.y, max.z}, {0, 0, 1}, 0xff00ff},
        Debug_Mesh_Vertex{{max.x, min.y, max.z}, {0, 0, 1}, 0xff00ff},
        Debug_Mesh_Vertex{{max.x, max.y, max.z}, {0, 0, 1}, 0xff00ff},
        Debug_Mesh_Vertex{{min.x, max.y, max.z}, {0, 0, 1}, 0xff00ff},

        // front
        Debug_Mesh_Vertex{{max.x, min.y, min.z}, {0, 0, -1}, 0x00ffff},
        Debug_Mesh_Vertex{{min.x, min.y, min.z}, {0, 0, -1}, 0x00ffff},
        Debug_Mesh_Vertex{{min.x, max.y, min.z}, {0, 0, -1}, 0x00ffff},
        Debug_Mesh_Vertex{{max.x, max.y, min.z}, {0, 0, -1}, 0x00ffff}

    )

    append(&mesh.indices,
        Debug_Mesh_Triangle{0, 1, 2},
        Debug_Mesh_Triangle{0, 2, 3},
        Debug_Mesh_Triangle{4, 5, 6},
        Debug_Mesh_Triangle{4, 6, 7},
        Debug_Mesh_Triangle{8, 9, 10},
        Debug_Mesh_Triangle{8, 10, 11},
        Debug_Mesh_Triangle{12, 13, 14},
        Debug_Mesh_Triangle{12, 14, 15},
        Debug_Mesh_Triangle{16, 17, 18},
        Debug_Mesh_Triangle{16, 18, 19},
        Debug_Mesh_Triangle{20, 21, 22},
        Debug_Mesh_Triangle{20, 22, 23}
    )
}

// rendering
MESH_VS :: `#version 460 core

    layout(location = 0) in vec3 i_position;
    layout(location = 1) in vec3 i_normal;
    layout(location = 2) in int i_color;

    out vec3 v_normal;
    out vec3 v_color;

    uniform mat4 u_projection;
    uniform mat4 u_view;

    vec3 int_to_rgb(int i) {
        return vec3(
            (i >> 16) & 0xFF,
            (i >> 8) & 0xFF,
            i & 0xFF
        ) / 255.0;
    }

    void main() {
        gl_Position = u_projection * u_view * vec4(i_position, 1.0);
        v_normal = i_normal;
        v_color = int_to_rgb(i_color);
    }
`

MESH_FS :: `#version 460 core
precision highp float;

in vec3 v_normal;
in vec3 v_color;

out vec4 o_frag_color;

uniform vec2 u_resolution;
uniform mat4 u_projection;
uniform mat4 u_view;
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

build_debug_mesh :: proc(mesh: ^Debug_Mesh) {
    // vao
    gl.GenVertexArrays(1, &mesh.vao)
    gl.BindVertexArray(mesh.vao)

    // vbo
    gl.GenBuffers(1, &mesh.vbo)
    gl.BindBuffer(gl.ARRAY_BUFFER, mesh.vbo)
    gl.BufferData(gl.ARRAY_BUFFER, size_of(Debug_Mesh_Vertex) * len(mesh.vertices), &mesh.vertices[0], gl.STATIC_DRAW)

    // attributes
    offset: uintptr = 0

    gl.EnableVertexAttribArray(0)
    gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of(Debug_Mesh_Vertex), offset)
    offset += size_of(glm.vec3)

    gl.EnableVertexAttribArray(1)
    gl.VertexAttribPointer(1, 3, gl.FLOAT, false, size_of(Debug_Mesh_Vertex), offset)
    offset += size_of(glm.vec3)

    gl.EnableVertexAttribArray(2)
    gl.VertexAttribIPointer(2, 1, gl.INT, size_of(Debug_Mesh_Vertex), offset)

    // ibo
    gl.GenBuffers(1, &mesh.ibo)
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, mesh.ibo)
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(Debug_Mesh_Triangle) * len(mesh.indices), &mesh.indices[0], gl.DYNAMIC_DRAW)
}

reload_debug_mesh :: proc(mesh: ^Debug_Mesh) {
    gl.BindVertexArray(mesh.vao)
    gl.BufferData(gl.ARRAY_BUFFER, size_of(Debug_Mesh_Vertex) * len(mesh.vertices), &mesh.vertices[0], gl.STATIC_DRAW)

    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, mesh.ibo)
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(Debug_Mesh_Triangle) * len(mesh.indices), &mesh.indices[0], gl.DYNAMIC_DRAW)
}

destroy_debug_mesh :: proc(mesh: ^Debug_Mesh) {
    delete(mesh.vertices)
    delete(mesh.indices)
    gl.DeleteVertexArrays(1, &mesh.vao)
    gl.DeleteBuffers(1, &mesh.vbo)
    gl.DeleteBuffers(1, &mesh.ibo)
}

init_mesh_rdr :: proc() {
    // data
    system.mesh_data = make([dynamic]^Debug_Mesh, DEBUG_MESH_CAP, DEBUG_MESH_CAP)

    // shaders
    make_shader(&system.mesh_shader, gl.load_shaders_source(MESH_VS, MESH_FS))
}

free_mesh_rdr :: proc() {
    delete_shader(&system.mesh_shader)
}

render_mesh_rdr :: proc(viewport: ^glm.ivec2, projection: ^glm.mat4, view: ^glm.mat4) {
    gl.Enable(gl.CULL_FACE); defer gl.Disable(gl.CULL_FACE)

    uniforms := &system.mesh_shader.uniforms

    use_shader(&system.mesh_shader)
    gl.Uniform2f(uniforms["u_resolution"] - 1, f32(viewport.x), f32(viewport.y))
    gl.UniformMatrix4fv(uniforms["u_projection"] - 1, 1, false, &projection[0][0])
    gl.UniformMatrix4fv(uniforms["u_view"] - 1, 1, false, &view[0][0])

    for i in 0 ..< system.mesh_len {
        mesh := system.mesh_data[i]

        gl.BindVertexArray(mesh.vao)
        gl.DrawElements(gl.TRIANGLES, cast(i32) len(mesh.indices) * 3, gl.UNSIGNED_INT, nil)
    }

    system.mesh_len = 0
}
