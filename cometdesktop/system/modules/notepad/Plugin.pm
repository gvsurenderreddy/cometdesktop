package CometDesktop::Plugin::Notepad;

# Comet Desktop
# Copyright (c) 2008 - David W Davis, All Rights Reserved
# xantus@cometdesktop.com     http://xant.us/
# http://code.google.com/p/cometdesktop/
# http://cometdesktop.com/
#
# License: GPL v3
# http://code.google.com/p/cometdesktop/wiki/License

use strict;
use warnings;

use CometDesktop;

$desktop->register_plugin( 'notepad' => 'Notepad' );

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

sub cmd_fetch {
    my ( $self, $what ) = @_;

    my %valid = (
        notes => 1,
    );
    return unless ( $valid{$what} );
    
    my @t;
    $desktop->db->arrayHashQuery(qq|
    SELECT
        id, note
    FROM 
        qo_notes
    WHERE
        qo_members_id=?
    ORDER BY id
    |,[$desktop->user->user_id],\@t);

    if ( $desktop->db->{error} ) {
        warn $desktop->db->{error};
        return 0;
    }

    print $desktop->encode_json({
        success => 'true',
        notes => \@t,
    });
}


sub cmd_save {
    my ( $self, $id ) = @_;

    my $data = {};
    # accepted data
    my @formdata = qw( note );
    @{$data}{@formdata} = $desktop->cgi_params(@formdata);
        
    my $uid = $desktop->user->user_id;

    # insert
    $data->{qo_members_id} = $uid;
    
    if ( defined $id ) {
        if ( $id =~ m/^\d+$/ ) {
            my $good = $desktop->db->scalarQuery(qq|
                SELECT 1
                FROM
                    qo_notes
                WHERE
                    qo_members_id=? AND id=?
            |,[$uid,$id]);
            return 0 unless ( $good );
            # $id is ok 
        } elsif ( $id eq 'new' ) {
            $id = undef;
        } else {
            return 0;
        }
    }

    if ( defined $id ) {
        # valid id, update it
        $desktop->db->updateWithWhere('qo_notes','qo_members_id=? AND id=?',[$uid,$id],$data);
    } else {
        # new note, insert it
        $desktop->db->insertWithHash('qo_notes',$data,\$id);
        if ( $id ) {
            warn "new note: $id";
        }
    }
    if ( $desktop->db->{error} ) {
        warn $desktop->db->{error};
        return 0;
    }

    print $desktop->encode_json({
        success => 'true',
        noteId => $id,
    });
}

sub cmd_delete {
    my ( $self, $id ) = @_;

    return 0 unless ( $id );
    return 0 unless ( $id =~ m/^\d+$/ );

    $desktop->db->doQuery(qq|
        DELETE
        FROM
            qo_notes
        WHERE
            qo_members_id=? AND id=?
    |,[$desktop->user->user_id,$id]);
    if ( $desktop->db->{error} ) {
        warn $desktop->db->{error};
        return 0;
    }
    $desktop->db->doQuery(qq|
        DELETE
        FROM
            qo_registry
        WHERE
            qo_members_id=? AND name=?
    |,[$desktop->user->user_id,"notepad-win-$id"]);

    print $desktop->encode_json({
        success => 'true'
    });
}
1;
