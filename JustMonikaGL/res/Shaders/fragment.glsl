#version 330 core

in vec2 UV;
out vec4 color;
uniform mat4 vertexUV_transform;
uniform sampler2D monika_bg;
uniform sampler2D monika_bg_highlight;
uniform float time;

vec4 getPixel(in sampler2D sampler, in vec2 uv)
{
    return texture(sampler, vec2(vertexUV_transform * vec4(uv, 0.0, 1.0)));
}

vec4 blend(in vec4 src, in vec4 dst, in float k)
{
    return clamp((1.0 - k) * src + k * dst, 0.0, 1.0);
}

// Called "monika_alpha" in DDLC source code
float monika_alpha()
{
    return pow(sin(time / 8.0), 64.0) * 1.4;
}

void main()
{
    vec4 backdrop  = getPixel(monika_bg, UV);
    vec4 highlight = getPixel(monika_bg_highlight, UV);
    color = blend(backdrop, highlight, monika_alpha());
}
