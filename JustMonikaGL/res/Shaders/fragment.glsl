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

uniform float offsetX;
uniform float offsetY;

// Compute four samples of a cubic B-spline
//
// Cubic B-spline has symmetric bell-shaped figure with maximum value at x = 0
// and tapering to zero for x outside (-2, 2).
//
//        1
// B(x) = - [(x + 2)^3 - 4(x + 1)^3 + 6(x)^3 - 4(x - 1)^3 + (x - 2)^3]
//        6
//
// It is effectively composed of four cubic splines, each covering its own
// region: (-2, -1), (-1, 0), (0, 1), (1, 2).
//
// This function returns the following four intermediate values:
//
// c.x = - 1/6 (v - 1)^3
// c.y =   2/3 (v - 1)^3 - 1/6 (v - 2)^3
// c.z = -     (v - 1)^3 + 2/3 (v - 2)^3 - 1/6 (v - 3)^3
// c.w =   1/2 (v - 1)^3 - 1/2 (v - 2)^3 + 1/6 (v - 3)^3 + 1
vec4 cubic(float v)
{
    vec4 n = vec4(1.0, 2.0, 3.0, 4.0) - v;
    vec4 s = n * n * n;
    float x = s.x;
    float y = s.y - 4.0 * s.x;
    float z = s.z - 4.0 * s.y + 6.0 * s.x;
    float w = 6.0 - x - y - z;
    return vec4(x, y, z, w) * (1.0 / 6.0);
}

vec4 textureBicubic(sampler2D sampler, vec2 texCoords)
{
    // This will be useful for normalizing coordinates
    vec2 invTextureSize = 1.0 / textureSize(sampler, 0);

    // Extract fractional part of the texture coordinates
    // relative to the center of the texel:
    //
    // +-----------+
    // |           |
    // |       f.x |
    // |     X--   |
    // |  f.y| o   |
    // |           |
    // +-----------+
    //
    // Also shifts "texCoords" into the lower left corner of the texel,
    // this will be used later for neighbors computation.
    texCoords = texCoords - 0.5;
    vec2 fxy = fract(texCoords);
    texCoords -= fxy;

    // Compute intermediate cubic values for f.x and f.y
    vec4 xcubic = cubic(fxy.x);
    vec4 ycubic = cubic(fxy.y);

    // Compute coordinates of neighboring 4 texels:
    //
    // +---+   +---+
    // | 3 |c.w| 4 |
    // +---+   +---+
    //  c.x  o  c.y
    // +---+   +---+
    // | 1 |c.z| 2 |
    // +---+   +---+
    //
    // Note that these are *diagonally* located around the central texel
    // and each component of "c" contains only one coordinate. They can
    // be extracted like "c.xz" to get coordinates of texel 1's center.
    vec4 c = texCoords.xxyy + vec2(-0.5, +1.5).xyxy;

    // More intermediate cubic values
    //
    // s.x =  1/2 (f.x - 1)^3 - 1/6 (f.x - 2)^3
    // s.y = -1/2 (f.x - 1)^3 + 1/6 (f.x - 2)^3 + 1
    // s.z =  1/2 (f.y - 1)^3 - 1/6 (f.y - 2)^3
    // s.w = -1/2 (f.y - 1)^3 + 1/6 (f.y - 2)^3 + 1
    vec4 s = vec4(xcubic.xz + xcubic.yw, ycubic.xz + ycubic.yw);

    //                  (2 - f.x)^3 - 4(1 - f.x)^3
    // offset.x = c.x + --------------------------
    //                  (2 - f.x)^3 - 3(1 - f.x)^3
    //
    //                  6 - (3 - f.x)^3 + 3(2 - f.x)^3 - 3(1 - f.x)^3
    // offset.y = c.y + ---------------------------------------------
    //                  6               -  (2 - f.x)^3 + 3(1 - f.x)^3
    //
    //                  (2 - f.y)^3 - 4(1 - f.y)^3
    // offset.z = c.z + --------------------------
    //                  (2 - f.y)^3 - 3(1 - f.y)^3
    //
    //                  6 - (3 - f.y)^3 + 3(2 - f.y)^3 - 3(1 - f.y)^3
    // offset.w = c.w + ---------------------------------------------
    //                  6               -  (2 - f.y)^3 + 3(1 - f.y)^3
    vec4 offset = c + vec4 (xcubic.yw, ycubic.yw) / s;

    // Normalize sampling offsets to (0.0, 1.0) range expected by OpenGL
    offset *= invTextureSize.xxyy;

    // Sample texture colors
    vec4 sample1 = texture(sampler, offset.xz);
    vec4 sample2 = texture(sampler, offset.yz);
    vec4 sample3 = texture(sampler, offset.xw);
    vec4 sample4 = texture(sampler, offset.yw);

    // s.x / (s.x + s.y)

    float sx = s.x / (s.x + s.y);
    float sy = s.z / (s.z + s.w);

    return mix(mix(sample4, sample3, sx),
               mix(sample2, sample1, sx),
               sy);
}

