# Comet Desktop
# Copyright (c) 2008 - David W Davis, All Rights Reserved
# xantus@cometdesktop.com     http://xant.us/
# http://code.google.com/p/cometdesktop/
# http://cometdesktop.com/
#
# License: GPL v3
# http://code.google.com/p/cometdesktop/wiki/License

package CometDesktop;

use strict;
use warnings;

use Class::Accessor::Fast;
use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors(qw(
    user
    cgi
    db
    db_dsn
    db_user
    db_pass
    plugins
    login_secret
    session_secret
    version
    pwd
    localmode
    extra_security
));

use Carp qw( croak );

our $singleton;

sub import {
    shift;

    my @modules = @_;

    my $package = caller();
    my @failed;
    
    {
        no strict 'refs';
        *{ $package . '::desktop' } = \$singleton;
    }

    # load the config and set optional include dirs before loading any modules
    CometDesktop->new() unless ( defined( $singleton ) );

    unshift( @modules, 'Common', '-Time::HiRes[time]' );

    @modules = map { s/^-// ? $_ : 'CometDesktop::'.$_  } @modules;

    foreach my $module ( @modules ) {
        my $code;
        if ( $module =~ s/\[([^\]]+)\]// ) {
            my $q = $1; $q =~ s/,/ /g;
            $code = "package $package; use $module qw($q);";
        } else {
            $code = "package $package; use $module;";
        }
        eval( $code );
        if ( $@ ) {
            warn $@;
            push( @failed, $module );
        }
    }

    @failed and croak 'could not import (' . join( ' ', @failed ) . ')';
}


sub new {
    my $class = shift;
    croak "$class requires an even number of parameters" if @_ % 2;
    return $singleton if ( $singleton );
    
    # FindBin?
    my $pwd = $ENV{SCRIPT_FILENAME} || $ENV{PWD} || '/tmp';
    $pwd =~ s/\/[a-zA-Z]+\.(pl|cgi)$/\//;

    $ENV{PWD} = $pwd;
    # XXX chdir?

    my $self = $singleton = $class->SUPER::new({
        pwd => $pwd,
        localmode => 0,
        extra_security => 0,
        @_
    });
   
    my $err = $self->load_config( $pwd.'main.conf' );
    $err->throw if ( $err );
   
    # db_user and db_pass are optional depending on the DBD
    foreach ( qw( login_secret session_secret db_dsn ) ) {
        $self->error( "missing config value: $_" )->throw unless ( defined $self->{$_} );
    }

    require CometDesktop::Common;
   
    $self->get_svn_version() if ( $self->{use_svn_version} );
    
    $self->plugins( {} ) unless ( $self->plugins );
    
    unless ( $self->cgi ) {
        require CGI;
        import CGI;
        $self->cgi( new CGI );
    }
    
    unless ( $self->db ) {
        require CometDesktop::DB;
        $self->error( "db_dsn not defined, set this in your config file\n" )->throw unless ( $self->{db_dsn} );
        $self->db( CometDesktop::DB->new(
            $self->{db_dsn},
            $self->{db_user} || '',
            $self->{db_pass} || '',
        ) );
        if ( $self->db->{error} ) {
            warn $self->db->{error};
            die "db error";
        }
    }
    
    unless ( $self->user ) {
        require CometDesktop::User;
#        import CometDesktop::User;   
        $self->user( CometDesktop::User->new( $self ) );
    }
    
    return $self;
}

sub get_svn_version {
    my $self = shift;

    my $file = $self->pwd.'.svn/entries';
    
    return $self->version( '1' ) unless ( -e $file );

    my @data = split( "\n", slurp( $file ) );
    return $self->version( '1' ) unless ( @data && $data[3] );

    return $self->version( $data[3] );
}

# never use a cookie directly, verify it's good first
sub session_cookie {
    my $self = shift;
    my $sid = $self->cgi->cookie('sessionId');

    require Digest::SHA1;
    
    unless ( defined $sid && $sid =~ m/^[a-f0-9]{40}\/[a-f0-9]{40}$/ ) {
        warn "session id doesn't match sha1/sha1 sid[$sid]" if ( defined $sid );
        return undef;
    }
    
    my $check;
    ( $check, $sid ) = ( split( '/', $sid, 2 ) );

    my $code;
    if ( $self->extra_security ) {
        $code = Digest::SHA1::sha1_hex( $sid.':'.$self->session_secret.':'.( $ENV{HTTP_USER_AGENT} || '' ) );
    } else {
        $code = Digest::SHA1::sha1_hex( $sid.':'.$self->session_secret );
    }

    unless ( $code eq $check ) {
        warn "session $sid doesn't pass token check against $check";
        return undef;
    }

    return $sid;
}

