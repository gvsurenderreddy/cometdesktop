# Comet Desktop
# Copyright (c) 2008 - David W Davis, All Rights Reserved
# xantus@cometdesktop.com     http://xant.us/
# http://code.google.com/p/cometdesktop/
# http://cometdesktop.com/
#
# License: GPL v3
# http://code.google.com/p/cometdesktop/wiki/License

package CometDesktop::Plugin::Preferences;

use strict;
use warnings;

use CometDesktop;

$desktop->register_plugin( 'qo-preferences' => 'Preferences' );

sub request {
    my ( $self, $task, $what ) = @_;

    if ( $desktop->user->logged_in && $task && $self->can( 'cmd_'.$task ) ) {
        my $cmd = 'cmd_'.$task;
        return $self->$cmd( $what );
    }

    return 0;
}

sub new {
    my $class = shift;
    bless( { @_ }, $class || ref( $class ) );
}

sub cmd_load {
    my ( $self, $what ) = @_;

    my %valid = (
        themes => 1,
        wallpapers => 1,
    );
    return unless ( $valid{$what} );

    # TODO switch to one table
    my @t = $desktop->db->arrayHashQuery(qq|
    SELECT
        id, name,
        path_to_thumbnail as pathtothumbnail,
        path_to_file as pathtofile
    FROM
        qo_$what
    ORDER by id
    |);
    return if ( $desktop->db->{error} );

    print $desktop->encode_json({
        images => \@t
    });
    return 1;
}

sub cmd_save {
    my ( $self, $what ) = @_;

    my %valid = (
        appearance => 1,
        background => 1,
        autorun => 2,
        shortcut => 2,
        quickstart => 2,
    );
    return unless ( $valid{$what} );

    my ( $data, @formdata );
    if ( $valid{$what} == 1 ) {
        @formdata = qw(
            backgroundcolor
            fontcolor
            theme
            transparency
            wallpaper
            wallpaperposition
        );
        @{$data}{@formdata} = $desktop->cgi_params(@formdata);
    
        use bytes;
        foreach ( @formdata ) {
            return if ( !defined || length( $_ ) == 0 );
        }
    
        return unless ( $desktop->update_styles("member",$data) );
    } elsif ( $valid{$what} == 2 ) {
        @formdata = qw(
            ids
            what
        );
        @{$data}{@formdata} = $desktop->cgi_params(@formdata);
    
        use bytes;
        foreach ( @formdata ) {
            return if ( !defined || length( $_ ) == 0 );
        }
    
        return unless ( $desktop->update_launchers("member",$data) );
    } else {
        return;
    }

    print qq|{'success': true}|;
}

1;
