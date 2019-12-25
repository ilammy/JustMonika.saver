JustMonikaGL
============

OpenGL implementation of Monika’s space room.

## Usage

`#include`[`<JustMonikaGL/JustMonikaGL.h>`](include/JustMonikaGL/JustMonikaGL.h)

then do something like this:

```c
// allocate
struct just_monika *monika = just_monika_make();

// initialize
just_monika_init(monika);

// adjust your... whatever device you're viewing this on
just_monika_set_viewport(monika, 640, 480);

// fire the animation timer
just_monika_start_animation(monika);

// draw a single frame into the current OpenGL context
just_monika_draw(monika);

// do this later at your own risk
just_monika_free(monika);
```

## Dependencies

**libpng** for decoding PNG resources.

## OpenGL compatibility

Currently tested with the following OpenGL flavors:

- OpenGL 3.2

## Porting

This code is intended to be easily portable to UNIX-like systems with a C99 compiler available.

Resource loading is platform-specific.
Bundle files from [`res`](res) directory, implement loading interface from [`resource.h`](src/resource.h).

## License

The library is distributed under the terms of [**Apache Software License**](LICENSE) version 2.0.

Resources in [`res/Monika`](res/Monika) directory are original DDLC assets.
Please follow [Team Salvato IP Guidelines](http://teamsalvato.com/ip-guidelines/) when distibuting them.
