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

#include "context.h"
#include "opengl.h"

static void print_error_to_stderr(png_structp png, png_const_charp error)
{
    fprintf(stderr, "libpng error: %s\n", error);
}

static png_uint_32 closest_power_of_two(png_uint_32 value)
{
    png_uint_32 size = 1;
    /* Edge case */
    if (value == 0) {
        return 0;
    }
    /* Multiplication may overflow for invalid PNGs */
    while (size <= value && size != 0) {
        size *= 2;
    }
    return size;
}

static png_uint_32 max(png_uint_32 a, png_uint_32 b)
{
    return (a > b) ? a : b;
}

struct texture_buffer {
    png_uint_32 width;
    png_uint_32 height;
    png_uint_32 actual_width;
    png_uint_32 actual_height;
    png_byte *data;
    png_byte **rows;
};

static void allocate_texture_buffer(png_structp png, png_infop png_info,
                                    struct texture_buffer *buffer)
{
    buffer->width = png_get_image_width(png, png_info);
    buffer->height = png_get_image_height(png, png_info);
    png_uint_32 size = max(closest_power_of_two(buffer->width),
                           closest_power_of_two(buffer->height));
    buffer->actual_width = size;
    buffer->actual_height = size;
    buffer->data = NULL;
    buffer->rows = NULL;

    /*
     * We use RGBA format which means 4 bytes per pixel.
     * We need a square of stride x stride size.
     * Carefully avoid overflows (should not happen in practice).
     */
    if (buffer->actual_height == 0 || buffer->actual_width == 0) {
        fprintf(stderr, "allocation error: invalid PNG size: %ux%u\n",
                buffer->actual_width, buffer->actual_height);
        return;
    }
    if (buffer->actual_height > (PNG_SIZE_MAX / 4) / buffer->actual_width) {
        fprintf(stderr, "allocation error: size overflow in %ux%u buffer\n",
                buffer->actual_width, buffer->actual_height);
        return;
    }

    buffer->data = png_malloc(png, 4 * buffer->actual_width * buffer->actual_height);
    if (!buffer->data) {
        fprintf(stderr, "allocation error: cannot allocate %ux%u buffer\n",
                buffer->actual_width, buffer->actual_height);
        return;
    }
    memset(buffer->data, 0, 4 * buffer->actual_width * buffer->actual_height);

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
        buffer->rows[y] = &buffer->data[4 * (buffer->height - 1 - y) * buffer->actual_width];
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

/*
 * Copy a single pixel from image edge into the outer rim in order for upscale
 * filters to produce good results without the background color bleeding in.
 * This border is required because we effectively use "texture atlas" (albeit,
 * with only a single texture in it). And this effectively simulates behavior
 * of GL_CLAMP_TO_EDGE wrapping for that one texel in an atlas.
 *
 *                | OpenGL width (2048 px) |
 *
 *           --   +-----------------+------+   --  bottom
 *                |78888888888888889|9    7|
 *                |45555555555555556|6    4|
 *                |45555555555555556|6    4|  Image height
 *                |45555555555555556|6    4|    (720 px)
 * OpenGL height  |45555555555555556|6    4|
 *   (2048 px)    |12222222222222223|3    1|
 *                +-----------------+------+   --  top
 *                |12222222222222223|3    1|
 *                |                 |      |
 *                |78888888888888889|9    7|
 *           --   +-----------------+------+
 *
 *                |   Image width   |
 *                     (1280 px)
 */
static void clamp_texture_buffer_edges(struct texture_buffer *buffer)
{
    const size_t stride = 4 * buffer->actual_width;
    const size_t width = 4 * buffer->width;

    /* 12222222222222223 row */
    memcpy(&buffer->data[stride * (buffer->height + 0)],
           &buffer->data[stride * (buffer->height - 1)],
           width);

    /* 78888888888888889 row */
    memcpy(&buffer->data[stride * (buffer->actual_height - 1)],
           &buffer->data[stride * 0],
           width);

    for (size_t y = 0; y < buffer->height; y++) {
        /* 366669 column */
        memcpy(&buffer->data[stride * y + width + 0],
               &buffer->data[stride * y + width - 4],
               4);

        /* 144447 column */
        memcpy(&buffer->data[stride * y + stride - 4],
               &buffer->data[stride * y + 0],
               4);
    }

    /* 3 corner */
    memcpy(&buffer->data[stride * buffer->height + width + 0],
           &buffer->data[stride * buffer->height + width - 4],
           4);

    /* 1 corner */
    memcpy(&buffer->data[stride * buffer->height + stride - 4],
           &buffer->data[stride * buffer->height + 0],
           4);

    /* 9 corner */
    memcpy(&buffer->data[stride * buffer->height + width + 0],
           &buffer->data[stride * buffer->height + width - 4],
           4);

    /* 7 corner */
    memcpy(&buffer->data[stride * (buffer->actual_height - 1) + stride - 4],
           &buffer->data[stride * (buffer->actual_height - 1) + 0],
           4);
}

static GLuint load_png_texture(png_structp png, png_infop png_info)
{
    GLuint texture = 0;
    struct texture_buffer buffer;

    memset(&buffer, 0, sizeof(buffer));

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

    clamp_texture_buffer_edges(&buffer);

    /*
     * Now actually load the texture into the GPU.
     */
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexImage2D(GL_TEXTURE_2D,
                 0,                 /* base image level */
                 GL_RGBA,           /* internal format */
                 buffer.actual_width,
                 buffer.actual_height,
                 0,                 /* border, must be 0 */
                 GL_RGBA,           /* data format */
                 GL_UNSIGNED_BYTE,  /* data type */
                 buffer.data);
    /*
     * Do not use mipmaps or anisotropic filtering. Since our texture data
     * does not fill the entire square, these filters tend to cause texture
     * bleeding which looks awful. We compensate at edges for linear filter,
     * but anything more advanced does not work right now, unfortunately.
     */
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);

error:
    destroy_texture_buffer(png, png_info, &buffer);

    return texture;
}

static void read_data(png_structp png, png_bytep data, size_t length)
{
    struct resource_file *image = png_get_io_ptr(png);

    while (length > 0) {
        size_t result = read_resource(image, data, length);
        if (!result) {
            png_error(png, "failed to read PNG data");
            return;
        }
        data += result;
        length -= result;
    }
}

GLuint load_texture(struct resource_file *image)
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

    png_set_read_fn(png, image, read_data);

    texture = load_png_texture(png, png_info);

error:
    png_destroy_read_struct(&png, &png_info, NULL);

    return texture;
}