sub css_includes {
    my $self = shift;
    my $ud = $self->user->user_data;
    my @t;
    $self->db->arrayHashQuery(qq|
    SELECT
        T.path_to_file AS path
    FROM
        qo_themes AS T,
        qo_styles AS S
    WHERE
        T.id=S.qo_themes_id AND
        S.qo_members_id=? AND S.qo_groups_id=?
    |,[$ud->{id},$ud->{groups_id}],\@t);
    return '' if ( $self->db->{error} );

    my @files;

    unless ( @t ) {
        @t = $self->db->arrayHashQuery(qq|
            SELECT
                path_to_file as path
            FROM
                qo_themes T
                    INNER JOIN qo_styles AS S ON S.qo_themes_id = T.id
            WHERE
                qo_members_id=0
        |);
        return '' if ( $self->db->{error} );
    }

    foreach my $h ( @t ) {
        push( @files, '<link id="theme" rel="stylesheet" type="text/css" href="'.$h->{path}.'?v='.$self->version.'" />' );
    }

    @t = ();

    # union?
    $self->db->arrayHashQuery(qq|SELECT path, name FROM qo_files WHERE type=? AND active='true' ORDER BY id|,['css'],\@t);
    return '' if ( $self->db->{error} );
    
    $self->db->arrayHashQuery(qq|SELECT path, name FROM qo_dialogs WHERE type=?|,['css'],\@t);
    return '' if ( $self->db->{error} );

    $self->db->arrayHashQuery(qq|
    SELECT
        M.path,
        MF.name
    FROM
        qo_modules_has_files MF
            INNER JOIN qo_modules AS M ON M.id = MF.qo_modules_id AND M.active = 'true'
            INNER JOIN qo_groups_has_modules AS GM ON GM.qo_modules_id = M.id
    WHERE
        type = 'css' AND qo_groups_id=?
    |,[$ud->{groups_id}],\@t);
    
    foreach my $h ( @t ) {
        push( @files, '<link rel="stylesheet" type="text/css" href="'.$h->{path}.$h->{name}.'?v='.$self->version.'" />' );
    }

    return join ( "\n", @files );
}

sub call_plugin {
    my $self = shift;
    my ( $module, $task, $what ) = $self->cgi_params( 'moduleId', 'task', 'what' );
    return unless ( $module && $task && $what );
      
    my $modules = {};
    $self->db->keyvalHashQuery(qq|
    SELECT
        m.moduleId, 1
    FROM
        qo_groups_has_modules AS gm
            INNER JOIN qo_modules AS m
                ON m.id=gm.qo_modules_id AND m.active='true'
    WHERE
        gm.qo_groups_id=?
    |,[ $self->user->group_id ],$modules);
    if ( $self->db->{error} ) {
        warn $self->db->{error};
        return 0;
    }
    # XXX hack
    $modules->{'ajax-db'} = 1;
    
    if ( !exists( $modules->{$module} ) ) {
        if ( $module eq 'remote-load' ) {
            warn "User tried to get the source for an unauthorized module: $module\n";
            print "/* unauthorized */";
            return 1;
        } else {
            return;
        }
    }

    my $data = {};
    $self->db->hashQuery(qq|SELECT path FROM qo_modules WHERE moduleId=? AND active='true'|,[$module],$data);
    return if ( $self->db->{error} );
    # TODO fix this hack
    if ( $module eq 'ajax-db' ) {
        $data->{path} = 'system/core/db/';
    }
    return unless ( $data->{path} );

    if ( $task eq 'remote-load' && $what eq 'src' ) {
        my $path = $self->pwd;
        if ( -e $path.$data->{path}.'plugin.meta' ) {
            my $meta = slurp( $path.$data->{path}.'plugin.meta' );
        
            my $metadata = eval $meta;
            unless ( $@ ) {
                unless ( $metadata->{files} && ref( $metadata->{files} ) eq 'ARRAY' ) {
                    print "/* nothing to load */\n";
                    return 1;
                }
                foreach ( @{$metadata->{files}} ) {
                    next unless ( m/\.js$/ );
                    if ( -e $path.$data->{path}.$_ ) {
                        my $src = slurp( $path.$data->{path}.$_ );
                        if ( $self->user->group_id == 1 ) {
                            print "/* $data->{path}$_ */\n";
                            print $src;
                        } else {
                            print $self->js_compress($src);
                        }
                    } else {
                        print "/* $data->{path}$_ not found */\n";
                    }
                }
            }
        } else {
            print "/* not a remote loaded module */\n";
        }
        return 1;
    }

    $data->{path} .= "/" unless ( $data->{path} =~ m/\/$/ );

    eval {
        require( $data->{path}.'Plugin.pm' );
    };
    if ( $@ ) {
        warn "error in require call for plugin $module : $@";
        return;
    }

    my $plugin = $self->plugins->{$module};
    
    return unless ( $plugin && UNIVERSAL::can( $plugin, 'request' ) );

    my $ret = eval { $plugin->request( $task, $what ); };
    if ( $@ ) {
        warn "error in call to plugin $module :$@";
        return;
    }
    return $ret ;
}

