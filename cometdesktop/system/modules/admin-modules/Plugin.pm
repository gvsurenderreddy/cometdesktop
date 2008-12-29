# Comet Desktop
# Copyright (c) 2008 - David W Davis, All Rights Reserved
# xantus@cometdesktop.com     http://xant.us/
# http://code.google.com/p/cometdesktop/
# http://cometdesktop.com/
#
# License: GPL v3
# http://code.google.com/p/cometdesktop/wiki/License

package CometDesktop::Plugin::AdminModules;

use strict;
use warnings;

use CometDesktop;

$desktop->register_plugin( 'admin-modules' => 'AdminModules' );

sub request {
    my ( $self, $task, $what ) = @_;
     
    $desktop->content_type( 'text/javascript' );

    return $desktop->out({ success => 'false' }) unless ( $desktop->user->is_admin );

    if ( $desktop->user->logged_in && $task && $self->can( 'cmd_'.$task ) ) {
        my $cmd = 'cmd_'.$task;
        return $desktop->out({ success => 'false' }) unless ( $self->$cmd( $what ) );
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
    return unless ( $valid{$what} );
    
    my @t = $desktop->db->arrayHashQuery(qq|
        SELECT
            *
        FROM 
            qo_modules
        ORDER BY id
    |);
    
    my @files = $desktop->db->arrayHashQuery(qq|
        SELECT
            qo_modules_id as id, name, type
        FROM 
            qo_modules_has_files
        ORDER BY type
    |);

    my $f = {};
    foreach ( @files ) {
        push( @{$f->{ delete $_->{id} } }, $_ );
    }

    foreach ( @t ) {
        $_->{files} = $f->{ $_->{id} } || [];
        $_->{active} = $_->{active} eq 'true' ? 'on' : 'off';
    }

    $desktop->out({
        success => 'true',
        modules => \@t,
    });
    return 1;
}


sub cmd_save {
    my ( $self, $data ) = @_;

    return unless ( $data && $data =~ m/^{/ );

    $data = $desktop->decode_json( $data );

#    my $data = {};
#    my @formdata = qw(  )
#    @{$data}{@formdata} = $desktop->cgi_params(@formdata);
        
#    use bytes;
#    shift @formdata; # note can be blank

#    foreach ( @formdata ) {
#        return if ( !defined || length( $_ ) == 0 );
#    }

    my $uid = $desktop->user->user_id;
    my $id = $data->{id};
    
    if ( defined $id ) {
        if ( $id =~ m/^\d+$/ ) {
            my $good = $desktop->db->scalarQuery(qq|
                SELECT 1
                FROM
                    qo_modules
                WHERE
                    id=?
            |,[$id]);
            return 0 unless ( $good );
            # $id is ok 
        } elsif ( $id eq 'new' ) {
            $id = undef;
        } else {
            return 0;
        }
    }

    $data->{active} = ( $data->{active} && $data->{active} eq 'on' ) ? 'true' : 'false';

    if ( defined $id ) {
        # valid id, update it
        $desktop->db->updateWithWhere('qo_modules','id=?',[$id],$data);
    } else {
        # new module, insert it
        $desktop->db->insertWithHash('qo_modules',$data,\$id);
    }

    if ( $data->{files} && ref( $data->{files} ) eq 'ARRAY' ) {
        $desktop->db->doQuery(qq|
            DELETE
            FROM
                qo_modules_has_files
            WHERE
                qo_modules_id=?
        |,[$id]);

        foreach ( @{ $data->{files} } ) {
            $_->{qo_modules_id} = $id;
            delete $_->{id};
            $desktop->db->insertWithHash('qo_modules_has_files',$_);
        }

    }

    $desktop->out({
        success => 'true',
        id => $id,
    });
    return 1;
}

sub cmd_delete {
    my ( $self, $id ) = @_;

    return;

    return 0 unless ( $id );
    return 0 unless ( $id =~ m/^\d+$/ );

    $desktop->db->doQuery(qq|
        DELETE
        FROM
            qo_modules
        WHERE
            id=?
    |,[$id]);
    $desktop->db->doQuery(qq|
        DELETE
        FROM
            qo_modules_has_files
        WHERE
            qo_modules_id=?
    |,[$id]);

    $desktop->out({ success => 'true' });
    return 1;
}
1;
