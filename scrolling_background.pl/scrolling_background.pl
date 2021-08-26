#!/usr/bin/perl

use warnings;
use strict;

=begin comment

    scrolling_background.pl 1.0 - An example, how to move the background in SDLx.

    Copyright (C) 2021 hlubenow

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
use SDLx::Rect;
use SDLx::Text;

my $SCALEFACTOR = 2;
my $TILESIZE    = 25;

my $PLAYERSPEED = 20;
my $DT          = 0.1;

my $SHOWNUMBERS = 1;
my $FONTFILE    = "FreeSans.ttf";

my %COLORS = (black      => [0, 0, 0, 255],
              darkgrey   => [76, 76, 76, 255],
              grey       => [140, 140, 140, 255],
              lightgrey  => [220, 220, 220, 255],
              red        => [204, 0, 0, 255],
              blue       => [0, 0, 200, 255],
              darkblue   => [0, 0, 150, 255]);

package MainWindow {

    use SDL::Event;

    sub new {
        my $classname = shift;
        my $self = {};
        $self->{addon} = AddOn->new();
        return bless($self, $classname);
    }

    sub start {
        my $self = shift;
        $self->{screenborder} = [100 * $SCALEFACTOR, 50 * $SCALEFACTOR];
        $self->{map} = Map->new($self->{addon}, $self->{screenborder});

        SDL::putenv("SDL_VIDEO_WINDOW_POS=240,20");

        $self->{screenwidth}  = $self->{screenborder}[0] + 1.1 * $self->{map}->{mappartwidth};
        $self->{screenheight} = $self->{screenborder}[1] + 1.1 * $self->{map}->{mappartheight};

        $self->{app} = SDLx::App->new(w            => $self->{screenwidth},
                                      h            => $self->{screenheight},
                                      dt           => $DT,
                                      min_t        => 1/60,
                                      title        => "SDLx - Scrolling Background",
                                      exit_on_quit => 1);
        $self->{screen} = SDLx::Surface::display();

        $self->{keystates}    = ();
        $self->{keystatekeys} = [SDLK_LEFT, SDLK_RIGHT, SDLK_UP, SDLK_DOWN, SDLK_q];
        for my $i (@{ $self->{keystatekeys} }) {
            $self->{keystates}{$i} = 0;
        }

        $self->{map}->createSurface($self->{screen});
        $self->{player} = Player->new($self->{addon}, $self->{map}, $self->{screenborder});
        $self->{player}->init();

        $self->{pressed_x}    = 0;
        $self->{pressed_y}    = 0;

        $self->{app}->add_event_handler(sub {
                                              my ( $event, $app ) = @_; 
                                              $self->processEvents($event); }); 
        $self->{app}->add_move_handler( sub {
                                              my ( $step, $app ) = @_; 
                                              $self->{player}->move($step) } );

        $self->{app}->add_show_handler( sub { $self->showScreen(); });

        $self->{app}->run();
    }

    sub showScreen {
        my $self = shift;
        $self->{addon}->fill($self->{screen}, $COLORS{darkblue});
        $self->{map}->draw($self->{screen});
        $self->{player}->draw($self->{screen});
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
            $self->{player}->startMoving("left");
        }
        $num = SDLK_RIGHT;
        if ($self->{keystates}{$num}) {
            $self->{pressed_x} = 1;
            $self->{player}->startMoving("right");
        }
        $num = SDLK_UP;
        if ($self->{keystates}{$num}) {
            $self->{pressed_y} = 1;
            $self->{player}->startMoving("up");
        }
        $num = SDLK_DOWN;
        if ($self->{keystates}{$num}) {
            $self->{pressed_y} = 1;
            $self->{player}->startMoving("down");
        }
        $num = SDLK_q;
        if ($self->{keystates}{$num}) {
            $self->{app}->stop();
        }
        if ($self->{pressed_x} == 0) {
            $self->{player}->stopMoving("x");
        }
        if ($self->{pressed_y} == 0) {
            $self->{player}->stopMoving("y");
        }
    }
}

package AddOn {

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

    sub set_xy {
        my ($self, $rect, $newx, $newy) = @_;
        $rect->topleft($newy, $newx);
    }
}