sub register_plugin {
    my ( $self, $plugin, $package ) = @_;

    $package = "CometDesktop::Plugin::$package";
    my $ret = eval { $self->plugins->{$plugin} = $package->new(); };
    if ( $@ ) {
        warn $@;
        return;
    }
    return $ret;
}

sub javascript_hash {
    my $self = shift;

    my @t = $self->db->arrayHashQuery(qq|SELECT * FROM qo_files WHERE type='javascript' AND active='true' ORDER BY id|);
    return '' if ( $self->db->{error} );
    my @u = $self->db->arrayHashQuery(qq|SELECT * FROM qo_dialogs WHERE type='javascript'|);
    return '' if ( $self->db->{error} );

    $self->db->arrayHashQuery(qq|
    SELECT
        M.path,
        MF.name
    FROM
        qo_groups_has_modules GM
            INNER JOIN qo_modules AS M ON M.id = GM.qo_modules_Id AND M.active='true'
            INNER JOIN qo_modules_has_files AS MF ON MF.qo_modules_id = M.id AND MF.type='javascript'
    WHERE
        qo_groups_id=?
    |,[$self->user->group_id],\@u);
    return '' if ( $self->db->{error} );

    my $path = $self->pwd;

    push( @t, @u );
    my @existing;
    foreach my $h ( @t ) {
        $h->{stat} = [ ( stat( $path.$h->{path}.$h->{name} ) )[ 7, 9 ] ];
        if ( -e _ ) {
            push( @{$h->{stat}}, 1 );
            push( @existing, $h );
        }
    }
    my @lm = sort { $b->{stat}->[1] <=> $a->{stat}->[1] } @existing;

    require Digest::SHA1;
    return Digest::SHA1::sha1_hex( join(':', ( $self->user->user_id, map { $_->{stat}->[1], $_->{path}.$_->{name} } @lm ) ) );
}


