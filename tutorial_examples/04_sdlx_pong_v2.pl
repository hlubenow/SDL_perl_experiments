#!/usr/bin/perl

use warnings;
use strict;

# SDL_perl Example 4

# Rewritten version of the "SDLx Pong" example in "SDL_Manual.pdf".

# Copyright (C) 2021 hlubenow
# License: GNU GPL 3.

use SDLx::App;
use SDLx::Text;
use SDLx::Rect;

my $RESX  = 500;
my $RESY  = 500;

my $BALLSPEED    = 27;
my $PLAYER1SPEED = 30;
my $PLAYER2SPEED = 25;

my $GREY = [170, 170, 170, 255];
my $RED  = [255, 0, 0, 255];

my $SHOWSCORES = 1;
my $FONTFILE   = "arial.ttf";

package GameWindow {

    use SDL::Event;

    sub new {
        my $classname = shift;
        my $self = {};
        return bless($self, $classname);
    }    

    sub start {
        my $self = shift;
        SDL::putenv("SDL_VIDEO_WINDOW_POS=273,80");
        $self->{app} = SDLx::App->new(w            => $RESX,
                                      h            => $RESY,
                                      dt           => 0.1,
                                      min_t        => 1/60,
                                      title        => 'SDLx Pong, rewritten version',
                                      exit_on_quit => 1);

        $self->{screen} = SDLx::Surface::display();
        $self->{event}  = SDL::Event->new();

        $self->initObjects();

        $self->{app}->add_event_handler(sub {
                                              my ( $event, $app ) = @_;
                                              $self->processEvents($event); });
        $self->{app}->add_move_handler( sub {
                                              my ( $step, $app ) = @_;
                                              $self->moveBall($step) } );

        $self->{app}->add_move_handler( sub {
                                              my ( $step, $app ) = @_;
                                              $self->{player1}->move($step); });

        $self->{app}->add_move_handler( sub {
                                              my ( $step, $app ) = @_;
                                              $self->{player2}->move($step, $self->{ball}); });

        $self->{app}->add_show_handler( sub { $self->showScreen(); });

        $self->{app}->run();
    }

    sub initObjects {
        my $self = shift;
        $self->{ball}    = Ball->new();
        $self->{ball}->createSurface();
        $self->{player1} = Player1->new();
        $self->{player1}->createSurface();
        $self->{player2} = Player2->new();
        $self->{player2}->createSurface();
        if ($SHOWSCORES) {
            $self->{score}   = Score->new();
        }
    }

    sub showScreen {
        my $self = shift;
        $self->{screen}->draw_rect( [ 0, 0, $self->{screen}->w, $self->{screen}->h ], 0x000000 );
        $self->{ball}->draw($self->{screen});
        $self->{player1}->draw($self->{screen});
        $self->{player2}->draw($self->{screen});
        if ($SHOWSCORES) {
            $self->{score}->write($self->{screen},
                                  $self->{player1}->{score} . ' x ' . $self->{player2}->{score});
        }
        $self->{screen}->flip();
    }

    sub moveBall {
        my ($self, $step) = @_;
        $self->{ball}->move($step);
        $self->{ball}->checkScreenLimits($self->{screen});

        if ($self->{ball}->{rect}->right >= $self->{screen}->w ) {
            $self->{player1}->{score}++;
            $self->{ball}->resetPosition();
            return;
        }

        if ($self->{ball}->{rect}->left <= 0 ) {
            $self->{player2}->{score}++;
            $self->{ball}->resetPosition();
            return;
        }

        if ($self->check_collision($self->{ball}->{rect}, $self->{player1}->{rect})) {
            $self->{ball}->{rect}->left( $self->{player1}->{rect}->right );
            $self->{ball}->{speedx} *= -1;
        }

        if ($self->check_collision($self->{ball}->{rect}, $self->{player2}->{rect})) {
            $self->{ball}->{rect}->right( $self->{player2}->{rect}->left );
            $self->{ball}->{speedx} *= -1;
        }
    }

    sub check_collision {
        my ($self, $rect_1, $rect_2) = @_;
        if ($rect_1->bottom < $rect_2->top) {
            return;
        }
        if ($rect_1->top > $rect_2->bottom) {
            return;
        }
        if ($rect_1->right < $rect_2->left) {
            return;
        }
        if ($rect_1->left > $rect_2->right) {
            return;
        }
        # if we got here, we have a collision!
        return 1;
    }

    sub processEvents {
        my ($self, $event) = @_;
        if ($event->type == SDL_KEYDOWN) {
            if ( $event->key_sym == SDLK_UP ) {
                $self->{player1}->startMovingUp();
            }
            if ( $event->key_sym == SDLK_DOWN ) {
                $self->{player1}->startMovingDown();
            }
            if ( $event->key_sym == SDLK_q ) {
                $self->{app}->stop();
            }
        }
        if ($event->type == SDL_KEYUP) {
            if ($event->key_sym == SDLK_UP || $event->key_sym == SDLK_DOWN) {
                $self->{player1}->{speedy} = 0;
            }
        }
    }
}

