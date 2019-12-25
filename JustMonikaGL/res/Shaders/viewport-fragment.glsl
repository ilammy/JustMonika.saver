// SPDX-License-Identifier: Apache-2.0
// JustMonikaGL
// Copyright (c) 2019 ilammy's tearoom

#version 330 core

in  vec2 UV;
out vec4 color;

uniform float blurRadius;
uniform sampler2DRect sampler;

// Use a simple Gaussian blur with a 3x3 kernel. This can be done more
// efficiently with two separate passes, but FBOs are such a royal pain
// to deal with that I'd rather convolute directly. Since the kernel is
// small, don't use too big radius to avoid ringing.
vec4 gaussianBlur(in sampler2DRect sampler, in vec2 uv, in float r)
{
    if (r == 0.0) {
        return texture(sampler, uv);
    }
    float d = r * 0.707107;
    vec3 soffset = vec3(-r, 0.0, r);
    vec2 doffset = vec2(-d, d);
    vec4 color = vec4(0.0);
    color += 0.2500 * texture(sampler, uv);
    color += 0.1250 * texture(sampler, uv + soffset.xy);
    color += 0.1250 * texture(sampler, uv + soffset.zy);
    color += 0.1250 * texture(sampler, uv + soffset.yx);
    color += 0.1250 * texture(sampler, uv + soffset.yz);
    color += 0.0625 * texture(sampler, uv + doffset.xx);
    color += 0.0625 * texture(sampler, uv + doffset.xy);
    color += 0.0625 * texture(sampler, uv + doffset.yx);
    color += 0.0625 * texture(sampler, uv + doffset.yy);
    return color;
}

void main()
{
    // Blur the output for for nicer downsampling when drawing preview
    color = gaussianBlur(sampler, UV, blurRadius);
}