sub javascript_include {
    my $self = shift;
    
    my @t = $self->db->arrayHashQuery(qq|SELECT * FROM qo_files WHERE type='javascript' AND active='true' ORDER BY id|);
    return '' if ( $self->db->{error} );
    my @u = $self->db->arrayHashQuery(qq|SELECT * FROM qo_dialogs WHERE type='javascript'|);
    return '' if ( $self->db->{error} );

    $self->db->arrayHashQuery(qq|
    SELECT
        M.moduleId,
        M.path,
        MF.name
    FROM
        qo_groups_has_modules GM
            INNER JOIN qo_modules AS M ON M.id = GM.qo_modules_Id AND M.active='true'
            INNER JOIN qo_modules_has_files AS MF ON MF.qo_modules_id = M.id AND MF.type='javascript'
    WHERE
        qo_groups_id=?
    |,[$self->user->group_id],\@u);
    return '' if ( $self->db->{error} );
    
    my $path = $self->pwd;

    push( @t, @u );
    foreach my $h ( @t ) {
        $h->{stat} = [ 0, 0 ];
        my $st = [ ( stat( $path.$h->{path}.$h->{name} ) )[ 7, 9 ] ];
        unless ( -e _ ) {
            warn "include: $path$h->{path}$h->{name} not found\n";
            $h->{stat} = [ 0, 0, 0 ];
            next;
        }
        push( @$st, ( -e _ ) ? 1 : 0 );
        $h->{stat} = $st;
        $h->{meta} = ( -e $path.$h->{path}.'plugin.meta' ) ? 1 : 0;
    }
    my @lm = sort { $b->{stat}->[1] <=> $a->{stat}->[1] } @t;
#    $|++;
    
    my $lastmod = $lm[0]->{stat}->[1];
    require HTTP::Date;
    my $lm = HTTP::Date::time2str($lastmod);
    if ( $ENV{HTTP_IF_MODIFIED_SINCE} ) {
        my $mtime = HTTP::Date::str2time($ENV{HTTP_IF_MODIFIED_SINCE});
        if ( $mtime && $lastmod <= $mtime ) {
            print "Status: 304\n";
            print "Last-Modified: $lm\n";
            print "Content-Length: 0\n\n";
            return;
        }
    }
    
    print "Last-Modified: $lm\n";
    print "Content-Type: text/javascript\n\n";
    my $version = $self->version;
    # decimal ip
    print qq|/* Copyright (c) 2008 - David Davis <xantus\@xantus.org>
 * You DO NOT have permission to copy, redistribute, or relicense this software until it has been released under the GPL.
 *
 *
 * http://xant.us/
 * http://cometdesktop.com/
 * http://code.google.com/p/cometdesktop/
 *
 * Comet Desktop v$version
 * Last Modified: $lm
 * 
 */\n\n|;
    my $module_meta = {};
    foreach my $h ( @t ) {
        if ( $h->{meta} ) {
            if ( !exists( $module_meta->{$h->{moduleId}} ) ) {
                print "/* $h->{moduleId} - remote loaded */\n";
                $module_meta->{$h->{moduleId}} = slurp( $path.$h->{path}.'plugin.meta' );
                
                #my $metadata = eval { $self->decode_json( $module_meta->{$h->{moduleId}}.";" ); };
                my $metadata = eval $module_meta->{$h->{moduleId}};
                if ( $@ ) {
                    print "/* error loading meta file */\n";
                } else {
                    delete $metadata->{files};
                    print "app.register(".$self->encode_json( $metadata ).");\n";
                }
            }
            next;
        }
        if ( $h->{stat}->[2] ) {
            my $src =  slurp( $path.$h->{path}.$h->{name} );
            if ( $self->user->group_id == 1 ) {
                print "/* $h->{path}$h->{name} ($h->{stat}->[0] bytes) */\n";
                print $src;
            } else {
                print $self->js_compress($src);
            }
        } else {
            print "/* $h->{path}$h->{name} not found */\n"
                if ( $self->user->group_id == 1 );
        }
#        if ( $h->{name} eq 'DesktopConfig.js' ) {
#            my $modules = $self->get_modules();
#            my $config = $self->get_config();
#            $contents[-1] =~ s/<<modules>>/$modules/g;
#            $contents[-1] =~ s/<<config>>/$config/g;
#        }
    }

    return;
}

sub get_modules {
    my ( $self, $group_id ) = @_;

    $group_id = $self->user->group_id unless ( defined $group_id );
    
    my @t;
    $self->db->arrayQuery(qq|
    SELECT
        m.moduleName
    FROM
        qo_groups_has_modules AS gm
            INNER JOIN qo_modules AS m
                ON m.id=gm.qo_modules_id AND m.active='true'
    WHERE
        gm.qo_groups_id=?
    |,[ $group_id ],\@t);
    return '' if ( $self->db->{error} );

    # XXX temp
    # move network status to the top
    @t = sort { $b =~ m/Registry/ } @t;

    return \@t;

#    my @contents;
#    foreach ( @t ) {
#        push( @contents, 'new '.$_.'()' );
#    }
#    return join( ",\n", @contents );
}

