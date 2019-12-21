#version 330 core

in vec2 UV;

out vec4 color;

uniform sampler2D screen;

void main()
{
    color = texture(screen, UV / textureSize(screen, 0));
}
