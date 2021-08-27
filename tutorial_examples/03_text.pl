#!/usr/bin/perl

use warnings;
use strict;

# SDL_perl Example 3

# Displaying text by rendering a font.

# Copyright (C) 2021 hlubenow
# License: GNU GPL 3.

use SDLx::App;
use SDLx::Text;
use SDL::Event;

my $FONTFILE = "FreeSans.ttf";

if (! -e $FONTFILE) {
    print "\nError: Font-file '$FONTFILE' not found in the script directory.\n";
    print "       '$FONTFILE' can be downloaded at:\n";
    print "       http://ftp.gnu.org/gnu/freefont/freefont-ttf.zip\n\n";
    exit 1;
}

SDL::putenv("SDL_VIDEO_WINDOW_POS=320,100");
my $app  = SDLx::App->new(w => 640,
                          h => 480,
                          title => "Text example",
                          eoq   => 1);
my $event = SDL::Event->new();

my $text = SDLx::Text->new(font  => $FONTFILE,
                           color => [220, 50, 50, 255],
                           size    => 32, 
                           h_align => 'center');

while (1) {
    processEvents($event);
    $text->write_xy($app, 300, 200, "Hello World!");
    $app->flip();
}

sub processEvents {
    my $event = shift;
    SDL::Events::pump_events();
    if (SDL::Events::poll_event($event)) {
        if ($event->type == SDL_KEYDOWN ) {
            if ($event->key_sym == SDLK_q) {
                exit;
            }
        }
    }
}
