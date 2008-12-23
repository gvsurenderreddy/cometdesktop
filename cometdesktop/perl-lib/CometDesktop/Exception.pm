# Comet Desktop
# Copyright (c) 2008 - David W Davis, All Rights Reserved
# xantus@cometdesktop.com     http://xant.us/
# http://code.google.com/p/cometdesktop/
# http://cometdesktop.com/
#
# License: GPL v3
# http://code.google.com/p/cometdesktop/wiki/License

package CometDesktop::Exception;

use strict;
use warnings;

use CometDesktop;

sub new {
    my $class = shift;
    my $self = bless( {
        caller_report => [qw(
            package
            filename
            line
            sub
            hashargs
            wantarray
            evaltext
            is_require
            hints
            bitmask
        )],
        caller => {},
        @_
    }, ref $class || $class );
    
    # build a hashref of key => val of reportable values from caller()
    # ($package, $filename, $line, $subroutine, $hasargs,
    #   $wantarray, $evaltext, $is_require, $hints, $bitmask)
    @{$self->{caller}}{@{$self->{caller_report}}} = caller(2);

    return $self;
}

*throw = *plain_throw;

sub plain_throw {
    my $self = shift;
    use bytes;
    my $desktop = $CometDesktop::singleton;
    $desktop->content_type( 'text/plain' );
    my $content = "\nError ".( $self->{error} || 'unknown' )."\n\n";
    foreach ( @{$self->{caller_report}} ) {
        next unless defined;
        $content .= "$_: ".( $self->{caller}->{$_} || 'NULL' )."\n";
    }
    $desktop->header(
        "Status: 500",
#        'Content-Length: '.length($content)
    );
    $desktop->out( $content );
    exit;
}

1;

