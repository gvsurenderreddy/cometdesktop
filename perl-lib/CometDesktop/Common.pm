# Comet Desktop
# # Copyright (c) 2008 - David W Davis, All Rights Reserved
# # xantus@cometdesktop.com     http://xant.us/
# # http://code.google.com/p/cometdesktop/
# # http://cometdesktop.com/
# #
# # License: GPL v3
# # http://code.google.com/p/cometdesktop/wiki/License

package CometDesktop::Common;

use strict;
use warnings;

sub import {
    my ( $class, $args ) = @_;
    my $package = caller();

    my @exports = qw(
        slurp
    );

    push( @exports, @_ ) if ( @_ );
    
    no strict 'refs';
    foreach ( @exports ) {
        *{ $package . '::' . $_ } = \&$_;
    }
}

sub slurp {
    local $/;
    open(FH, $_[0]) or return '';
    <FH>;
}

1;
