package imdd

import gl "vendor:OpenGL"

Framebuffer :: struct {
    width: i32,
    height: i32,

    fbo: u32,
    color_tbo: u32,
    normal_tbo: u32,
    depth_tbo: u32
}

make_framebuffer :: proc(framebuffer: ^Framebuffer, width: i32, height: i32) {
    framebuffer.width = width
    framebuffer.height = height

    gl.GenFramebuffers(1, &framebuffer.fbo)
    gl.BindFramebuffer(gl.FRAMEBUFFER, framebuffer.fbo)

    // color buffer
    gl.GenTextures(1, &framebuffer.color_tbo)
    gl.BindTexture(gl.TEXTURE_2D, framebuffer.color_tbo)
    gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA32F, width, height, 0, gl.RGBA, gl.FLOAT, nil)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
    gl.FramebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, framebuffer.color_tbo, 0)

    // normal buffer
    gl.GenTextures(1, &framebuffer.normal_tbo)
    gl.BindTexture(gl.TEXTURE_2D, framebuffer.normal_tbo)
    gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA32F, width, height, 0, gl.RGBA, gl.FLOAT, nil)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
    gl.FramebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT1, gl.TEXTURE_2D, framebuffer.normal_tbo, 0)

    // draw buffers
    draw_buffers := []u32{gl.COLOR_ATTACHMENT0, gl.COLOR_ATTACHMENT1}
    gl.DrawBuffers(2, &draw_buffers[0])

    // depth buffer
    gl.GenTextures(1, &framebuffer.depth_tbo)
    gl.BindTexture(gl.TEXTURE_2D, framebuffer.depth_tbo)
    gl.TexImage2D(gl.TEXTURE_2D, 0, gl.DEPTH_COMPONENT24, width, height, 0, gl.DEPTH_COMPONENT, gl.FLOAT, nil)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
    gl.FramebufferTexture2D(gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT, gl.TEXTURE_2D, framebuffer.depth_tbo, 0)

    gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
}

delete_framebuffer :: proc(framebuffer: ^Framebuffer) {
    gl.DeleteFramebuffers(1, &framebuffer.fbo)
    gl.DeleteTextures(1, &framebuffer.color_tbo)
    gl.DeleteTextures(1, &framebuffer.normal_tbo)
    gl.DeleteTextures(1, &framebuffer.depth_tbo)
}

resize_buffer :: proc(framebuffer: ^Framebuffer, width: i32, height: i32) {
    framebuffer.width = width
    framebuffer.height = height

    // color buffer
    gl.BindTexture(gl.TEXTURE_2D, framebuffer.color_tbo)
    gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA32F, width, height, 0, gl.RGBA, gl.FLOAT, nil)

    // normal buffer
    gl.BindTexture(gl.TEXTURE_2D, framebuffer.normal_tbo)
    gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGB16F, width, height, 0, gl.RGB, gl.FLOAT, nil)

    // depth buffer
    gl.BindTexture(gl.TEXTURE_2D, framebuffer.depth_tbo)
    gl.TexImage2D(gl.TEXTURE_2D, 0, gl.DEPTH_COMPONENT24, width, height, 0, gl.DEPTH_COMPONENT, gl.FLOAT, nil)
}

bind_framebuffer :: proc(framebuffer: ^Framebuffer) {
    gl.BindFramebuffer(gl.FRAMEBUFFER, framebuffer.fbo)
}
