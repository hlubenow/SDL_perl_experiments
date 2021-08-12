#### racing.pl

A translation of [the racing game example by FamTrinli](https://www.youtube.com/watch?v=N60lBZDEwJ8) from his C++/SFML version to Perl/SDLx.

Available keys are:

- Strafe left:  a, LEFT,
- Strafe right: d, RIGHT,
- Forward:      UP,
- Backwards:    DOWN,
- Fly up:       w,
- Fly down:     d,
- Turbo Boost:  TAB,
- Quit:         q, ESCAPE

This Perl version doesn't have the sprites, shown later in the video though. SDL_perl could display them, but unfortunately it can't scale them fast enough, so that the program wouldn't run fluently. The reason is, I believe, SDL_perl/SDLx uses version 1.2 of the SDL library, that doesn't support hardware acceleration. There is also [SDL_perl for SDL2](https://github.com/PerlGameDev/SDL2/), but it seems, it isn't complete yet.

However, I also once wrote this translation to Python/SFML, and it was definitely fast enough including the sprites. It ran just like the C++ version.

A version in Python/Pygame again didn't though. Pygame uses SDL 1.2 too. SFML and its Python bindings on the other hand aren't so easy to install. So not so many people could enjoy a SFML version. While SDL_perl is available on many systems. Nevertheless, I also wrote [a page](https://hlubenow.lima-city.de/pysfml.html) about writing in Python/SFML. It is a nice library, and it sure is useful to provide hardware acceleration for games.

The racing game code works by setting up 1600 "Line" objects, that have different properties. Then, the main loop runs through 300 of these Line objects each frame, and draws the scenery according to their properties (using a lot of math).

License of my Perl translation: GNU GPL, version 3 (or above)