sub get_config {
    my $self = shift;
    my $launchers = {};
    my $ud = $self->user->user_data;
    my @t;
    $self->db->arrayHashQuery(qq|
    SELECT
        L.name AS launcher,
        M.moduleId as moduleId
    FROM
        qo_modules_has_launchers ML
            INNER JOIN qo_modules AS M
                ON M.id = ML.qo_modules_id AND M.active='true'
            INNER JOIN qo_launchers AS L
                ON L.id = ML.qo_launchers_id
    WHERE
        ML.qo_members_id=? AND ML.qo_groups_id=?
    ORDER BY ML.sort_order asc
|,[0,$ud->{groups_id}],\@t);
    $self->db->arrayHashQuery(qq|
    SELECT
        L.name AS launcher,
        M.moduleId as moduleId
    FROM
        qo_modules_has_launchers ML
            INNER JOIN qo_modules AS M
                ON M.id = ML.qo_modules_id AND M.active='true'
            INNER JOIN qo_launchers AS L
                ON L.id = ML.qo_launchers_id
    WHERE
        ML.qo_members_id=? AND ML.qo_groups_id=?
    ORDER BY ML.sort_order asc
|,[0,0],\@t);
    $self->db->arrayHashQuery(qq|
    SELECT
        L.name AS launcher,
        M.moduleId as moduleId
    FROM
        qo_modules_has_launchers ML
        INNER JOIN qo_modules AS M
            ON M.id = ML.qo_modules_id AND M.active='true'
        INNER JOIN qo_launchers AS L
            ON L.id = ML.qo_launchers_id
    WHERE
        ML.qo_members_id=? AND ML.qo_groups_id=?
    ORDER BY ML.sort_order asc
|,[$ud->{id},$ud->{groups_id}],\@t);
    foreach ( @t ) {
        push( @{$launchers->{$_->{launcher}}}, $_->{moduleId} );
    }
   # make the lists unique
    while ( my ( $k, $v ) = each( %$launchers ) ) {
        my %seen;
        @{$launchers->{$k}} = map { $seen{$_}++ ? () : $_ } @$v;
    }

    my $styles = $self->get_styles( 0, 0 );
    my $group = $self->get_styles( 0, $ud->{groups_id} );
    my $member = $self->get_styles( $ud->{id}, $ud->{groups_id} );
    $self->_merge( $styles, $group );
    $self->_merge( $styles, $member );
    my $user = $self->user;
#    $launchers->{autorun} = ['jabber'] if ( $self->user->is_guest );
#    require Socket;
    return {
        launchers => $launchers,
        styles => $styles,
        modules => $self->get_modules,
        registry => $self->get_registry,
        user => {
            id => $user->user_id,
            email => $user->email_address,
            isAdmin => $user->is_admin,
            isGuest => $user->is_guest,
            group => $user->group_id,
            first => $user->first_name || '',
            last => $user->last_name || '',
            totalDuration => $user->total_duration,
            lastSessionDuration => $user->session_duration,
        },
        ip => $ENV{REMOTE_ADDR},
#        dip => unpack( 'N', inet_aton( $ENV{REMOTE_ADDR} ) ), # decimal ip
        sessionId => $user->session_id,
        localmode => $self->localmode,
        version => $self->version,
#        env => ( $self->user->group_id == 1 ? \%ENV : {} ),
    };
}

