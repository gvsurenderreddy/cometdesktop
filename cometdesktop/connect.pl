#!/usr/bin/perl

use strict;
use warnings;

use lib $ENV{COMETDESKTOP_ROOT} ? $ENV{COMETDESKTOP_ROOT}.'/perl-lib' : 'perl-lib';

use CometDesktop;

unless( $desktop->user->logged_in ) {
    print "Status: 401\n\n";
    exit;
}

my $type = $desktop->cgi_param( 'type' );

if ( defined $type && $type eq 'xml' ) {
    print "Content-Type: text/xml\n\n";
} else {
    print "Content-Type: text/javascript\n\n";
}

if ( $ENV{REQUEST_METHOD} eq 'POST' && $desktop->user->logged_in ) {
    exit if ( $desktop->call_plugin() );
}

# TODO use an accept header
if ( defined $type && $type eq 'xml' ) {
    print '<?xml version="1.0"?>';
} else {
    print qq|{'success': false}|;
}

1;