package Map {

    sub new {
        my $classname = shift;
        my $self = {};
        $self->{addon}              = shift;
        $self->{screenborder}       = shift;
        $self->{mappartsx}          = 3;  
        $self->{mappartsy}          = 3;  
        $self->{tilespermappart}    = 9;
        $self->{mappartborder}      = $SCALEFACTOR;
        $self->{tilegap}            = $SCALEFACTOR;
        # border + tile + gap + tile + gap + tile + border:
        $self->{mappartwidth}       = 2 * $self->{mappartborder} + $self->{tilespermappart} * $TILESIZE * $SCALEFACTOR + ($self->{tilespermappart} - 1) * $self->{tilegap};
        $self->{mappartheight}      = $self->{mappartwidth};
        $self->{mappart_halfwidth}  = int($self->{mappartwidth} / 2);
        $self->{mappart_halfheight} = int($self->{mappartheight} / 2);
        $self->{mapwidth}           = $self->{mappartsx} * $self->{mappartwidth};
        $self->{mapheight}          = $self->{mappartsy} * $self->{mappartheight};
        $self->{lastpart_x}         = $self->{mapwidth}  - $self->{mappartwidth};
        $self->{lastpart_y}         = $self->{mapheight} - $self->{mappartheight};
        return bless($self, $classname);
    }

    sub createSurface {
        my $self = shift;
        my $screen = shift;
        $self->{surface} = SDLx::Surface->new(w => $self->{mapwidth}, h => $self->{mapheight});
        $self->{addon}->fill($self->{surface}, $COLORS{black});
        $self->{rect} = SDLx::Rect->new(0, 0,
                                        1.1 * $self->{mappartwidth},
                                        1.1 * $self->{mappartheight});
        if ($SHOWNUMBERS) {
            $self->{numbertext} = SDLx::Text->new(font    => $FONTFILE,
                                                  color   => $COLORS{red},
                                                  size    => 32,
                                                  h_align => 'left');
        }
        my ($c, $mappart_x, $mappart_y, $tile_x, $tile_y);
        my $cnum = 1;
        my $tilerect = SDLx::Rect->new(0, 0,
                                       $TILESIZE * $SCALEFACTOR,
                                       $TILESIZE * $SCALEFACTOR);
        my $drawx = 0;
        my $drawy = 0;
        my @mapparttopleft;
        my $number = 1;

        for $mappart_y (0 .. $self->{mappartsy} - 1) {
            for $mappart_x (0 .. $self->{mappartsx} - 1) {
                @mapparttopleft = ($mappart_x * $self->{mappartwidth} + $self->{mappartborder},
                                   $mappart_y * $self->{mappartheight} + $self->{mappartborder});
                for $tile_y (0 .. $self->{tilespermappart} - 1) {
                    for $tile_x (0 .. $self->{tilespermappart} - 1) {
                        $drawx = $mapparttopleft[0] + $tile_x * ($tilerect->w + $self->{tilegap});
                        $drawy = $mapparttopleft[1] + $tile_y * ($tilerect->h + $self->{tilegap});
                        if ($cnum) {
                            $c = $COLORS{lightgrey};
                        } else {
                            $c = $COLORS{grey};
                        }
                        $tilerect->topleft($drawy, $drawx);
                        $self->{surface}->draw_rect($tilerect, $c);
                        $cnum = 1 - $cnum;
                    }
                }
                if ($SHOWNUMBERS) {
                    $self->{numbertext}->write_xy($self->{surface},
                                                  $mapparttopleft[0] + 15,
                                                  $mapparttopleft[1] + 1,
                                                  $number);
                    $number++;
                }
            }
        }
    }

    sub move {
        my ($self, $player) = @_;
        $self->{rect}->topleft($player->{y} - $player->{drawy},
                               $player->{x} - $player->{drawx});
    }

    sub draw {
        my ($self, $screen) = @_;
        my $whererect = SDLx::Rect->new(int($self->{screenborder}[0] / 2),
                                        int($self->{screenborder}[1] / 2), 0, 0);
        # surface, surfacepart_rect, where_on_screen_rect:
        $screen->blit_by($self->{surface}, $self->{rect}, $whererect);
    }
}