// All our textures have 2048 x 2048 size in memory and have 1280 x 720
// starting at origin filled with actually userful data. UV coordinates
// are expressed in source image coordinates.
const vec2 imageSize = vec2(1280.0, 720.0);

vec4 getPixel(in sampler2D sampler, in vec2 uv)
{
    return textureBicubic(sampler, mod(uv, imageSize));
}

void draw(inout vec4 canvas, in vec4 color)
{
    canvas = mix(canvas, color, color.a);
}

void overlay(inout vec4 canvas, in vec4 color)
{
    canvas = clamp(canvas + color, 0.0, 1.0);
}

float amplify(float a, float offset, float scale)
{
    float shift = (0.5 - offset) * (1.0 + 1.0 / scale);
    return clamp(scale * ((a - shift) - 0.5) + 0.5, 0.0, 1.0);
}

const vec2 windowSize     = vec2(320.0, 180.0);
const vec2 windowPosLeft  = vec2( 30.0, 340.0);
const vec2 windowPosRight = vec2(935.0, 340.0);
const vec2 shiftALeft     = vec2(-100.0, 600.0);
const vec2 shiftARight    = vec2(560.0, 200.0);

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
    float d = flip ? size.x : 0;
    posA.x += mod(16.0 * time + d, size.x * 1.5 + 160.0) + size.x * 2;
    vec4 pixelA = getPixel(mask, posA);

    const mat4 maskbTransform = mat4(
        0.6 * imageSize.x / windowSize.x, 0.0, 0.0, 0.0,
        0.0, 1.0 * imageSize.y / windowSize.y, 0.0, 0.0,
        0.0,                              0.0, 1.0, 0.0,
        2.5 * windowSize.x,               0.0, 0.0, 1.0
    );
    vec2 posB = vec2(maskbTransform * vec4(UV - pos, 0.0, 1.0));
    vec4 pixelB = getPixel(maskb, posB);

    vec4 light = vec4(0.0, 0.0, 0.0, 0.0);
    draw(light, pixelA);
    draw(light, pixelB);
    // TODO: compute without calling draw?
    float alpha = light.a;

    float offset = bias + pow(sin(time / 8.0), 64.0) * 0.5;

    return tint * amplify(alpha, offset, scale);
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

uniform float biasA;
uniform float biasB;
uniform float scaleA;
uniform float scaleB;

void main()
{
    canvas = vec4(0.0, 0.0, 0.0, 0.0);
    draw(canvas, getPixel(mask_2, mask_2_transform(UV)));
    draw(canvas, getPixel(mask_3, mask_3_transform(UV)));
    const vec4 orange = vec4(1.0, 0.375, 0.0, 1.0);
    const vec4 white  = vec4(1.0, 1.0,   1.0, 1.0);
    overlay(canvas, WindowMask(orange, false, 0.35, 6.0,
                               windowSize, windowPosLeft,
                               shiftALeft));
    overlay(canvas, WindowMask(white, false, 0.29, 16.0,
                               windowSize, windowPosLeft,
                               shiftALeft));
    overlay(canvas, WindowMask(orange, true, 0.35, 6.0,
                               windowSize, windowPosRight,
                               shiftARight));
    overlay(canvas, WindowMask(white, true, 0.29, 16.0,
                               windowSize, windowPosRight,
                               shiftARight));
    vec4 backdrop  = getPixel(monika_bg, UV);
    vec4 highlight = getPixel(monika_bg_highlight, UV);
    draw(canvas, mix(backdrop, highlight, monika_alpha()));
}
