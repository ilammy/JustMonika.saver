//
//  texture.c
//  JustMonikaGL
//
//  Created by Alexei Lozovsky on 2019-11-28.
//  Copyright © 2019 ilammy's tearoom. All rights reserved.
//

#include "texture.h"

#include <string.h>

#include <libpng/png.h>

#include "opengl.h"

typedef PNG_CALLBACK(void, *png_error_ptr, (png_structp, png_const_charp));

static void print_error_to_stderr(png_structp png, png_const_charp error)
{
    fprintf(stderr, "libpng error: %s\n", error);
}

/*
 * OpenGL is more performant and predictable if we use squares that have
 * power-of-two sides.
 */
static png_uint_32 closest_power_of_two(png_uint_32 width, png_uint_32 height)
{
    png_uint_32 max = (width > height) ? width : height;
    png_uint_32 size = 1;
    /* Edge case */
    if (max == 0) {
        return 0;
    }
    /* Multiplication may overflow for invalid PNGs */
    while (size <= max && size != 0) {
        size *= 2;
    }
    return size;
}

struct texture_buffer {
    png_uint_32 width;
    png_uint_32 height;
    png_uint_32 stride;
    png_byte *data;
    png_byte **rows;
};

static void allocate_texture_buffer(png_structp png, png_infop png_info,
                                    struct texture_buffer *buffer)
{
    buffer->width = png_get_image_width(png, png_info);
    buffer->height = png_get_image_height(png, png_info);
    buffer->stride = closest_power_of_two(buffer->width, buffer->height);
    buffer->data = NULL;
    buffer->rows = NULL;

    /*
     * We use RGBA format which means 4 bytes per pixel.
     * We need a square of stride x stride size.
     * Carefully avoid overflows (should not happen in practice).
     */
    if (buffer->stride > (PNG_SIZE_MAX / 4) / buffer->stride) {
        fprintf(stderr, "allocation error: size overflow in %ux%u buffer\n",
                buffer->stride, buffer->stride);
        return;
    }
    buffer->data = png_malloc(png, 4 * buffer->stride * buffer->stride);
    if (!buffer->data) {
        fprintf(stderr, "allocation error: cannot allocate %ux%u buffer\n",
                buffer->stride, buffer->stride);
        return;
    }
    /*
     * Initialize the pixel data with opaque black color.
     */
    for (png_uint_32 i = 0; i < buffer->stride * buffer->stride; i++) {
        buffer->data[4 * i + 0] = 0x00;
        buffer->data[4 * i + 1] = 0x00;
        buffer->data[4 * i + 2] = 0x00;
        buffer->data[4 * i + 3] = 0xFF;
    }

    /*
     * Now allocate, prepare and set the row pointers.
     * Note that OpenGL reads textures bottom-up while PNG is stored top-down.
     */
    buffer->rows = png_malloc(png, buffer->height * sizeof(png_bytep));
    if (!buffer->rows) {
        fprintf(stderr, "allocation error: cannot allocate %u row pointers\n",
                buffer->height);
        png_free(png, buffer->data);
        buffer->data = NULL;
        return;
    }
    for (png_uint_32 y = 0; y < buffer->height; y++) {
        buffer->rows[y] = &buffer->data[(buffer->height - y) * buffer->stride];
    }
}

static void destroy_texture_buffer(png_structp png, png_infop png_info,
                                   struct texture_buffer *buffer)
{
    png_free(png, buffer->data);
    png_free(png, buffer->rows);
    buffer->data = NULL;
    buffer->rows = NULL;
}

static GLuint load_png_texture(png_structp png, png_infop png_info)
{
    GLuint texture = 0;
    struct texture_buffer buffer;

    /*
     * libpng uses longjmp() for error recovery. png_read_info()
     * will jump here in case of any errors. Ditto elsewhere.
     */
    if (setjmp(png_jmpbuf(png))) {
        goto error;
    }
    png_read_info(png, png_info);

    /*
     * We expect to load only RGBA images so save ourselves trouble
     * of configuring proper PNG transformations.
     */
    png_byte color_type = png_get_color_type(png, png_info);
    if (color_type != PNG_COLOR_TYPE_RGBA) {
        fprintf(stderr, "format error: unsupported color type: 0x%02X\n",
                color_type);
        goto error;
    }

    allocate_texture_buffer(png, png_info, &buffer);

    if (setjmp(png_jmpbuf(png))) {
        goto error;
    }
    png_read_image(png, buffer.rows);

    if (setjmp(png_jmpbuf(png))) {
        goto error;
    }
    png_read_end(png, NULL);

    /*
     * Now actually load the texture into the GPU.
     */
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexImage2D(GL_TEXTURE_2D,
                 0,                 /* base image level */
                 GL_RGBA,           /* internal format */
                 buffer.stride,     /* width */
                 buffer.stride,     /* height */
                 0,                 /* border, must be 0 */
                 GL_RGBA,           /* data format */
                 GL_UNSIGNED_BYTE,  /* data type */
                 buffer.data);
error:
    destroy_texture_buffer(png, png_info, &buffer);

    return texture;
}

GLuint load_texture(FILE *fp)
{
    GLuint texture = 0;
    png_structp png = NULL;
    png_infop png_info = NULL;

    png = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL,
                                 print_error_to_stderr,
                                 print_error_to_stderr);
    if (!png) {
        goto error;
    }

    png_info = png_create_info_struct(png);
    if (!png_info) {
        goto error;
    }

    png_init_io(png, fp);

    texture = load_png_texture(png, png_info);

error:
    png_destroy_read_struct(&png, &png_info, NULL);

    return texture;
}