package Player {

    sub new {
        my $classname         = shift;
        my $self              = {};
        $self->{addon}        = shift;
        $self->{map}          = shift;
        $self->{screenborder} = shift;
        $self->{radius}       = 6;
        $self->{r}            = $self->{radius} * $SCALEFACTOR;
        # The coordinates in the game world (on the map):
        $self->{x}            = int($self->{map}->{mappartsx} / 2) * $self->{map}->{mappartwidth} + $self->{map}->{mappart_halfwidth};
        $self->{y}            = int($self->{map}->{mappartsy} / 2) * $self->{map}->{mappartwidth} + $self->{map}->{mappart_halfheight};
        # The coordinates on the screen:
        $self->{drawx}        = $self->{x};
        $self->{drawy}        = $self->{y};
        $self->{speedx}       = 0;
        $self->{speedy}       = 0;
        $self->{speed}        = $PLAYERSPEED;
        return bless($self, $classname);
    }

    sub init {
        my $self = shift;
        $self->createSurface();
        $self->setDrawCoordinates();
        $self->{map}->move($self);
    }

    sub createSurface {
        my $self = shift;
        $self->{surface} = SDLx::Surface->new(w => $self->{radius} * 2 * $SCALEFACTOR,
                                              h => $self->{radius} * 2 * $SCALEFACTOR);
        $self->{rect}    = $self->{addon}->get_rect($self->{surface});

        $self->{surface}->draw_circle_filled( [ $self->{radius} * $SCALEFACTOR,
                                                $self->{radius} * $SCALEFACTOR ],
                                              $self->{radius} * $SCALEFACTOR,
                                              $COLORS{blue} );
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
        # $self->printInfo();
        $self->{x} = int($self->{x} + $self->{speedx} * $step);
        $self->{y} = int($self->{y} + $self->{speedy} * $step);
        $self->checkBoundaries();
        $self->setDrawCoordinates();
        $self->{map}->move($self);
    }

    sub checkBoundaries {
        my $self = shift;
        $self->checkBoundary("x");
        $self->checkBoundary("y");
    }

    sub checkBoundary {
        my ($self, $coordinate) = @_;
        # Works with a square map:
        my $topleftboundary   = $self->{r} + $self->{map}->{mappartborder};
        my $downrightboundary = $self->{map}->{mapwidth} - $self->{r} - $self->{map}->{mappartborder};
        if ($self->{$coordinate} < $topleftboundary) {
            $self->{$coordinate} =  $topleftboundary;
            $self->stopMoving($coordinate);
        }
        if ($self->{$coordinate} > $downrightboundary) {
            $self->{$coordinate} = $downrightboundary;
            $self->stopMoving($coordinate);
        }
    }

    sub printInfo {
        my $self = shift;
        print "speedx/speedy: $self->{speedx}\t$self->{speedy}\n";
        print "x/y          : $self->{x}\t$self->{y}\n";
        print "drawx/drawy  : $self->{drawx}\t$self->{drawy}\n\n";
    }

    sub setDrawCoordinates {
        my $self = shift;
        if ($self->{x} < $self->{map}->{mappart_halfwidth}) {
            $self->{drawx} = $self->{x};
        } elsif ($self->{x} >= $self->{map}->{mappart_halfwidth} && $self->{x} < $self->{map}->{lastpart_x} + $self->{map}->{mappart_halfwidth}) {
            $self->{drawx} = $self->{map}->{mappart_halfwidth};
        } else {
            $self->{drawx} = $self->{x} - $self->{map}->{lastpart_x};
        }
        if ($self->{y} < $self->{map}->{mappart_halfheight}) {
            $self->{drawy} = $self->{y};
        } elsif ($self->{y} >= $self->{map}->{mappart_halfheight} && $self->{y} < $self->{map}->{lastpart_y} + $self->{map}->{mappart_halfheight}) {
            $self->{drawy} = $self->{map}->{mappart_halfheight};
        } else {
            $self->{drawy} = $self->{y} - $self->{map}->{lastpart_y};
        }

        $self->{addon}->set_xy($self->{rect},
                               int($self->{drawx} + $self->{screenborder}[0] / 2) - $self->{radius} * $SCALEFACTOR,
                               int($self->{drawy} + $self->{screenborder}[1] / 2) - $self->{radius} * $SCALEFACTOR);
    }

    sub draw {
        my ($self, $screen) = @_;
        $screen->blit_by($self->{surface}, undef, $self->{rect});
    }
}


if (! -e $FONTFILE) {
    print "\nWarning: Font-file '$FONTFILE' not found in the script directory.\n";
    print "         Starting without displaying the numbers.\n";
    print "         '$FONTFILE' can be downloaded at:\n";
    print "         http://ftp.gnu.org/gnu/freefont/freefont-ttf.zip\n\n";
    $SHOWNUMBERS = 0;
}

my $app = MainWindow->new();
$app->start();
