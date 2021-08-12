#!/usr/bin/perl

use warnings;
use strict;

=begin comment

    racing.pl 1.0 - A Translation of the great Racing Game Example
                    by FamTrinli from C++/SFML to Perl/SDLx.

    Original C++/SFML-version by user "FamTrinli":
    https://www.youtube.com/watch?v=N60lBZDEwJ8

    Perl translation Copyright (C) 2021 hlubenow

    Available keys are:

    - Strafe left:  a, LEFT,
    - Strafe right: d, RIGHT,
    - Forward:      UP,
    - Backwards:    DOWN,
    - Fly up:       w,
    - Fly down:     d,
    - Turbo Boost:  TAB,
    - Quit:         q, ESCAPE

    This program is free software: you can redistribute it and/or modify
     it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.

=end comment

=cut

use SDLx::App;
use SDLx::Surface;
use SDLx::Rect;
use SDLx::FPS;
use SDL::Event;

my $APPSPEED = 50;

my $WIDTH = 800;
my $HEIGHT = 600;
my $ROADW = 2000;
my $SEGL  = 200;
my $CAMD = 0.84;

SDL::putenv("SDL_VIDEO_WINDOW_POS=100,50");

my $LIGHT_BLUE = [85, 135, 200, 255];

package Main {

    use SDL::Event;

    sub new {
        my $classname = shift;
        my $self = {};
        return bless($self, $classname);
    }

    sub start {
        my $self = shift;
        $self->{app} = SDLx::App->new(w     => $WIDTH,
                                      h     => $HEIGHT,
                                      title => "Racing",
                                      exit_on_quit => 1);

        $self->{screen}  = SDLx::Surface::display();
        $self->{fps}     = SDLx::FPS->new(fps => $APPSPEED);
        $self->{event}   = SDL::Event->new();
        $self->{lines}   = [];
        $self->{keystates} = ();
        $self->{keystatekeys} = [ SDLK_LEFT, SDLK_RIGHT, SDLK_UP, SDLK_DOWN, SDLK_a, SDLK_d, SDLK_w, SDLK_s, SDLK_q, SDLK_TAB, SDLK_ESCAPE ];
        my $i;
        for $i (@{$self->{keystatekeys}}) {
            $self->{keystates}->{$i} = 0;
        }

        $self->buildLines();

        $self->{nroflines} = $#{$self->{lines}} + 1;
        $self->{playerX}   = 0;
        $self->{pos}       = 0;
        $self->{flying}    = 1500;
        $self->{running}   = 1;

        my ($l, $p);

        while ($self->{running}) {
            $self->{fps}->delay();
            $self->{speed} = 0;
            $self->processEvents();
            $self->{pos} += $self->{speed}; 

            while ($self->{pos} >= $self->{nroflines} * $SEGL) {
                $self->{pos} -= $self->{nroflines} * $SEGL;
            }
            while ($self->{pos} < 0) {
                $self->{pos} += $self->{nroflines} * $SEGL;
            }
            $self->{startPos} = $self->{pos} / $SEGL;
            if ($self->{flying} < 400) {
                $self->{flying} = 400;
            }
            # Don't fly too high, my little friend:
            if ($self->{flying} > 20000) {
                $self->{flying} = 20000;
            }
            $self->{camH} = $self->{lines}->[$self->{startPos}]->{y} + $self->{flying};

            $self->{maxy} = $HEIGHT;
            $self->{x}    = 0;
            $self->{dx}   = 0;

            # Fill background:
            $self->{screen}->draw_rect( [ 0, 0, $self->{screen}->w, $self->{screen}->h ], $LIGHT_BLUE);

            # Draw road
            for $i ($self->{startPos} .. $self->{startPos} + 299) {
                $l = $self->{lines}->[$i % $self->{nroflines}];
                if ($i >= $self->{nroflines}) {
                    $l->project($self->{playerX} * $ROADW - $self->{x}, $self->{camH}, ($self->{startPos} - $self->{nroflines}) * $SEGL);
                } else {
                    $l->project($self->{playerX} * $ROADW - $self->{x}, $self->{camH}, $self->{startPos} * $SEGL);
                }
                $self->{x} += $self->{dx};
                $self->{dx} += $l->{curve};
                $l->{clip} = $self->{maxy};
                if ($l->{Y} >= $self->{maxy}) {
                    next;
                }

                $self->{maxy} = $l->{Y};

                if (($i / 3) % 2 == 1) {
                    $self->{grass}  = [16, 200, 16, 255];
                    $self->{rumble} = [255, 255, 255, 255];
                    $self->{road}   = [107, 107, 107, 255];
                } else {
                    $self->{grass}  = [0, 154, 0, 255];
                    $self->{rumble} = [0, 0, 0, 255];
                    $self->{road}   = [105, 105, 105, 255];
                }
                
                $p = $self->{lines}->[($i - 1) % $self->{nroflines}]; # previous line
                $self->drawQuad($self->{screen},
                                $self->{grass},
                                0,
                                $p->{Y},
                                $WIDTH,
                                0,
                                $l->{Y},
                                $WIDTH);

                $self->drawQuad($self->{screen},
                                $self->{rumble},
                                $p->{X},
                                $p->{Y},
                                $p->{W} * 1.2,
                                $l->{X},
                                $l->{Y},
                                $l->{W} * 1.2);

                $self->drawQuad($self->{screen},
                                $self->{road},
                                $p->{X},
                                $p->{Y},
                                $p->{W},
                                $l->{X},
                                $l->{Y},
                                $l->{W});
            }

            $self->{screen}->flip();
        }
    }

    sub drawQuad {
        my ($self, $window, $color, $x1, $y1, $w1, $x2, $y2, $w2) = @_;
        $window->draw_polygon_filled([[$x1 - $w1, $y1],
                                      [$x2 - $w2, $y2],
                                      [$x2 + $w2, $y2],
                                      [$x1 + $w1, $y1]], $color);
    }

    sub buildLines {
        my $self = shift;
        my $i;
        my $line;
        for $i (0 .. 1599) {
            $line = Line->new();
            $line->setZ($i * $SEGL);
            if ($i > 300 && $i < 700) {
                $line->setCurve(0.5);
            }
            if ($i > 1100) {
                $line->setCurve(-0.7);
            }
            if ($i > 750) {
                $line->{y} = sin($i / 30) * 1500;
            }
            push($self->{lines}, $line);
        }
    }

    sub processEvents {
        my $self = shift;
        my ($i, $num, $num2);
        SDL::Events::pump_events();
        if (SDL::Events::poll_event($self->{event})) {
            if ($self->{event}->type == SDL_KEYDOWN ) {
                for $i (@{$self->{keystatekeys}}) {
                    if ($self->{event}->key_sym == $i) {
                        $self->{keystates}->{$i} = 1;
                    }
                }
            }
            if ($self->{event}->type == SDL_KEYUP ) {
                for $i (@{$self->{keystatekeys}}) {
                    if ($self->{event}->key_sym == $i) {
                        $self->{keystates}->{$i} = 0;
                    }
                }
            }
        }
        for $i (@{$self->{keystatekeys}}) {
            $num  = SDLK_LEFT;
            $num2 = SDLK_a;
            if ($self->{keystates}->{$num} || $self->{keystates}->{$num2}) {
                $self->{playerX} -= 0.1;
            }
            $num  = SDLK_RIGHT;
            $num2 = SDLK_d;
            if ($self->{keystates}->{$num} || $self->{keystates}->{$num2}) {
                $self->{playerX} += 0.1;
            }
            $num = SDLK_UP;
            if ($self->{keystates}->{$num}) {
                $self->{speed} = 200; # Not +=, but =.
            }
            $num = SDLK_DOWN;
            if ($self->{keystates}->{$num}) {
                $self->{speed} -= 200; # Not +=, but =.
            }
            $num = SDLK_TAB;
            if ($self->{keystates}->{$num}) {
                $self->{speed} *= 3;
            }
            $num = SDLK_w;
            if ($self->{keystates}->{$num}) {
                $self->{flying} += 100;
            }
            $num = SDLK_s;
            if ($self->{keystates}->{$num}) {
                $self->{flying} -= 100;
            }
            $num  = SDLK_q;
            $num2 = SDLK_ESCAPE;
            if ($self->{keystates}->{$num} || $self->{keystates}->{$num2}) {
                $self->{running} = 0;
                last;
            }
        }
    }
}


package Line {

    sub new {
        my $classname = shift;
        my $self = {x => 0,
                    y => 0,
                    z => 0,
                    X => 0,
                    Y => 0,
                    W => 0,
                    scale => 0,
                    curve => 0,
                    spriteX => 0,
                    clip => 0};
        return bless($self, $classname);
    }

    sub setZ {
        my $self = shift;
        $self->{z} = shift;
    }

    sub setCurve {
        my $self = shift;
        $self->{curve} = shift;
    }

    # from world to screen coordinates;
    sub project {
        my ($self, $camX, $camY, $camZ) = @_;
        if ($self->{z} == $camZ) {
            $self->{scale} = 1;
        } else {
            $self->{scale} = $CAMD / ($self->{z} - $camZ);
        }
        $self->{X} = (1 + $self->{scale} * ($self->{x} - $camX)) * $WIDTH / 2;
        $self->{Y} = (1 - $self->{scale} * ($self->{y} - $camY)) * $HEIGHT / 2;
        $self->{W} = $self->{scale} * $ROADW * $WIDTH / 2.;
    }
}


my $app = Main->new();
$app->start();
