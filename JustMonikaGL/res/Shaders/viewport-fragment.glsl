#version 330 core

in  vec2 UV;
out vec4 color;

uniform bool useBlur;
uniform float blurParameter;
uniform sampler2DRect sampler;

// Use a simple Gaussian blur with a 3x3 kernel. This can be done more
// efficiently with two separate passes, but FBOs are such a royal pain
// to deal with that I'd rather convolute directly. Since the kernel is
// small, don't use too big radius to avoid ringing.
vec4 gaussianBlur(in sampler2DRect sampler, in vec2 uv)
{
    float r = blurParameter;
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
    // If we're drawing a preview then blur the output for nicer downsampling,
    // otherwise just pass through color as is
    if (useBlur) {
        color = gaussianBlur(sampler, UV);
    } else {
        color = texture(sampler, UV);
    }
}
