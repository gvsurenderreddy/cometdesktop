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
        $desktop->content_type( 'text/javascript' );
        my $cmd = 'cmd_'.$task;
        $self->$cmd( $dbname );
        return;
    }

    $desktop->error( 'no such task' )->throw;
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
        'SQLite2:dbname='.$desktop->tempdir.'user-'.$desktop->user->user_id.'-'.$dbname.'.sqlite2',
        '',
        ''
    );
#    warn $self->{db}->{error} if ( $self->{db}->{error} );
    return $self->{db};
}

sub cmd_query {
    my ( $self, $dbname ) = @_;

    my ( $sql, $args ) = $desktop->cgi_params( 'sql', 'args' );
    $desktop->error( 'bad params' ) unless ( $sql && $dbname );
    
    if ( defined $args ) {
        $args = $desktop->decode_json( $args );
        $desktop->error( 'bad args' )->throw unless ( ref $args eq 'ARRAY' );
#        warn "sqlite query $sql bind:".join(',',@$args);
    } else {
#        warn "sqlite query $sql";
    }

    my $db = $self->db( $dbname );

    my @t;
    eval {
        # this forces the db to use die, so we can trap it
        $db->no_exceptions;
        if ( $args ) {
            $db->arrayHashQuery( $sql, $args, \@t );
        } else {
            @t = $db->arrayHashQuery( $sql );
        }
        $db->use_exceptions;
    };
    return $desktop->out({
        error => $@,
    }) if ( $@ );

    $desktop->out({
        success => 'true',
        result => \@t,
    });
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
    eval {
        # this forces the db to use die, so we can trap it
        $db->no_exceptions;
        if ( $args ) {
            $res = $db->doQuery( $sql, $args );
        } else {
            $res = $db->doQuery( $sql );
        }
        $db->use_exceptions;
    };
    return $desktop->out({
        error => $@,
    }) if ( $@ );

    $desktop->out({
        success => 'true',
        result => $res,
    });
}

1;
