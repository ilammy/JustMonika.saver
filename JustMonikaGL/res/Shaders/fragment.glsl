#version 330 core

in vec2 UV;
out vec4 color;
uniform sampler2D sampler;
uniform float timer;

void main() {
    color = texture(sampler, UV);
    color.a *= (sin(timer) + 1.0) / 2.0;
}
