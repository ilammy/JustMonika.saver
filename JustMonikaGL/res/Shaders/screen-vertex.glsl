#version 330 core

in  vec2 XY;
out vec2 UV;

// Despite using frambuffers and stuff for textures, vertex coordinates
// are still expected to be normalized. Thankfully, screen size is fixed.
const mat4 screen_transform = mat4(
    2.0/1280.0,       0.0, 0.0, 0.0,
           0.0, 2.0/720.0, 0.0, 0.0,
           0.0,       0.0, 1.0, 0.0,
          -1.0,      -1.0, 0.0, 1.0
);

void main()
{
    gl_Position = screen_transform * vec4(XY, 0.0, 1.0);

    // Forward coordinates to fragment shader
    UV = XY;
}