sub get_registry {
    my $self = shift;
    my $state = {};

    $self->db->keyvalHashQuery(qq|
    SELECT
        name, val
    FROM 
        qo_registry
    WHERE
        qo_members_id=?
    |,[$self->user->user_id],$state);
    if ( $self->db->{error} ) {
        warn $self->db->{error};
        return 0;
    }

    while( my ( $k, $v ) = each( %$state ) ) {
        $state->{$k} = ( $v =~ m/^(\[|\{)/ ) ? $self->decode_json( $v ) : ( ( $v && $v =~ m/^"(.*)"$/ ) ? $1 : $v );
    }

    return $state;
}

sub get_styles {
    my $self = shift;
    my $h = {};
    $self->db->hashQuery(qq|
    SELECT
        backgroundcolor,
        fontcolor,
        transparency,
        T.id AS themeid,
        T.name AS themename,
        T.path_to_file AS themefile,
        W.id AS wallpaperid,
        W.name AS wallpapername,
        W.path_to_file AS wallpaperfile,
        wallpaperposition
    FROM
        qo_styles S
            INNER JOIN qo_themes AS T ON T.id = S.qo_themes_id
            INNER JOIN qo_wallpapers AS W ON W.id = S.qo_wallpapers_id
    WHERE
        qo_members_id=? AND qo_groups_id=?|,[@_],$h);
    if ( $self->db->{error} ) {
        warn $self->db->{error};
    }
    # TODO util function to do this
    $h->{transparency} = ( defined $h->{transparency} && $h->{transparency} eq 'true' ) ? $self->json_true : $self->json_false;
    return $h;
}

sub update_styles {
    my ( $self, $type, $data ) = @_;
    
    return unless ( $type eq 'member' );

    my $ud = $self->user->user_data;

    my $ex = $self->db->scalarQuery(qq|
    SELECT 1
    FROM
        qo_styles
    WHERE
        qo_members_id=? AND qo_groups_id=?
    |,[ @{$ud}{qw( id groups_id )}]);
    if ( $self->db->{error} ) {
        warn $self->db->{error};
        return 0;
    }
    
    # XXX this is crap, and validate these are ints
    $data->{qo_themes_id} = delete $data->{theme};
    $data->{qo_wallpapers_id} = delete $data->{wallpaper};
    
    return 0 unless ( defined $data->{qo_themes_id} && $data->{qo_themes_id} =~ m/^\d+$/ );
    return 0 unless ( defined $data->{qo_wallpapers_id} && $data->{qo_wallpapers_id} =~ m/^\d+$/ );
    
    if ( $ex ) {
        # update
        $self->db->updateWithWhere('qo_styles','qo_members_id=? AND qo_groups_id=?',[@{$ud}{qw( id groups_id )}],$data);
    } else {
        # insert
        @{$data}{qw( qo_members_id qo_groups_id )} = @{$ud}{qw( id groups_id )};
        $self->db->insertWithHash('qo_styles',$data);
    }

    if ( $self->db->{error} ) {
        warn $self->db->{error};
        return 0;
    }
    return 1;
}

sub update_launchers {
    my ( $self, $type, $data ) = @_;
    
    return unless ( $type eq 'member' );

    my $ud = $self->user->user_data;

    my $launchers = { $self->db->keyvalHashQuery(qq|
    SELECT
        name, id
    FROM 
        qo_launchers
    |) };
    if ( $self->db->{error} ) {
        warn $self->db->{error};
        return 0;
    }

    return unless ( $launchers->{$data->{what}} );

    my $modules = { $self->db->keyvalHashQuery(qq|
    SELECT
        moduleId, id
    FROM 
        qo_modules
    |) };
    #WHERE active='true'
    if ( $self->db->{error} ) {
        warn $self->db->{error};
        return 0;
    }

    $self->db->doQuery(qq|
    DELETE
    FROM
        qo_modules_has_launchers
    WHERE
        qo_members_id=? AND qo_groups_id=? AND qo_launchers_id=?
    |,[ @{$ud}{qw( id groups_id )}, $launchers->{$data->{what}} ]);
    if ( $self->db->{error} ) {
        warn $self->db->{error};
        return 0;
    }
    warn "delete ".join(',',(@{$ud}{qw( id groups_id )}, $launchers->{$data->{what}}));
    
    my $ids = $self->decode_json( $data->{ids} );
    return 0 unless ( ref( $ids ) eq 'ARRAY' );

    return 1 unless ( @$ids );

    # insert
    @{$data}{qw( qo_members_id qo_groups_id )} = @{$ud}{qw( id groups_id )};
    my $insert = {
        qo_members_id => $ud->{id},
        qo_groups_id => $ud->{groups_id},
        qo_launchers_id => $launchers->{$data->{what}},
        sort_order => 0,
    };

    my %seen;
    foreach ( map { $seen{$_}++ ? () : $_ } @$ids ) {
        my $mid = $modules->{$_};
        next unless ( $mid );
        $insert->{qo_modules_id} = $mid;
        $self->db->insertWithHash('qo_modules_has_launchers',$insert);
        last if ( $self->db->{error} );
        $insert->{sort_order}++;
    }
    if ( $self->db->{error} ) {
        warn $self->db->{error};
        return 0;
    }
    return 1;
}

# util

sub cgi_param {
    return shift->cgi->param(@_);
}

sub cgi_params {
    my $self = shift;
    return map { $self->cgi->param($_) } @_;
}

sub json_true {
    require JSON::Any;
    import JSON::Any;
    return eval "JSON::Any::true()";
}

sub json_false {
    require JSON::Any;
    import JSON::Any;
    return eval "JSON::Any::false()";
}

sub decode_json {
    shift;
    require JSON::Any;
    import JSON::Any;
    my $r = eval { JSON::Any->jsonToObj(@_); };
    if ( $@ ) {
        warn 'Error while decoding json from line: '.(caller())[2].' : '.$@;
    }
    return $r;
}

sub encode_json {
    shift;
    require JSON::Any;
    import JSON::Any;
    my $r = eval { JSON::Any->objToJson(@_) };
    if ( $@ ) {
        warn 'Error while encoding json from line: '.(caller())[2].' : '.$@;
    }
    return $r;
}

sub js_compress {
    my ( $self, $js ) = @_;
    require JavaScript::Minifier;
    return JavaScript::Minifier::minify(
        input => $js,
    );
}

# merge hash keys overwriting $x with keys from $y
sub _merge {
    my ( $self, $x, $y ) = @_;
    while( my ( $k, $v ) = each ( %{$y} ) ) {
        $x->{$k} = $v if ( defined $v );
    }
}

sub error {
    return CometDesktop::Exception->new(
        error => shift,
        caller => [caller()],
        @_
    );
}

sub load_config {
    my ( $self, $file ) = @_;

    open (my $fh, $file) or return $self->error( "error opening config file [$file]: $!" );

    my $line = 0;
    while (<$fh>) {
        $line++;
        # we only care about errors here
        my $err = $self->config_command( $_, $line );
        return $err if ( $err && UNIVERSAL::isa( $err, 'CometDesktop::Exception' ) );
    }

    close($fh);
    return;
}

sub config_command {
    my ( $self, $cmd, $line ) = @_;

    foreach ( qr/^\s+/, qr/#.*/, qr/\s+$/ ) {
        $cmd =~ s/$_//;
    }
    $cmd =~ s/\s+/ /g;
    my $orig = $cmd;
    $cmd =~ s/^([^=]+)/lc($1)/e;
    return unless $cmd =~ /^\S/; # blank
    
    # ENV vars
    $cmd =~ s/\$(\w+)/$ENV{$1}/g;

    return $self->error( "syntax error on line $line" ) unless ( $cmd =~ /^(\w+)/ );
    
    $cmd = $1;
    my $h = UNIVERSAL::can( $self, "cmd_$cmd" );
    return $self->error( "command not found $cmd" ) unless ( $h );
    
    return $h->( $self, $orig );
}

# set foo = bar
# set foo.bar = baz
sub cmd_set {
    my ( $self, $cmd ) = @_;
    
    my @set = grep { defined } ( $cmd =~ /^set (?:(\w+)[ \.])?([\w\.]+) ?= ?(.+)$/i );
    $self->{ $set[0] } = $set[1] if ( @set == 2 );
    $self->{ $set[0] }->{ $set[1] } = $set[2] if ( @set == 3 );
    
    return;
}

# include lib
sub cmd_include {
    my ( $self, $cmd ) = @_;
    
    my @set = ( $cmd =~ /^include (.+)$/i );
    unshift( @INC, split( /\s+/, $set[0] ) );
    
    return;
}

sub cmd_load_config {
    my ( $self, $cmd ) = @_;

    my @set = ( $cmd =~ /^load_config (.+)$/i );
    return $self->load_config( $set[0] ) if ( defined $set[0] );
}

sub set_env {
    my ( $self, $cmd ) = @_;

    my @set = grep { defined } ( $cmd =~ /^set_env ([\w\.]+) ?= ?(.+)$/i );
    $ENV{ $set[0] } = $set[1];
    
    return;
}

1;

package CometDesktop::Exception;

use strict;
use warnings;


sub new {
    my $class = shift;
    # XXX save caller
    bless( { error => shift, @_ }, ref $class || $class );
}

*throw = *plain_throw;

sub plain_throw {
    my $self = shift;
    print "Status: 500\n";
    print "Content-Type: text/plain\n\n";
    print "Error: $self->{error}";
}

1;

