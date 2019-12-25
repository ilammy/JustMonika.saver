// SPDX-License-Identifier: Apache-2.0
// JustMonikaGL
// Copyright (c) 2019 ilammy's tearoom

#version 330 core

in vec2 UV;
out vec4 canvas;
uniform sampler2DRect mask;
uniform sampler2DRect maskb;
uniform sampler2DRect mask_2;
uniform sampler2DRect mask_3;
uniform sampler2DRect monika_bg;
uniform sampler2DRect monika_bg_highlight;
uniform float time;

const vec2 imageSize = vec2(1280.0, 720.0);

vec4 getPixel(in sampler2DRect sampler, in vec2 uv)
{
    // Rectangular textures don't do wrapping on their own
    return texture(sampler, mod(uv, textureSize(sampler)));
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
