/* SPDX-License-Identifier: Apache-2.0 */
/* JustMonikaGL, (c) 2019 ilammy's tearoom */

#ifndef JUST_MONIKA_GL_PRIVATE_RESOURCE_H
#define JUST_MONIKA_GL_PRIVATE_RESOURCE_H

#include <stddef.h>
#include <stdint.h>

struct resource_file;

struct resource_file* open_resource(const char *name);

void free_resource(struct resource_file *resource);

size_t read_resource(struct resource_file *resource, uint8_t *buffer, size_t size);

size_t load_resource(const char *name, uint8_t **buffer);

#endif /* JUST_MONIKA_GL_PRIVATE_RESOURCE_H */
