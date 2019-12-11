#version 330 core

in vec2 vertexXY_modelSpace;
out vec2 UV;
uniform mat4 vertexXY_transform;

void main() {
    gl_Position = vertexXY_transform * vec4(vertexXY_modelSpace, 0.0, 1.0);
    // For simplicity XY and UV coordinates are the same
    UV = vertexXY_modelSpace;
}
