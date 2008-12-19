# Comet Desktop
# Copyright (c) 2008 - David W Davis, All Rights Reserved
# xantus@cometdesktop.com     http://xant.us/
# http://code.google.com/p/cometdesktop/
# http://cometdesktop.com/
#
# License: GPL v3
# http://code.google.com/p/cometdesktop/wiki/License

package CometDesktop::User;

use strict;
use warnings;

use CometDesktop qw(
    -Digest::SHA1[sha1_hex]
);

use Class::Accessor::Fast;
use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors(qw(
    session_id
    logged_in
    user_id
    is_admin
    is_guest
    group_id
    first_name
    last_name
    email_address
    password
    active
    inactive
    session_duration
    total_duration
));

sub new {
    my $class = shift;
#    my $desktop = shift;

    my $self = bless({
        user_data => {},
        logged_in => 0,
        is_admin => 0,
        is_guest => 0,
        session_duration => 0,
        total_duration => 0,
    }, $class || ref( $class ) );

    my $sid = shift->session_cookie();
    if ( $sid ) {
        my $data = $self->load_session( $sid );
        if ( defined $data ) {
            $self->user_data( $data );
            $self->logged_in( 1 );
            $self->session_id( $sid );
        }
    }

    return $self;
}

sub login {
    my ( $self, $user, $sha, $token ) = @_;

    if ( defined $user && length( $user ) > 0 && defined $sha && length( $sha ) > 0 ) {
        $self->logout();
        my $data = $self->load_user( $user, $sha, $token );
        if ( defined $data ) {
            if ( $data->{invalid_token} ) {
                print qq|{ "reload": true }|;
                return 2;
            }
            $self->user_data( $data );
            $self->session_id( $self->generate_sid );
            $self->logged_in( 1 );
    
            $desktop->db->doQuery('UPDATE qo_members SET logins=logins+1 WHERE id=?',[ $self->user_id ]);

            $desktop->db->insertWithHash('qo_sessions',{
                id => $self->session_id,
                qo_members_id => $self->user_id,
                ip => $ENV{REMOTE_ADDR},
                date => '_raw:NOW()',
                last_active => '_raw:NOW()',
                inactive => 0,
                session_duration => 0,
                useragent => $ENV{HTTP_USER_AGENT},
            });
            return 1;
        } else {
            print qq|{errors:[{id:'user', msg:'Password incorrect, or user not found'}]}|;
            return 2;
        }
    } else {
        if ( !defined $user || length( $user ) == 0 ) {
            print qq|{errors:[{id:'user', msg:'Username is required'}]}|;
        } else {
            print qq|{errors:[{id:'pass', msg:'Password is required'}]}|;
        }
        return 2;
    }

    return undef;
}

sub logout {
    my $self = shift;
    return unless ( $self->logged_in );

    $desktop->db->doQuery('DELETE FROM qo_sessions WHERE id=?',[ $self->session_id ]);
    $self->user_data( {} );
    $self->logged_in( 0 );

    return 1;
}

sub inactivate_session {
    my $self = shift;
    return unless ( $self->logged_in );

    # TODO log the duration
    $desktop->db->doQuery('UPDATE qo_sessions SET inactive=1,session_duration=? WHERE id=?',[ $self->session_duration, $self->session_id ]);
    
    $desktop->db->doQuery('UPDATE qo_members SET total_time=? WHERE id=?',[ ( $self->total_duration + $self->session_duration ), $self->user_id ]);

    return 1;
}

