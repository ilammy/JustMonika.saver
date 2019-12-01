#version 330 core

in vec2 vertexXY_modelSpace;
in vec2 vertexUV_modelSpace;
out vec2 UV;
uniform mat4 vertexXY_transform;

void main() {
    gl_Position = vertexXY_transform * vec4(vertexXY_modelSpace, 0.0, 1.0);
    UV = vertexUV_modelSpace;
}
