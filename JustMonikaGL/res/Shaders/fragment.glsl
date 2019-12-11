#version 330 core

in vec2 UV;
out vec4 canvas;
uniform sampler2D mask;
uniform sampler2D maskb;
uniform sampler2D mask_2;
uniform sampler2D mask_3;
uniform sampler2D monika_bg;
uniform sampler2D monika_bg_highlight;
uniform float time;

// All our textures have 2048 x 1048 size in memory and have 1280 x 720
// starting at origin filled with actually userful data. UV coordinates
// are expressed in source image coordinates.
const vec2 textureSize = vec2(2048.0, 1024.0);
const vec2 imageSize   = vec2(1280.0,  720.0);

vec4 getPixel(in sampler2D sampler, in vec2 uv)
{
    const mat4 textureTransform = mat4(
        1.0/textureSize.x, 0.0, 0.0, 0.0,
        0.0, 1.0/textureSize.y, 0.0, 0.0,
        0.0,               0.0, 1.0, 0.0,
        0.0,               0.0, 0.0, 1.0
    );
    vec4 spatial = vec4(mod(uv, imageSize), 0.0, 1.0);
    return texture(sampler, vec2(textureTransform * spatial));
}

void draw(inout vec4 canvas, in vec4 color)
{
    canvas = (1.0 - color.a) * canvas + color.a * color;
}

void overlay(inout vec4 canvas, in vec4 color)
{
    canvas = clamp(canvas + color, 0.0, 1.0);
}

vec4 blend(in vec4 src, in vec4 dst, in float k)
{
    return clamp((1.0 - k) * src + k * dst, 0.0, 1.0);
}

float amplify(float a, float offset, float scale)
{
    return clamp(scale * (a + offset) - (scale - 1.0) / 2.0, 0.0, 1.0);
}

const vec2 windowSize     = vec2(320.0, 180.0);
const vec2 windowPosLeft  = vec2( 30.0, 340.0);
const vec2 windowPosRight = vec2(935.0, 340.0);
const vec2 shiftALeft     = vec2(  0.0,   0.0);
const vec2 shiftARight    = vec2(  0.0,   0.0);

vec4 WindowMask(in vec4 tint, bool flip, float bias, float scale,
                in vec2 size, in vec2 pos,
                in vec2 shiftA)
{
    if (UV.x < pos.x || pos.x + size.x < UV.x ||
        UV.y < pos.y || pos.y + size.y < UV.y)
    {
        return vec4(0.0, 0.0, 0.0, 0.0);
    }

    vec2 posA = UV + shiftA;
    posA.x += 2.0 * 1280.0 + mod(50.0 * time, 2.0 * 1280.0);

    const mat4 maskbTransform = mat4(
        0.6 * imageSize.x / windowSize.x, 0.0, 0.0, 0.0,
        0.0, 1.0 * imageSize.y / windowSize.y, 0.0, 0.0,
        0.0,                              0.0, 1.0, 0.0,
        2.7 * windowSize.x,               0.0, 0.0, 1.0
    );
    vec2 posB = vec2(maskbTransform * vec4(UV - pos, 0.0, 1.0));

    vec4 light = vec4(0.0, 0.0, 0.0, 0.0);
    draw(light, getPixel(mask,  posA));
    draw(light, getPixel(maskb, posB));

    float offset = bias + pow(sin(time / 8.0), 64.0) * 0.5;

    return tint * amplify(light.a, offset, scale);
}

vec2 mask_2_transform(in vec2 uv)
{
    const float duration = 1200.0;
    float offset = imageSize.x * clamp(time / duration, 0.0, 1.0);
    return vec2(mod(uv.x + offset, imageSize.x), uv.y);
}

vec2 mask_3_transform(in vec2 uv)
{
    const float duration = 180.0;
    float offset = imageSize.x * clamp(time / duration, 0.0, 1.0);
    return vec2(mod(uv.x + offset, imageSize.x), uv.y);
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
    const vec4 orange = vec4(1.0, 0.375, 0.0, 1.0);
    const vec4 white  = vec4(1.0, 1.0,   1.0, 1.0);
    overlay(canvas, WindowMask(orange, false, 0.10, 8.0,
                               windowSize, windowPosLeft,
                               shiftALeft));
    overlay(canvas, WindowMask(white, false, 0.03, 16.0,
                               windowSize, windowPosLeft,
                               shiftALeft));
    overlay(canvas, WindowMask(orange, true, 0.10, 8.0,
                               windowSize, windowPosRight,
                               shiftARight));
    overlay(canvas, WindowMask(white, true, 0.03, 16.0,
                               windowSize, windowPosRight,
                               shiftARight));
    vec4 backdrop  = getPixel(monika_bg, UV);
    vec4 highlight = getPixel(monika_bg_highlight, UV);
    draw(canvas, blend(backdrop, highlight, monika_alpha()));
}