sub load_user {
    my ( $self, $user, $pass, $token ) = @_;

    unless ( $user && $pass && $token ) {
        warn "user pass and token required";
        return;
    }

    my ( $verify, $ttime );
    ( $verify, $pass ) = split( ':', $pass, 2 );
    unless ( $verify && $pass ) {
        warn "verify and pass not split";
        return;
    }
    ( $ttime, $token ) = split( '~', $token, 2 );
    unless ( $token && $ttime ) {
        warn "ttime and token not split";
        return;
    }
    unless ( $ttime =~ m/^\d+$/ ) {
        warn "ttime is not numeric";
        return;
    }
    
    my $time = CORE::time();

    # check token time against time
    if ( $time - $ttime > 1200 ) {
        warn "ttime has expired";
        return { invalid_token => 1 };
    }
    
    # check token against time and secret key
    my $check1 = sha1_hex( $ttime.':'.$desktop->login_secret );
    unless ( $check1 eq $token ) {
        warn "token doesn't verify against secret and ttime";
        return;
    }

    # check login against the token
    my $check = sha1_hex( $token.':'.$pass );

    warn "time:$time ttime:$ttime token:$token sha:$pass check:$check check1:$check1 ver:$verify";
    unless ( $verify eq $check ) {
        warn "check doesn't verify against token and pass";
        return;
    }

    my $data = {};
    $desktop->db->hashQuery(qq|
        SELECT m.*, mg.qo_groups_id as groups_id
        FROM qo_members AS m
        JOIN qo_members_has_groups as mg
            ON m.id=mg.qo_members_id
            AND mg.active='true'
        WHERE m.email_address=?
        AND m.password=?
    |, [$user, $pass], $data );
    return undef if ( $desktop->db->{error} );
            
    $desktop->db->doQuery('UPDATE qo_members SET last_access=NOW() WHERE id=?',[ $data->{id} ]);

    return ( $data->{id} ) ? $data : undef;
}

sub load_session {
    my ( $self, $sid ) = @_;

    my $data = {};
    $desktop->db->hashQuery(qq|
        SELECT m.*, mg.qo_groups_id as groups_id, s.session_duration
        FROM qo_sessions AS s
        JOIN qo_members AS m
        ON m.id=s.qo_members_id
        JOIN qo_members_has_groups as mg
            ON m.id=mg.qo_members_id
            AND mg.active='true'
        WHERE s.id=?|, [$sid], $data );
    return undef if ( $desktop->db->{error} );

    if ( $data->{id} ) {
        $data->{inactive} = 0;
        if ( defined $ENV{HTTP_X_SESSION_DURATION} && $ENV{HTTP_X_SESSION_DURATION} =~ m/^\d+$/ ) {
            $desktop->db->doQuery(qq|
                UPDATE qo_sessions
                    SET last_active=NOW(),
                    inactive=0,
                    useragent=?,
                    session_duration=?
                WHERE id=?
            |,[$ENV{HTTP_USER_AGENT},$ENV{HTTP_X_SESSION_DURATION},$sid]);
        } else {
            $desktop->db->doQuery(qq|
                UPDATE qo_sessions
                    SET last_active=NOW(),
                    inactive=0,
                    useragent=?
                WHERE id=?
            |,[$ENV{HTTP_USER_AGENT},$sid]);
        }
        $desktop->db->doQuery('UPDATE qo_members SET last_access=NOW() WHERE id=?',[ $data->{id} ]);
        return undef if ( $desktop->db->{error} );
    }

    return ( $data->{id} ) ? $data : undef;
}

sub generate_sid {
    my $self = shift;
    # XXX switch to uuid sessions?
    return sha1_hex( int(rand(10000000000)).':'.$self->user_id.':'.( $ENV{HTTP_USER_AGENT} || '' ) );
}

sub session_id_tokenized {
    my $self = shift;
    my $sid = $self->session_id;
    return undef unless $sid;
    if ( $desktop->extra_security ) {
        return sha1_hex( $sid.':'.$desktop->session_secret.':'.( $ENV{HTTP_USER_AGENT} || '' ) ).'/'.$sid;
    } else {
        return sha1_hex( $sid.':'.$desktop->session_secret ).'/'.$sid;
    }
}

sub user_data {
    my ( $self, $data ) = @_;
    
    if ( ref $data ) {
        $self->{user_data} = $data;
        # group_id 1 is admin
        @{$self}{qw(
            user_id
            group_id
            first_name
            last_name
            email_address
            password
            inactive
            session_duration
            total_duration
        )} = @{$data}{qw(
            id
            groups_id
            first_name
            last_name
            email_address
            password
            inactive
            session_duration
            total_time
        )};
        $self->is_admin( defined $data->{groups_id} && $data->{groups_id} == 1 ? 1 : 0 );
        $self->is_guest( defined $data->{groups_id} && $data->{groups_id} == 3 ? 1 : 0 );
    }

    return $self->{user_data};
}

1;
