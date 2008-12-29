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
        )],
#            hints
#            bitmask
        caller => {},
        @_
    }, ref $class || $class );
    
    # build a hashref of key => val of reportable values from caller()
    # ($package, $filename, $line, $subroutine, $hasargs,
    #   $wantarray, $evaltext, $is_require, $hints, $bitmask)
    @{$self->{caller}}{@{$self->{caller_report}}} = caller(2);

    return $self;
}

sub throw {
    my $self = shift;
    if ( $self->{throw_die} ) {
        my $error = "\nError ".( $self->{error} || 'unknown' ).' ';
#        foreach ( @{$self->{caller_report}} ) {
#            next unless defined;
#            $error .= "$_: ".( $self->{caller}->{$_} || 'NULL' ).", ";
#        }
        die "$error\n";
    } else {
        return $self->html_throw;
    }
}

sub html_throw {
    my $self = shift;
    use bytes;
    my $desktop = $CometDesktop::singleton;
    $desktop->content_type( 'text/html' );
    my $content = '<html><head><title>Comet Desktop - Error 500</title></head>'
        .'<body><h3>Error 500</h3><pre>'.( $self->{error} || 'unknown' )."\n\n";
    foreach ( @{$self->{caller_report}} ) {
        next unless defined;
        $content .= "$_: ".( $self->{caller}->{$_} || 'NULL' )."\n";
    }
    if ( $self->{dump_var} ) {
        require Data::Dumper;
        $content .= Data::Dumper->Dump([$self->{dump_var}]);
    }
    $content .= "</pre></frameset></body></html>";
    $desktop->header(
        "Status: 500",
#        'Content-Length: '.length($content)
    );
    $desktop->out( $content );
    exit;
}

1;

