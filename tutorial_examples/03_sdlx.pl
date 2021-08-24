#!/usr/bin/perl

use warnings;
use strict;

# SDL_perl Example 3

# Moving to SDLx-style application speed control.

# Copyright (C) 2021 hlubenow
# License: GNU GPL 3.

use SDLx::App;
use SDLx::Rect;

my $RESX  = 800;
my $RESY  = 600;
my $BLUE  = [0, 0, 189, 255];
my $RED   = [220, 0, 0, 255];
my $SIZE  = 50;

package GameWindow {

    use SDL::Event;

    sub new {
        my $classname = shift;
        my $self = {};
        return bless($self, $classname);
    }    

    sub start {
        my $self = shift;
        SDL::putenv("SDL_VIDEO_WINDOW_POS=130,18");
        $self->{app} = SDLx::App->new(w            => $RESX,
                                      h            => $RESY,
                                      title        => 'Moving Circle, SDLx-Style',
                                      dt           => 0.1,
                                      min_t        => 1/60,
                                      exit_on_quit => 1);

        $self->{screen} = SDLx::Surface::display();
        $self->{keystates}    = ();
        $self->{keystatekeys} = [SDLK_LEFT, SDLK_RIGHT, SDLK_UP, SDLK_DOWN, SDLK_q];
        my $i;
        for $i (@{ $self->{keystatekeys} }) {
            $self->{keystates}{$i} = 0;
        }
        $self->{pressed_x} = 0;
        $self->{pressed_y} = 0;
        $self->{red_circle} = RedCircle->new();
        $self->{red_circle}->createSurface();

        $self->{app}->add_event_handler(sub {
                                              my ( $event, $app ) = @_;
                                              $self->processEvents($event); });
        $self->{app}->add_move_handler( sub {
                                              my ( $step, $app ) = @_;
                                              $self->{red_circle}->move($step) } );

        $self->{app}->add_show_handler( sub { $self->showScreen(); });

        $self->{app}->run();
    }

    sub showScreen {
        my $self = shift;
        # Fill the screen blue:
        $self->{screen}->draw_rect( [ 0, 0, $RESX, $RESY ], $BLUE);
        $self->{red_circle}->draw($self->{screen});
        $self->{screen}->flip();
    }

    sub processEvents {
        my ($self, $event) = @_; 
        my ($i, $num);
        if ($event->type == SDL_KEYDOWN) {
            for $i (@{ $self->{keystatekeys} }) {
                if ($event->key_sym == $i) {
                    $self->{keystates}{$i} = 1;
                }
            }
        }
        if ($event->type == SDL_KEYUP ) {
            for $i (@{ $self->{keystatekeys} }) {
                if ($event->key_sym == $i) {
                    $self->{keystates}{$i} = 0;
                }
            }
        }
        $self->{pressed_x} = 0;
        $self->{pressed_y} = 0;
        $num = SDLK_LEFT;
        if ($self->{keystates}{$num}) {
            $self->{pressed_x} = 1;
            $self->{red_circle}->startMoving("left");
        }
        $num = SDLK_RIGHT;
        if ($self->{keystates}{$num}) {
            $self->{pressed_x} = 1;
            $self->{red_circle}->startMoving("right");
        }
        $num = SDLK_UP;
        if ($self->{keystates}{$num}) {
            $self->{pressed_y} = 1;
            $self->{red_circle}->startMoving("up");
        }
        $num = SDLK_DOWN;
        if ($self->{keystates}{$num}) {
            $self->{pressed_y} = 1;
            $self->{red_circle}->startMoving("down");
        }
        $num = SDLK_q;
        if ($self->{keystates}{$num}) {
            $self->{app}->stop();
        }
        if ($self->{pressed_x} == 0) {
            $self->{red_circle}->stopMoving("x");
        }
        if ($self->{pressed_y} == 0) {
            $self->{red_circle}->stopMoving("y");
        }
    }   
}

package RedCircle {

    sub new {
        my $classname = shift;
        # "Velocity" and "Speed" both mean "Geschwindigkeit" (in German):
        my $self = {speedx => 0,
                    speedy => 0};
        # "speed" is the value, "speedx" and "speedy" are set to, when the object is
        # supposed to move. That means, you can set the object's speed here:
        $self->{speed} = 50;
        return bless($self, $classname);
    }    

    sub createSurface {
        my $self = shift;
        $self->{surface} = SDLx::Surface->new(w => $SIZE, h => $SIZE);
        $self->{surface}->draw_circle_filled( [$SIZE / 2, $SIZE / 2], ($SIZE - 10) / 2, $RED);
        $self->{rect} = SDLx::Rect->new(0, 0, $self->{surface}->w, $self->{surface}->h);
        $self->{rect}->center($RESX / 2, $RESY / 2);
    }

    sub startMoving {
        my ($self, $direction) = @_;
        if ($direction eq "left") {
            $self->{speedx} = -$self->{speed};
        }
        if ($direction eq "right") {
            $self->{speedx} = $self->{speed};
        }
        if ($direction eq "up") {
            $self->{speedy} = -$self->{speed};
        }
        if ($direction eq "down") {
            $self->{speedy} = $self->{speed};
        }
    }

    sub stopMoving {
        my ($self, $axis) = @_;
        if ($axis eq "x") {
            $self->{speedx} = 0;
        } else {
            $self->{speedy} = 0;
        }
    }

    sub move {
        my ($self, $step) = @_;
        $self->{rect}->x(int($self->{rect}->x + $self->{speedx} * $step));
        $self->{rect}->y(int($self->{rect}->y + $self->{speedy} * $step));
        $self->checkScreenLimits();
    }

    sub checkScreenLimits {
        my $self = shift;
        if ($self->{rect}->right < 0) {
            $self->{rect}->right($RESX);
        }
        if ($self->{rect}->left > $RESX) {
            $self->{rect}->left(0);
        }
        if ($self->{rect}->bottom < 0) {
            $self->{rect}->bottom($RESY);
        }
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
