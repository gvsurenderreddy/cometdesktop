#!/usr/bin/perl

use strict;
use warnings;

use lib $ENV{COMETDESKTOP_ROOT} ? $ENV{COMETDESKTOP_ROOT}.'/perl-lib' : 'perl-lib';

use CometDesktop;

if ( $desktop->user->logged_in ) {
    # this may return 304 Not Modified
    $desktop->javascript_include;
} else {
    print "Content-Type: text/javascript\n\n ";
}

1;
