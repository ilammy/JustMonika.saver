//
//  resource.h
//  JustMonikaGL
//
//  Created by Alexei Lozovsky on 2019-11-30.
//  Copyright © 2019 ilammy's tearoom. All rights reserved.
//

#ifndef JUST_MONIKA_GL_PRIVATE_RESOURCE_H
#define JUST_MONIKA_GL_PRIVATE_RESOURCE_H

#include <stddef.h>
#include <stdint.h>

struct resource_file;

struct resource_file* open_resource(const char *name);

void free_resource(struct resource_file *resource);

size_t read_resource(struct resource_file *resource, uint8_t *buffer, size_t size);

size_t load_resource(const char *name, uint8_t *buffer, size_t size);

#endif /* JUST_MONIKA_GL_PRIVATE_RESOURCE_H */
