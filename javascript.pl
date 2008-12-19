#!/usr/bin/perl

use strict;
use warnings;

use lib $ENV{COMETDESKTOP_ROOT} ? $ENV{COMETDESKTOP_ROOT}.'/perl-lib' : 'perl-lib';

use CometDesktop;

if ( $desktop->user->logged_in ) {
    $desktop->javascript_include;
} else {
    print "Content-Type: text/javascript\n\n ";
}

1;
