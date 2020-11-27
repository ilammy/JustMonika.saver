/* SPDX-License-Identifier: Apache-2.0 */
/* JustMonikaGL, (c) 2019 ilammy's tearoom */

#include "resource.h"

#include <stdio.h>
#include <stdlib.h>

#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>

struct resource_file {
    FILE *fp;
};

static NSString* resource_path(const char *name)
{
    NSBundle *thisBundle = [NSBundle bundleWithIdentifier:@"net.ilammy.JustMonikaGL"];
    NSString *resourceName = [NSString stringWithCString:name
                                                encoding:NSUTF8StringEncoding];
    NSString *resourcePath;
    if ([resourceName hasSuffix:@".png"]) {
        resourcePath = [[[thisBundle resourcePath]
                         stringByAppendingPathComponent:@"Monika"]
                        stringByAppendingPathComponent:resourceName];
    }
    if ([resourceName hasSuffix:@".glsl"]) {
        resourcePath = [[[thisBundle resourcePath]
                         stringByAppendingPathComponent:@"Shaders"]
                        stringByAppendingPathComponent:resourceName];
    }
    return resourcePath;
}

struct resource_file* open_resource(const char *name)
{
    NSString *resourcePath = resource_path(name);
    if (!resourcePath) {
        return NULL;
    }

    struct resource_file *resource = malloc(sizeof(*resource));
    if (!resource) {
        return NULL;
    }

    const char *resourceCPath = [resourcePath cStringUsingEncoding:NSUTF8StringEncoding];
    resource->fp = fopen(resourceCPath, "rb");
    if (!resource->fp) {
        free(resource);
        return NULL;
    }

    return resource;
}

void free_resource(struct resource_file *resource)
{
    if (resource) {
        fclose(resource->fp);
        free(resource);
    }
}

size_t read_resource(struct resource_file *resource, uint8_t *buffer, size_t size)
{
    if (!resource) {
        return 0;
    }
    return fread(buffer, sizeof(uint8_t), size, resource->fp);
}

static size_t get_resource_size(struct resource_file *resource)
{
    size_t length = 0;
    if (resource && resource->fp) {
        fseek(resource->fp, 0, SEEK_END);
        length = ftell(resource->fp);
        rewind(resource->fp);
    }
    return length;
}

size_t load_resource(const char *name, uint8_t **buffer)
{
    struct resource_file *resource = NULL;
    size_t read = 0;
    size_t total = 0;
    ssize_t remaining = 0;
    uint8_t *next = NULL;

    resource = open_resource(name);
    remaining = get_resource_size(resource);

    next = realloc(*buffer, remaining);
    if (!next) {
        goto error;
    }
    *buffer = next;

    while (remaining > 0) {
        read = read_resource(resource, next, remaining);
        if (read == 0) {
            break;
        }
        next += read;
        total += read;
        remaining -= read;
    }

error:
    free_resource(resource);

    return total;
}

void load_png_resource(const char *name, uint8_t **rgba,
                       size_t *width, size_t *height)
{
    // First, open the image.
    NSString *resourcePath = resource_path(name);
    const char *resourceCPath = [resourcePath cStringUsingEncoding:NSUTF8StringEncoding];
    CGDataProviderRef data = CGDataProviderCreateWithFilename(resourceCPath);
    CGImageRef image = CGImageCreateWithPNGDataProvider(data,
                                                        NULL,  // decode array
                                                        false, // shouldInterpolate
                                                        kCGRenderingIntentDefault);
    CFRelease(data);

    // Now create a context to decode the image into.
    // Note that OpenGL needs RGBA component layout.
    CGContextRef context =
        CGBitmapContextCreate(NULL, // data
                              CGImageGetWidth(image),
                              CGImageGetHeight(image),
                              8, // bits per component
                              4 * CGImageGetWidth(image),
                              CGImageGetColorSpace(image),
                              kCGImageAlphaPremultipliedLast);

    // Flip the context upside down because OpenGL expects origin to be in
    // the top-left corner while Quartz2D has it in the bottom-left one.
    CGContextTranslateCTM(context, 0, CGImageGetHeight(image));
    CGContextScaleCTM(context, 1, -1);

    // Draw the image into context, extracting its pixel values.
    CGRect rect = CGRectMake(0, 0, CGImageGetWidth(image), CGImageGetHeight(image));
    CGContextDrawImage(context, rect, image);

    // Copy RGBA pixel values into output buffer.
    size_t total_size = 4 * CGImageGetWidth(image) * CGImageGetHeight(image);
    *width = CGImageGetWidth(image);
    *height = CGImageGetHeight(image);
    *rgba = malloc(total_size);
    if (!*rgba) {
        goto error;
    }
    memcpy(*rgba, CGBitmapContextGetData(context), total_size);

error:
    CFRelease(context);
    CFRelease(image);
}
