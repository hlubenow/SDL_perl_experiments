#!/usr/bin/perl

use warnings;
use strict;

# SDL_perl example 1

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
        $self->{fps}    = SDLx::FPS->new(fps => 50);
        $self->{event}  = SDL::Event->new();

        $self->{red_circle} = RedCircle->new($self->{addon});
        $self->{red_circle}->createSurface();

        $self->{running} = 1;

        # Main Loop:
        while ($self->{running}) {
            $self->{fps}->delay();
            if ($self->handleEvents() eq "quit") {
                $self->{running} = 0;
            }
            $self->{red_circle}->moveRight();

            $self->{addon}->fill($self->{screen}, $BLUE);
            $self->{red_circle}->draw($self->{screen});
            $self->{screen}->flip(); # or "update()"
        }
    }

    sub handleEvents {
        my $self = shift;
        SDL::Events::pump_events();
        if (SDL::Events::poll_event($self->{event})) {
            if ($self->{event}->type == SDL_KEYDOWN ) {
                if ($self->{event}->key_sym == SDLK_SPACE) {
                    $self->{red_circle}->startStopMoving();
                }
                if ($self->{event}->key_sym == SDLK_q) {
                    return "quit";
                }
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
        $self->{addon}->fill($self->{surface}, $BLACK);
        $self->{surface}->draw_circle_filled( [$SIZE / 2, $SIZE / 2], ($SIZE - 10) / 2, $RED);
        $self->{rect} = $self->{addon}->get_rect($self->{surface});
        # Set start-position. Values for "->topleft()" are in the order of y, x:
        $self->{rect}->topleft(300 - $SIZE, 0);
    }

    sub startStopMoving {
        my $self = shift;
        $self->{moving} = 1 - $self->{moving};
    }

    sub moveRight {
        my $self = shift;
        if ($self->{moving} == 0) {
            return;
        }
        $self->{rect}->x($self->{rect}->x + $STEP);
        if ($self->{rect}->right > 800) {
            $self->{rect}->x(0);
        }
    }

    sub draw {
        my ($self, $screen) = @_;
        $screen->blit_by($self->{surface}, undef, $self->{rect});
    }
}

my $app = GameWindow->new();
$app->start();
