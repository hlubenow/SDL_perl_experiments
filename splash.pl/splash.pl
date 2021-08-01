#!/usr/bin/perl

use strict;
use warnings;

=begin comment

    splash 1.0 - Retro style drawing demo in SDL_perl 

    Perl Code Copyright (C) 2021 hlubenow

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
use SDLx::FPS;

my $SCALEFACTOR = 3;

package ZXEnvironment {

    sub new {
        my $classname = shift;
        my $self = {};
        $self->{zx_width} = 256;
        $self->{zx_height} = 176;
        $self->{zx_char_width} = $self->{zx_width} / 8; # 32
        $self->{zx_char_height} = $self->{zx_height} / 8; # 22
        $self->{zx_border} = 16; # 2
        $self->{pc_paperwidth} = $self->{zx_width} * $SCALEFACTOR;
        $self->{pc_paperheight} = $self->{zx_height} * $SCALEFACTOR;
        $self->{pc_border} = $self->{zx_border} * $SCALEFACTOR;
        $self->{screenwidth} = ($self->{zx_width} + 2 * $self->{zx_border}) * $SCALEFACTOR;
        $self->{screenheight} = ($self->{zx_height} + 2 * $self->{zx_border}) * $SCALEFACTOR;
        return bless($self, $classname);
    }    
}

package Data {

    sub new {
        my $classname = shift;
        my $self = {};
        $self->{colors} = { black => [0, 0, 0, 255],
                            red   => [189, 0, 0, 255],
                            white => [200, 200, 200, 255] };
        return bless($self, $classname);
    }    
}


package SplashWindow {

    use SDL::Event;

    sub new {
        my $classname = shift;
        my $self = {};
        $self->{zx_env} = ZXEnvironment->new();
        $self->{data}   = Data->new();
        return bless($self, $classname);
    }

    sub createScreen {
        my $self = shift;
        SDL::putenv("SDL_VIDEO_WINDOW_POS=130,18");
        $self->{app} = SDLx::App->new(w => $self->{zx_env}->{screenwidth},
                                      h => $self->{zx_env}->{screenheight},
                                      title => 'Splash');
        $self->{screen} = SDLx::Surface::display();
        $self->{fps} = SDLx::FPS->new(fps => 50);
        $self->{event} = SDL::Event->new();

        $self->{paper} = SDLx::Surface->new(w => $self->{zx_env}->{pc_paperwidth}, h => $self->{zx_env}->{pc_paperheight});

        $self->{paperrect} = $self->get_rect($self->{paper});
        $self->{paperrect}->topleft($self->{zx_env}->{pc_border}, $self->{zx_env}->{pc_border});
    
        $self->fill($self->{screen}, $self->{data}->{colors}->{red});
        $self->fill($self->{paper}, $self->{data}->{colors}->{white});
        $self->{running} = 1;

        my @m = ();
        my $i;
        for $i (0 .. 1000) {
            push(@m, 0);
        }
        my $cos45 = cos(3.141592 / 4);
        my $peak_width = -0.001;
        my $peak_height = 80;
        my ($x1, $y1, $e, $c, $d, $z);
        my $x = 1;
        my $y = 1;

        # Main Loop:

        while ($self->{running}) {
            if ($self->handleEvents() eq "quit") {
                $self->{running} = 0;
            }
            # $self->{fps}->delay();

            if ($y <= 141) {
                $x++;
                $e = $cos45 * $y;
                $c = $y - 70;
                $c *= $c;
                if ($x <= 141) {
                    $d = $x - 70;
                    $z = $peak_height * exp($peak_width * ($c + $d * $d));
                    $x1 = $x + $e;
                    $y1 = $z + $e;
                    # Skip overlapping points:
                    if ($y1 >= $m[int($x1)]) {
                        $m[int($x1)] = $y1;
                        $self->plot($x1, $y1);
                    }
                }
                if ($x > 141) {
                    $x = 1;
                    $y += 5;
                }
            }

            $self->{screen}->blit_by($self->{paper}, undef, $self->{paperrect});
            $self->{screen}->flip();
        }
    }

    sub handleEvents {
        my $self = shift;
        SDL::Events::pump_events();
        if (SDL::Events::poll_event($self->{event})) {
            if ($self->{event}->type == SDL_KEYDOWN ) { 
                if ($self->{event}->key_sym == SDLK_q) {
                    return "quit";
                }
            }
        }
        return 0;
    }   

    sub plot {
        my $self = shift;
        my $zx_x = shift;
        my $zx_y = shift;
        $zx_y = $self->{zx_env}->{zx_height} - $self->{zx_env}->{zx_border} - $zx_y; 
        $self->{paper}->draw_rect( [ $zx_x * $SCALEFACTOR, $zx_y * $SCALEFACTOR, $SCALEFACTOR, $SCALEFACTOR ], $self->{data}->{colors}->{black});
    }

    sub getColor {
        my $self = shift;
        my @a = @{ shift() };
        return SDL::Video::map_RGB($self->{screen}->format, $a[0], $a[1], $a[2] );
    }

    sub fill {
        my $self = shift;
        my $surface = shift;
        my $colorref = shift;
        $surface->draw_rect( [ 0, 0, $surface->w, $surface->h ], $colorref);
    }

    sub get_rect {
        my $self = shift;
        my $surface = shift;
        return SDLx::Rect->new(0, 0, $surface->w, $surface->h);
    }
}

my $app = SplashWindow->new();
$app->createScreen();
