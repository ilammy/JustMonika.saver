//
//  resource_macos.m
//  JustMonikaGL
//
//  Created by Alexei Lozovsky on 2019-11-30.
//  Copyright © 2019 ilammy's tearoom. All rights reserved.
//

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

size_t load_resource(const char *name, uint8_t *buffer, size_t size)
{
    struct resource_file *resource = NULL;
    size_t read = 0;
    size_t total = 0;

    resource = open_resource(name);

    for (;;) {
        read = read_resource(resource, buffer, size);
        if (read == 0) {
            break;
        }
        buffer += read;
        total += read;
        size -= read;
    }

    free_resource(resource);

    return total;
}
