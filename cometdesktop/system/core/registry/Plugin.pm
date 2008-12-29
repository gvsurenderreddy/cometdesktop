# Comet Desktop
# Copyright (c) 2008 - David W Davis, All Rights Reserved
# xantus@cometdesktop.com     http://xant.us/
# http://code.google.com/p/cometdesktop/
# http://cometdesktop.com/
#
# License: GPL v3
# http://code.google.com/p/cometdesktop/wiki/License

package CometDesktop::Plugin::Registry;

use strict;
use warnings;

use CometDesktop;

$desktop->register_plugin( 'registry' => 'Registry' );

sub request {
    my ( $self, $task, $what ) = @_;

    if ( $desktop->user->logged_in && $task && $self->can( 'cmd_'.$task ) ) {
        $desktop->content_type( 'text/javascript' );
        my $cmd = 'cmd_'.$task;
        $self->$cmd( $what );
        return;
    }

    $desktop->error( 'no such task' )->throw;
}

sub new {
    my $class = shift;
    bless( { @_ }, $class || ref( $class ) );
}

sub cmd_fetch {
    my ( $self, $what ) = @_;

    my %valid = (
        all => 1,
    );
    $desktop->error( 'var what is required' )->throw unless ( $valid{$what} );
    
    my $ud = $desktop->user->user_data;

    my $state = {};
    $desktop->db->keyvalHashQuery(qq|
    SELECT
        name, val
    FROM 
        qo_registry
    WHERE
        qo_members_id=?
    |,[$ud->{id}],$state);

    while( my ( $k, $v ) = each( %$state ) ) {
        $state->{$k} = $desktop->decode_json( $v );
    }

    $desktop->out({ success => 'true', state => $state });
}

sub cmd_set {
    my ( $self, $name ) = @_;

    $desktop->error( 'var what is required' )->throw unless ( defined $name );

    my $value = $desktop->cgi_param('value');
        
    my $ud = $desktop->user->user_data;

    my $exists = $desktop->db->scalarQuery(qq|
        SELECT 1
        FROM
            qo_registry
        WHERE
            qo_members_id=? AND name=?
    |,[$ud->{id},$name]);

    my $data = {
        val => $value,
    };
    if ( $exists ) {
        if ( !defined( $value ) || $value eq 'null' || $value eq 'undefined' ) {
            $desktop->db->doQuery(qq|DELETE FROM qo_registry WHERE qo_members_id=? AND name=?|,[$ud->{id},$name]);
        } else {
            $desktop->db->updateWithWhere('qo_registry','qo_members_id=? AND name=?',[$ud->{id},$name],$data);
        }
    } elsif ( !defined( $value ) || $value eq 'null' || $value eq 'undefined' ) {
        # skip insert
    } else {
        $data->{qo_members_id} = $ud->{id};
        $data->{name} = $name;
        $desktop->db->insertWithHash('qo_registry',$data);
    }

    $desktop->out({ success => 'true' });
}


1;
