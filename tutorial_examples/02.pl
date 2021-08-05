#!/usr/bin/perl

use warnings;
use strict;

# SDL_perl Example 2

# Copyright (C) 2021 hlubenow
# License: GNU GPL 3.

use SDLx::App;
use SDLx::Surface;
use SDLx::Rect;
use SDLx::FPS;

my $RESX  = 800;
my $RESY  = 600;
my $BLACK = [0, 0, 0, 255];
my $BLUE  = [0, 0, 189, 255];
my $RED   = [220, 0, 0, 255];
my $SIZE  = 50;
my $STEP  = 5;
my $FPS   = 50;

package GameWindow {

    use SDL::Event;

    sub new {
        my $classname = shift;
        my $self = {};
        $self->{addon} = AddOn->new();
        return bless($self, $classname);
    }    

    sub start {
        my $self = shift;
        SDL::putenv("SDL_VIDEO_WINDOW_POS=130,18");
        $self->{app} = SDLx::App->new(w            => $RESX,
                                      h            => $RESY,
                                      title        => 'Moving Circle',
                                      exit_on_quit => 1);

        $self->{screen} = SDLx::Surface::display();
        $self->{fps}    = SDLx::FPS->new(fps => $FPS);
        $self->{event}  = SDL::Event->new();
        $self->{keystates} = ();
        $self->{keystatekeys} = [SDLK_LEFT, SDLK_RIGHT, SDLK_UP, SDLK_DOWN, SDLK_q];
        my $i;
        for $i (@{ $self->{keystatekeys} }) {
            $self->{keystates}{$i} = 0;
        }
        $self->{red_circle} = RedCircle->new($self->{addon});
        $self->{red_circle}->createSurface();

        $self->{running} = 1;

        # Main Loop:
        while ($self->{running}) {
            $self->{fps}->delay();
            if ($self->processEvents() eq "quit") {
                $self->{running} = 0;
            }
            $self->{addon}->fill($self->{screen}, $BLUE);
            $self->{red_circle}->draw($self->{screen});
            $self->{screen}->flip(); # or "update()"
        }
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
                if ($self->{event}->key_sym == SDLK_q) {
                    return "quit";
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

            $num = SDLK_LEFT;
            if ($self->{keystates}{$num}) {
                $self->{red_circle}->moveLeft();
            }
            $num = SDLK_RIGHT;
            if ($self->{keystates}{$num}) {
                $self->{red_circle}->moveRight();
            }
            $num = SDLK_UP;
            if ($self->{keystates}{$num}) {
                $self->{red_circle}->moveUp();
            }
            $num = SDLK_DOWN;
            if ($self->{keystates}{$num}) {
                $self->{red_circle}->moveDown();
            }
        }
        return 0;
    }
}

package AddOn {

    # My own additions to SDLx.

    sub new {
        my $classname = shift;
        my $self = {};
        return bless($self, $classname);
    }    

    sub get_rect {
        my ($self, $surface) = @_;
        return SDLx::Rect->new(0, 0, $surface->w, $surface->h);
    }

    sub fill {
        my ($self, $surface, $colorref) = @_;
        $surface->draw_rect( [ 0, 0, $surface->w, $surface->h ], $colorref);
    }
}


package RedCircle {

    sub new {
        my $classname = shift;
        my $self = {moving => 1}; 
        $self->{addon} = shift;
        return bless($self, $classname);
    }    

    sub createSurface {
        my $self = shift;
        $self->{surface} = SDLx::Surface->new(w => $SIZE, h => $SIZE);
        $self->{surface}->draw_circle_filled( [$SIZE / 2, $SIZE / 2], ($SIZE - 10) / 2, $RED);
        $self->{rect} = $self->{addon}->get_rect($self->{surface});
        $self->{rect}->center($RESX / 2, $RESY / 2);
    }

    sub moveLeft {
        my $self = shift;
        $self->{rect}->x($self->{rect}->x - $STEP);
        if ($self->{rect}->right < 0) {
            $self->{rect}->right($RESX);
        }
    }

    sub moveRight {
        my $self = shift;
        $self->{rect}->x($self->{rect}->x + $STEP);
        if ($self->{rect}->left > $RESX) {
            $self->{rect}->left(0);
        }
    }

    sub moveUp {
        my $self = shift;
        $self->{rect}->y($self->{rect}->y - $STEP);
        if ($self->{rect}->bottom < 0) {
            $self->{rect}->bottom($RESY);
        }
    }

    sub moveDown {
        my $self = shift;
        $self->{rect}->y($self->{rect}->y + $STEP);
        if ($self->{rect}->top > $RESY) {
            $self->{rect}->top(0);
        }
    }

    sub draw {
        my ($self, $screen) = @_;
        $screen->blit_by($self->{surface}, undef, $self->{rect});
    }
}

my $app = GameWindow->new();
$app->start();
