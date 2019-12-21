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
    /*
     * Initialize the pixel data with opaque black color.
     */
    for (png_uint_32 i = 0; i < buffer->actual_width * buffer->actual_height; i++) {
        buffer->data[4 * i + 0] = 0xFF;
        buffer->data[4 * i + 1] = 0x00;
        buffer->data[4 * i + 2] = 0x00;
        buffer->data[4 * i + 3] = 0xFF;
    }
}

static void allocate_texture_row_pointers(png_structp png,
                                          struct texture_buffer *buffer)
{
    /*
     * Now allocate, prepare and set the row pointers.
     * Note that OpenGL reads textures bottom-up while PNG is stored top-down.
     */
    buffer->rows = png_malloc(png, buffer->height * sizeof(png_bytep));
    if (!buffer->rows) {
        fprintf(stderr, "allocation error: cannot allocate %u row pointers\n",
                buffer->height);
        return;
    }
    for (png_uint_32 y = 0; y < buffer->height; y++) {
        buffer->rows[y] = &buffer->data[4 * (buffer->height - y) * buffer->actual_width];
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

static png_byte* texture_pixel(struct texture_buffer *src, size_t x, size_t y)
{
    return &src->data[4 * (src->actual_width * y + x)];
}

/*
 * Scale down a bitmap into a smaller bitmap for computing mipmap,
 * using linear averaging.
 *
 * Here's what we have in src:
 *
 * +---+---+---+---+
 * | 0 | 1 | 4 | 5 |
 * +---+---+---+---+
 * | 2 | 3 | 6 | 7 |
 * +---+---+---+---+
 * | 8 | 9 | C | D |
 * +---+---+---+---+
 * | A | B | E | F |
 * +---+---+---+---+
 *
 * And here's what we get in dst:
 *
 * +-------+-------+
 * |0+1+2+3|4+5+6+7|
 * | ----- | ----- |
 * |   4   |   4   |
 * +-------+-------+
 * |8+9+A+B|C+D+E+F|
 * | ----- | ----- |
 * |   4   |   4   |
 * +-------+-------+
 *
 * It's simple, but effective enough for our cause. Smarter approach would
 * cause more overlap with neighboring pixels using signal processing magic.
 *
 * We could have used SIMD here for a speedup, but given that this code is
 * executed on a cold path and can have very small texture sizes, it's not
 * really worth the complexity.
 */
static void scale_down_mipmap(struct texture_buffer *src,
                              struct texture_buffer *dst)
{
    /* Half the size, rounding up */
    dst->width = (src->width + 1) / 2;
    dst->height = (src->height + 1) / 2;
    dst->actual_width = (src->actual_width + 1) / 2;
    dst->actual_height = (src->actual_height + 1) / 2;

    for (size_t y = 0; y < dst->height; y++) {
        for (size_t x = 0; x < dst->width; x++) {
            png_uint_16 r = 0, g = 0, b = 0, a = 0;
            r += src->data[4 * (src->actual_width * (2 * y + 0) + (2 * x + 0)) + 0];
            g += src->data[4 * (src->actual_width * (2 * y + 0) + (2 * x + 0)) + 1];
            b += src->data[4 * (src->actual_width * (2 * y + 0) + (2 * x + 0)) + 2];
            a += src->data[4 * (src->actual_width * (2 * y + 0) + (2 * x + 0)) + 3];
            r += src->data[4 * (src->actual_width * (2 * y + 0) + (2 * x + 1)) + 0];
            g += src->data[4 * (src->actual_width * (2 * y + 0) + (2 * x + 1)) + 1];
            b += src->data[4 * (src->actual_width * (2 * y + 0) + (2 * x + 1)) + 2];
            a += src->data[4 * (src->actual_width * (2 * y + 0) + (2 * x + 1)) + 3];
            r += src->data[4 * (src->actual_width * (2 * y + 1) + (2 * x + 0)) + 0];
            g += src->data[4 * (src->actual_width * (2 * y + 1) + (2 * x + 0)) + 1];
            b += src->data[4 * (src->actual_width * (2 * y + 1) + (2 * x + 0)) + 2];
            a += src->data[4 * (src->actual_width * (2 * y + 1) + (2 * x + 0)) + 3];
            r += src->data[4 * (src->actual_width * (2 * y + 1) + (2 * x + 1)) + 0];
            g += src->data[4 * (src->actual_width * (2 * y + 1) + (2 * x + 1)) + 1];
            b += src->data[4 * (src->actual_width * (2 * y + 1) + (2 * x + 1)) + 2];
            a += src->data[4 * (src->actual_width * (2 * y + 1) + (2 * x + 1)) + 3];
            dst->data[4 * (dst->actual_width * y + x) + 0] = r / 4;
            dst->data[4 * (dst->actual_width * y + x) + 1] = g / 4;
            dst->data[4 * (dst->actual_width * y + x) + 2] = b / 4;
            dst->data[4 * (dst->actual_width * y + x) + 3] = a / 4;
        }
    }
}

static GLuint load_png_texture(png_structp png, png_infop png_info)
{
    GLuint texture = 0;
    struct texture_buffer buffer;
    struct texture_buffer mipmap;

    memset(&buffer, 0, sizeof(buffer));
    memset(&mipmap, 0, sizeof(mipmap));

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
    allocate_texture_buffer(png, png_info, &mipmap);
    allocate_texture_row_pointers(png, &buffer);
    if (!buffer.data || !buffer.rows || !mipmap.data) {
        goto error;
    }

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
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST_MIPMAP_LINEAR);
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST_MIPMAP_NEAREST);

    GLint current_lod = 0;
    struct texture_buffer *curr_buffer = &buffer;
    struct texture_buffer *next_mipmap = &mipmap;
    struct texture_buffer *tmp = NULL;
    for (;;) {
        clamp_texture_buffer_edges(curr_buffer);

        glTexImage2D(GL_TEXTURE_2D,
                     current_lod,       /* level of detail */
                     GL_RGBA,           /* internal format */
                     curr_buffer->actual_width,
                     curr_buffer->actual_height,
                     0,                 /* border, must be 0 */
                     GL_RGBA,           /* data format */
                     GL_UNSIGNED_BYTE,  /* data type */
                     curr_buffer->data);
        /* We stop at 1x1 mipmap texture */
        if (curr_buffer->actual_width == 1 || curr_buffer->actual_height == 1) {
            break;
        }
        scale_down_mipmap(curr_buffer, next_mipmap);
        tmp = curr_buffer;
        curr_buffer = next_mipmap;
        next_mipmap = tmp;
        current_lod++;
    }

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