package Ball {

    sub new {
        my $classname = shift;
        my $self = {speedx => int($BALLSPEED * 1.2),
                    speedy => $BALLSPEED};
        return bless($self, $classname);
    }    

    sub createSurface {
        my $self = shift;
        $self->{surface} = SDLx::Surface->new(w => 10, h => 10);
        $self->{rect}    = SDLx::Rect->new(0, 0, $self->{surface}->w, $self->{surface}->h);
        $self->{surface}->draw_rect($self->{rect}, $RED);
        $self->resetPosition();
    }

    sub move {
        my ($self, $step) = @_;
        $self->{rect}->x( $self->{rect}->x + ($self->{speedx} * $step) );
        $self->{rect}->y( $self->{rect}->y + ($self->{speedy} * $step) );
    }

    sub checkScreenLimits {
        my ($self, $screen) = @_;
        if ( $self->{rect}->bottom >= $screen->h ) {
            $self->{rect}->bottom( $screen->h );
            $self->{speedy} *= -1;
        } elsif ($self->{rect}->top <= 0 ) {
            $self->{rect}->top( 0 );
            $self->{speedy} *= -1;
        }
    }

    sub resetPosition {
        my $self = shift;
        $self->{rect}->x( $RESX / 2);
        $self->{rect}->y( $RESY / 2);
    }

    sub draw {
        my ($self, $screen) = @_;
        $screen->blit_by($self->{surface}, undef, $self->{rect});
    }
}

package Player1 {

    sub new {
        my $classname = shift;
        my $self = {speedy => 0,
                    score  => 0};
        $self->{speed} = $PLAYER1SPEED;
        return bless($self, $classname);
    }    

    sub createSurface {
        my $self = shift;
        # "That's not a paddle", Mick Dundee said, "THIS is a paddle!":
        $self->{surface} = SDLx::Surface->new(w => 10, h => 300);
        $self->{rect}    = SDLx::Rect->new(0, 0, $self->{surface}->w, $self->{surface}->h);
        $self->{surface}->draw_rect($self->{rect}, $GREY);
        $self->{rect}->topleft(100, 10);
    }

    sub startMovingUp {
        my $self = shift;
        $self->{speedy} = -$self->{speed};
    } 

    sub startMovingDown {
        my $self = shift;
        $self->{speedy} = $self->{speed};
    } 

    sub move {
        my ($self, $step) = @_;
        $self->{rect}->y(int($self->{rect}->y + ( $self->{speedy} * $step)) );
    }

    sub draw {
        my ($self, $screen) = @_;
        $screen->blit_by($self->{surface}, undef, $self->{rect});
    }
}

package Player2 {

    sub new {
        my $classname = shift;
        my $self = {speedy => 0,
                    score  => 0};
        $self->{speed} = $PLAYER2SPEED;
        return bless($self, $classname);
    }    

    sub createSurface {
        my $self = shift;
        $self->{surface} = SDLx::Surface->new(w => 10, h => 40);
        $self->{rect}    = SDLx::Rect->new(0, 0, $self->{surface}->w, $self->{surface}->h);
        $self->{surface}->draw_rect($self->{rect}, $GREY);
        $self->{rect}->topleft($RESY / 2, $RESX - 20);
    }

    sub move {
        my ($self, $step, $ball) = @_;
        if ( $ball->{rect}->y > $self->{rect}->y ) {
            $self->{speedy} = $self->{speed};
        } elsif ( $ball->{rect}->y < $self->{rect}->y ) {
            $self->{speedy} = -$self->{speed};
        } else {
            $self->{speedy} = 0;
        }
        $self->{rect}->y( $self->{rect}->y + ( $self->{speedy} * $step ) );
        return;
    }

    sub draw {
        my ($self, $screen) = @_;
        $screen->blit_by($self->{surface}, undef, $self->{rect});
    }
}

package Score {

    sub new {
        my $classname = shift;
        my $self = {};
        $self->{score} = SDLx::Text->new( font => 'arial.ttf', h_align => 'center' );
        return bless($self, $classname);
    }    

    sub write {
        my ($self, $surface, $text) = @_; 
        $self->{score}->write_xy( $surface, 450, 10, $text);
    }
}

if (! -e $FONTFILE) {
    print "\nWarning: Font file '$FONTFILE' not found in the game directory.\n";
    print "         Starting the game without displaying the scores.\n\n";
    $SHOWSCORES = 0;
}

my $app = GameWindow->new();
$app->start();
