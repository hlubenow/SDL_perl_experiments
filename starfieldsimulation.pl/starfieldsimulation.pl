#!/usr/bin/perl

use warnings;
use strict;

=begin comment

    starfieldsimulation.pl 1.1

    A translation of the example of a starfield simulation in
    Python/Tkinter by davidejones
    ( https://github.com/davidejones/starfield )
    to SDL_perl/SDLx.

    Keys:

    - "Up" to go faster,
    - "Down" to slow down.
    - "q" to quit.

    Perl-Code Copyright (C) 2021 hlubenow

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

my $WIDTH   = 1024;
my $HEIGHT  = 576;

# Original value was 1.7:
my $STARSIZEFACTOR = 3;

# 1: circles, 2: rectangles:
my $STARSHAPE = 2;

my $SPEEDSETTING  = 60;
my $INITIALSPEED = $SPEEDSETTING / 2;
my $STOPDELAYTIME = 220;
my $ACCELERATOR   = 0.1;

my $COLOR_BLACK = [0, 0, 0, 255];

package Star {

    sub new {
        my $classname = shift;
        my $self = {x => shift,
                    y => shift,
                    z => shift,
                    radius => 0,
                    color  => []};
        return bless($self, $classname);
    }

    sub setGreyValue {
        my ($self, $greyvalue) = @_;
        $self->{color} = [$greyvalue, $greyvalue, $greyvalue, 255];
    }
}

package StarField {

    sub new {
        my $classname = shift;
        my $self = {width     => shift,
                    height    => shift,
                    timer     => shift,
                    delaytime => shift,
                    pi        => 3.14159265359,
                    max_depth => 32,
                    num_stars => 350,
                    view_distance => 0};
        return bless($self, $classname);
    }

    sub initStars {
        my $self = shift;
        $self->{stars} = [];
        my ($i, $s);
        for $i (0 .. $self->{num_stars}) {
            $s = Star->new($self->getRandRange($self->{width}),
                           $self->getRandRange($self->{height}),
                           int(rand($self->{max_depth} - 1)) + 1);
            push($self->{stars}, $s);
        }
    }

    sub getRandRange {
        my ($self, $num) = @_;
        return int(rand(2 * $num)) - $num;
    }

    sub moveStars {
        my ($self, $currenttime) = @_;
        if ($self->{delaytime} >= $STOPDELAYTIME) {
            $self->{timer} = $currenttime;
            return;
        }
        if ($currenttime - $self->{timer} <= $self->{delaytime}) {
            return;
        }
        my $star;
        for $star (@{$self->{stars}}) {
            # move depth;
            $star->{z}        -= 0.19;
            $star->{radius}   = (1 - $star->{z} / $self->{max_depth}) * $STARSIZEFACTOR;
            $star->{radius}   = int($star->{radius});
            $star->setGreyValue(int((1 - $star->{z} / $self->{max_depth}) * 255));
            # reset depth;
            if ($star->{z} <= 0) {
                $star->{x} = $self->getRandRange($self->{width});
                $star->{y} = $self->getRandRange($self->{height});
                $star->{z} = $self->{max_depth};
                $star->{radius} = 0;
                $star->setGreyValue(0);
            }
        }
        $self->{timer} = $currenttime;
    }

    sub draw {
        my ($self, $screen) = @_;
        # print $self->{delaytime} . "\n";
        for my $star (@{$self->{stars}}) {
            # Transforms this 3D point to 2D using a perspective projection.;
            my $factor = $self->{pi} / ($self->{view_distance} + $star->{z});
            my $x  = $star->{x} * $factor + $self->{width}  / 2;
            my $y = -$star->{y} * $factor + $self->{height} / 2;
            if ($star->{radius} == 0) {
                next;
            }
            if ($STARSHAPE == 1) {
                $screen->draw_circle_filled([int($x), int($y)], $star->{radius}, $star->{color});
            } else {
                $screen->draw_rect( [ int($x) - $star->{radius},
                                      int($y) - $star->{radius},
                                      2 * $star->{radius},
                                      2 * $star->{radius} ], $star->{color} );
            }
        }
    }

    sub goFaster {
        my $self = shift;
        $self->{delaytime} -=  $ACCELERATOR;
        if ($self->{delaytime} < 0) {
            $self->{delaytime} = 0;
        }
    }

    sub slowDown {
        my $self = shift;
        $self->{delaytime} += $ACCELERATOR;
        if ($self->{delaytime} > $STOPDELAYTIME) {
            $self->{delaytime} = $STOPDELAYTIME;
        }
    }
}


package Main {

    use SDL::Event;

    sub new {
        my $classname = shift;
        my $self = {};
        return bless($self, $classname);
    }    

    sub start {
        my $self = shift;
        SDL::putenv("SDL_VIDEO_WINDOW_POS=75,37");
        $self->{app} = SDLx::App->new(w            => $WIDTH,
                                      h            => $HEIGHT,
                                      title        => 'Starfield Simulation',
                                      exit_on_quit => 1);
        $self->{screen} = SDLx::Surface::display();
        $self->{event}  = SDL::Event->new();
        $self->{keystates}    = ();
        $self->{keystatekeys} = [SDLK_UP, SDLK_DOWN, SDLK_q];
        for my $i (@{ $self->{keystatekeys} }) {
            $self->{keystates}{$i} = 0;
        }

        $self->{starfield} = StarField->new($WIDTH, $HEIGHT, $self->{app}->ticks(), $INITIALSPEED);
        $self->{starfield}->initStars();

        $self->{running} = 1;

        # Main Loop:
        while ($self->{running}) {
            $self->{timer} = $self->{app}->ticks();
            if ($self->processEvents() eq "quit") {
                $self->{running} = 0;
            }
            $self->fill($self->{screen}, $COLOR_BLACK);
            $self->{starfield}->moveStars($self->{timer});
            $self->{starfield}->draw($self->{screen});
            $self->{screen}->flip(); # or "update()"
        }
    }

    sub fill {
        my ($self, $surface, $colorref) = @_;
        $surface->draw_rect( [ 0, 0, $surface->w, $surface->h ], $colorref);
    }

    sub processEvents {
        my $self = shift;
        my ($i, $num);
        SDL::Events::pump_events();
        if (SDL::Events::poll_event($self->{event})) {
            if ($self->{event}->type == SDL_KEYDOWN ) {
                for $i (@{ $self->{keystatekeys} }) {
                    if ($self->{event}->key_sym == $i) {
                        $self->{keystates}{$i} = 1;
                    }
                }
            }
            if ($self->{event}->type == SDL_KEYUP ) {
                for $i (@{ $self->{keystatekeys} }) {
                    if ($self->{event}->key_sym == $i) {
                        $self->{keystates}{$i} = 0;
                    }
                }
            }
        }
        for $i (@{ $self->{keystatekeys} }) {
            $num = SDLK_UP;
            if ($self->{keystates}{$num}) {
                $self->{starfield}->goFaster(); 
            }
            $num = SDLK_DOWN;
            if ($self->{keystates}{$num}) {
                $self->{starfield}->slowDown(); 
            }
            $num = SDLK_q;
            if ($self->{keystates}{$num}) {
                # 'q' pressed.
                return "quit";
            }
        }
        return 0;
    }
}

my $app = Main->new();
$app->start();
