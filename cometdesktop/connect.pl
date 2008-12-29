#!/usr/bin/perl

use strict;
use warnings;

use lib $ENV{COMETDESKTOP_ROOT} ? $ENV{COMETDESKTOP_ROOT}.'/perl-lib' : 'perl-lib';

use CometDesktop;

unless( $desktop->user->logged_in ) {
    $desktop->header( "Status: 401" );
    $desktop->out();
    exit;
}

if ( $ENV{REQUEST_METHOD} eq 'POST' && $desktop->user->logged_in ) {
    eval {
        $desktop->call_plugin();
    };
    if ( $@ ) {
        my $type = $desktop->content_type;
        if ( $type eq 'text/xml' ) {
            $desktop->out( '<?xml version="1.0"?>' );
        } elsif ( $type eq 'text/javascript' ) {
            $desktop->out({ success => true });
        }
    }
}

1;
