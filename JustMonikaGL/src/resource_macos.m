/* SPDX-License-Identifier: Apache-2.0 */
/* JustMonikaGL, (c) 2019 ilammy's tearoom */

#include "resource.h"

#include <stdio.h>
#include <stdlib.h>

#import <Foundation/Foundation.h>

struct resource_file {
    FILE *fp;
};

struct resource_file* open_resource(const char *name)
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
