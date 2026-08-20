#pragma once

#include <stddef.h>
#include <stdint.h>

struct header {
  uint32_t width;
  uint32_t height;
};

typedef void* (*malloc_fn)(size_t n, size_t align);

void set_malloc(malloc_fn);
void* decode_rapid_qoi(const void *bytes, size_t len, struct header *hdr);
void* decode_qoi_rust(const void *bytes, size_t len, struct header *hdr);
