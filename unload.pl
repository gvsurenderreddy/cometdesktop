#!/usr/bin/perl

use strict;
use warnings;

use lib $ENV{COMETDESKTOP_ROOT} ? $ENV{COMETDESKTOP_ROOT}.'/perl-lib' : 'perl-lib';

use CometDesktop;
    
print "Pragma: nocache\n";
print "Cache-Control: no-cache\n";
print "Expires: 0\n";
print "Content-Type: text/plain\n\n";

if ( $ENV{REQUEST_METHOD} eq 'POST' ) {
    eval {
    if ( $desktop->user->logged_in ) {
        my $data = $ENV{HTTP_X_SESSIONTIME};
        if ( defined $data ) {
            my ( $start, $end ) = split( '~', $data );
            if ( defined $start && defined $end ) {
                my ( $startc, $startt ) = split( '/', $start );
                my ( $endc, $endt ) = split( '/', $end );
                my $secs = $endt - $startt;
                warn "session duration: ($secs) $start~$end\n";
                $desktop->user->session_duration( $secs );
            }
        }
        $desktop->user->inactivate_session();
    }
    };
}

print "OK";

1;
