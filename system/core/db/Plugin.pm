# Comet Desktop
# Copyright (c) 2008 - David W Davis, All Rights Reserved
# xantus@cometdesktop.com     http://xant.us/
# http://code.google.com/p/cometdesktop/
# http://cometdesktop.com/
#
# License: GPL v3
# http://code.google.com/p/cometdesktop/wiki/License

package CometDesktop::Plugin::DB;

use strict;
use warnings;

use CometDesktop;

$desktop->register_plugin( 'ajax-db' => 'DB' );

sub request {
    my ( $self, $task, $dbname ) = @_;

    if ( $desktop->user->logged_in && $task && $self->can( 'cmd_'.$task ) ) {
        my $cmd = 'cmd_'.$task;
        return $self->$cmd( $dbname );
    }

    return 0;
}

sub new {
    my $class = shift;
    bless( { @_ }, $class || ref( $class ) );
}

sub db {
    my ( $self, $dbname ) = @_;

    return $self->{db} if ( $self->{db} );

    $dbname ||= 'noname';
    $dbname =~ s/[^a-zA-Z0-9\.]//g;

#    warn "opening db: $dbname";

    $self->{db} = CometDesktop::DB->new(
        'SQLite2:dbname='.$desktop->pwd.'perl-lib/tmp/user-'.$desktop->user->user_id.'-'.$dbname.'.sqlite2',
        '',
        ''
    );
#    warn $self->{db}->{error} if ( $self->{db}->{error} );
    return $self->{db};
}

sub cmd_query {
    my ( $self, $dbname ) = @_;

    my ( $sql, $args ) = $desktop->cgi_params( 'sql', 'args' );
    return 0 unless ( $sql && $dbname );
    
    if ( defined $args ) {
        $args = $desktop->decode_json( $args );
        return 0 unless ( ref $args eq 'ARRAY' );
#        warn "sqlite query $sql bind:".join(',',@$args);
    } else {
#        warn "sqlite query $sql";
    }

    my $db = $self->db( $dbname );

    my @t;
    if ( $args ) {
        $db->arrayHashQuery( $sql, $args, \@t );
    } else {
        @t = $db->arrayHashQuery( $sql );
    }
    print $desktop->encode_json({
        error => $db->{error},
    }), return 1 if ( $db->{error} );

    print $desktop->encode_json({
        success => 'true',
        result => \@t,
    });

    return 1;
}

sub cmd_exec {
    my ( $self, $dbname ) = @_;

    my ( $sql, $args ) = $desktop->cgi_params( 'sql', 'args' );
    return 0 unless ( $sql );

    if ( defined $args ) {
        $args = $desktop->decode_json( $args );
        return 0 unless ( ref $args eq 'ARRAY' );
#        warn "sqlite exec $sql bind:".join(',',@$args);
    } else {
#        warn "sqlite exec $sql";
    }

    # not supported in sqlite2
#    $sql =~ s/IF NOT EXISTS//;
    
    my $db = $self->db( $dbname );

    my $res;
    if ( $args ) {
        $res = $db->doQuery( $sql, $args );
    } else {
        $res = $db->doQuery( $sql );
    }
    print $desktop->encode_json({
        error => $db->{error},
    }), return 1 if ( $db->{error} );

    print $desktop->encode_json({
        success => 'true',
        result => $res,
    });
    return 1;
}

1;
