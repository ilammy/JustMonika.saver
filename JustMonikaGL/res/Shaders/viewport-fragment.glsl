#version 330 core

in  vec2 UV;
out vec4 color;

uniform sampler2DRect sampler;

void main()
{
    // Nothing fancy here, just pass through sampled color
    color = texture(sampler, UV);
}
