#version 330 core

in vec2 UV;
out vec4 color;
uniform mat4 vertexUV_transform;
uniform sampler2D monika_bg;
uniform float timer;

vec4 getPixel(in sampler2D sampler, in vec2 uv)
{
    return texture(sampler, vec2(vertexUV_transform * vec4(uv, 0.0, 1.0)));
}

void main()
{
    color = getPixel(monika_bg, UV);
    color.a *= (cos(timer) + 1.0) / 2.0;
}
