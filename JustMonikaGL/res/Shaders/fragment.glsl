#version 330 core

in vec2 UV;
out vec4 canvas;
uniform mat4 vertexUV_transform;
uniform sampler2D mask_2;
uniform sampler2D mask_3;
uniform sampler2D monika_bg;
uniform sampler2D monika_bg_highlight;
uniform float time;

vec4 getPixel(in sampler2D sampler, in vec2 uv)
{
    return texture(sampler, vec2(vertexUV_transform * vec4(uv, 0.0, 1.0)));
}

void draw(inout vec4 canvas, in vec4 color)
{
    canvas = (1.0 - color.a) * canvas + color.a * color;
}

vec4 blend(in vec4 src, in vec4 dst, in float k)
{
    return clamp((1.0 - k) * src + k * dst, 0.0, 1.0);
}

vec2 mask_2_transform(in vec2 uv)
{
    const float width = 1280.0;
    const float duration = 1200.0;
    float offset = width * clamp(time / duration, 0.0, 1.0);
    return vec2(mod(uv.x + offset, width), uv.y);
}

vec2 mask_3_transform(in vec2 uv)
{
    const float width = 1280.0;
    const float duration = 180.0;
    float offset = width * clamp(time / duration, 0.0, 1.0);
    return vec2(mod(uv.x + offset, width), uv.y);
}

float monika_alpha()
{
    return pow(sin(time / 8.0), 64.0) * 1.4;
}

void main()
{
    canvas = vec4(0.0, 0.0, 0.0, 0.0);
    draw(canvas, getPixel(mask_2, mask_2_transform(UV)));
    draw(canvas, getPixel(mask_3, mask_3_transform(UV)));
    vec4 backdrop  = getPixel(monika_bg, UV);
    vec4 highlight = getPixel(monika_bg_highlight, UV);
    draw(canvas, blend(backdrop, highlight, monika_alpha()));
}
