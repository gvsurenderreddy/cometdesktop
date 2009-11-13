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

use CometDesktop::Exception;

use Class::Accessor::Fast;
use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors(qw(
    cgi
    db_dsn
    db_user
    db_pass
    plugins
    login_secret
    session_secret
    pwd
    version
    revision
    localmode
    extra_security
    main_conf
    ga_account
    secure_login
    content_type
    sent_header
    tempdir
));

our $singleton;
our $VERSION = '0.9.2';

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
    __PACKAGE__->new( imported_pkg => $package ) unless ( defined( $singleton ) );

    unshift( @modules, 'Common', '-Time::HiRes[time]' );

    @modules = map { s/^-// ? $_ : __PACKAGE__.'::'.$_  } @modules;

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

    @failed and die 'could not import (' . join( ' ', @failed ) . ')';
}


sub new {
    my $class = shift;
    die "$class requires an even number of parameters" if @_ % 2;
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
        main_conf => 'main.conf',
        ga_account => undef,
        version => $VERSION,
        revision => '',
        secure_login => 0,
        header => [],
        content_type => undef,
        tempdir => 'tmp/',
        use_exceptions => 1,
        config_files => {},
        @_
    });
   
    my $err = $self->load_config( $self->main_conf );
    $err->throw if ( $err );
   
    # db_user and db_pass are optional depending on the DBD
    foreach ( qw( login_secret session_secret db_dsn ) ) {
        $self->error( "missing config value: $_" )->throw unless ( defined $self->{$_} );
    }

    require CometDesktop::Common;
    import CometDesktop::Common;

    my $tmp = $self->tempdir;
    $tmp .= '/' unless ( $tmp =~ m/\/$/ );
    $tmp = $self->pwd.$tmp if ( $tmp !~ m/^\// );
    $self->tempdir( $tmp );
   
    $self->get_svn_revision if ( $self->{use_svn_revision} );

    $self->version( $VERSION.$self->revision );
    
    $self->plugins( {} ) unless ( $self->plugins );
    
    unless ( $self->cgi ) {
        require CGI;
        $self->cgi( new CGI );
    }
    
    return $self;
}

# simple http handler
sub out {
    my ( $self, @out ) = @_;
    unless ( $self->sent_header ) {
        print $self->header;
        my $type = $self->content_type;
        print "Content-Type: $type; charset=utf-8\n" if ( defined $type );
        print "\n\n";
        $self->sent_header( 1 );
    }
    if ( @out ) {
        my $out = '';
        foreach ( @out ) {
            if ( ref $_ ) {
                $out .= $self->encode_json( $_ )."\n";
            } else {
                $out .= "$_\n";
            }
        }
        utf8::encode( $out );
        print $out;
    }

    return;
}

sub header {
    my $self = shift;
    push( @{$self->{header}}, @_ ) if ( @_ );

    return join( "\n", @{$self->{header}} ).( @{$self->{header}} ? "\n" : '' );
}

sub user {
    my $self = shift;
    unless ( $self->{user} ) {
        require CometDesktop::User;
        $self->{user} = CometDesktop::User->new( $self );
    }
    return $self->{user};    
}

sub db {
    my $self = shift;
    unless ( $self->{db} ) {
        require CometDesktop::DB;
        $self->error( "db_dsn not defined, set this in your config file" )->throw unless ( $self->{db_dsn} );
        $self->{db} = CometDesktop::DB->new(
            $self->{db_dsn},
            $self->{db_user} || '',
            $self->{db_pass} || '',
        );
    }
    return $self->{db};
}

sub get_svn_revision {
    my $self = shift;

    my $file = $self->pwd.'.svn/entries';
    
    return unless ( -e $file );

    my @data = split( "\n", slurp( $file ) );
    return unless ( @data && $data[3] );

    return $self->revision( 'r'.$data[3] );
}

# never use a cookie directly, verify it's good first
sub session_cookie {
    my $self = shift;
    my $sid = $self->cgi->cookie('sessionId');

    require Digest::SHA1;
    
    unless ( defined $sid && $sid =~ m/^[a-f0-9]{40}\/[a-f0-9]{40}$/ ) {
        # TODO send a cookie reset header
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
        # TODO send a cookie reset header
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
    }

    foreach my $h ( @t ) {
        push( @files, '<link id="theme" rel="stylesheet" type="text/css" href="'.$h->{path}.'?v='.$self->version.'" />' );
    }

    # reusing @t
    # TODO union
    @t = $self->db->arrayHashQuery(qq|SELECT path, name FROM qo_files WHERE type='css' AND active='true' ORDER BY id|);
    
    push( @t, $self->db->arrayHashQuery(qq|SELECT path, name FROM qo_dialogs WHERE type='css'|) );

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
        M.moduleId, 1
    FROM
        qo_groups_has_modules AS GM
            INNER JOIN qo_modules AS M
                ON M.id=GM.qo_modules_id AND M.active='true'
    WHERE
        GM.qo_groups_id=?
    |,[$self->user->group_id],$modules);
    # XXX hack
    $modules->{'ajax-db'} = 1;
    
    if ( !exists( $modules->{$module} ) ) {
        if ( $module eq 'on-demand' ) {
            # TODO send a cookie reset header?
            warn "User tried to get the source for an unauthorized module: $module\n";

            $self->out( "/* unauthorized */" );
            return 1;
        } else {
            return;
        }
    }

    my $data = {};
    $self->db->hashQuery(qq|SELECT path FROM qo_modules WHERE moduleId=? AND active='true'|,[$module],$data);
    # TODO fix this hack
    if ( $module eq 'ajax-db' ) {
        $data->{path} = 'system/core/db/';
    }
    return unless ( $data->{path} );

    if ( $task eq 'on-demand' && $what eq 'src' ) {
        my $path = $self->pwd;
        if ( -e $path.$data->{path}.'plugin.meta' ) {
            my $meta = slurp( $path.$data->{path}.'plugin.meta' );
        
            my $metadata = eval $meta;
            if ( $@ ) {
               $self->out( "/* error loading meta file */\n" );
               return 1;
            } else {
                if ( $metadata->{onDemand} ) {
                    unless ( $metadata->{files} && ref( $metadata->{files} ) eq 'ARRAY' ) {
                        $self->out( "/* nothing to load */\n" );
                        return 1;
                    }
                    foreach ( @{$metadata->{files}} ) {
                        next unless ( m/\.js$/ );
                        if ( -e $path.$data->{path}.$_ ) {
                            my $src = slurp( $path.$data->{path}.$_ );
                            if ( $self->user->is_admin ) {
                                $self->out( "/* $data->{path}$_ */", $src );
                            } else {
                                $self->out( $self->js_compress($src) );
                            }
                        } else {
                            $self->out( "/* $data->{path}$_ not found */\n" );
                            $self->out( "log('javascript: file not found: $data->{path}$_');\n" ) if ( $self->user->is_admin );
                        }
                    }
                } else {
                    $self->out(
                        "/* onDemand disabled */",
                        "app.publish( '/desktop/notify', { html: 'onDemand disabled for this module', title:'Error' } );\n"
                    );
                }
            }
        } else {
            $self->out(
                "/* not an onDemand module */",
                "app.publish( '/desktop/notify', { html: 'Not an onDemand module', title:'Error' } );\n"
            );
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
    return $ret;
}

sub register_plugin {
    my ( $self, $plugin, $package ) = @_;

    $package = 'CometDesktop::Plugin::'.$package;
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
    push( @t, $self->db->arrayHashQuery(qq|SELECT * FROM qo_dialogs WHERE type='javascript'|) );

    $self->db->arrayHashQuery(qq|
    SELECT
        M.path,
        MF.name
    FROM
        qo_groups_has_modules GM
            INNER JOIN qo_modules AS M ON M.id = GM.qo_modules_Id AND M.active='true'
            INNER JOIN qo_modules_has_files AS MF ON MF.qo_modules_id = M.id AND MF.type='javascript'
    WHERE
        GM.qo_groups_id=?
    |,[$self->user->group_id],\@t);

    my $path = $self->pwd;

    my @existing;
    foreach my $h ( @t ) {
        $h->{stat} = [ ( stat( $path.$h->{path}.$h->{name} ) )[ 7, 9 ] ];
        next unless ( -e _ );

        # TODO, move the onDemand flag to the database
        if ( -e $path.$h->{path}.'plugin.meta' ) {
            # check if the plugin has enabled onDemand
            my $meta = slurp( $path.$h->{path}.'plugin.meta' );
    
            my $metadata = eval $meta;
            if ( $@ ) {
                warn "error loading meta file $path$h->{path}plugin.meta";
                next;
            } else {
                next if ( $metadata->{onDemand} );
                # ok, meta exists, but onDemand is off, so add it to the list
            }
        }

        push( @{$h->{stat}}, 1 );
        push( @existing, $h );
    }
    my @lm = sort { $b->{stat}->[1] <=> $a->{stat}->[1] } @existing;

    require Digest::SHA1;
    return Digest::SHA1::sha1_hex( join(':', ( $self->user->user_id, map { $_->{stat}->[1], $_->{path}.$_->{name} } @lm ) ) );
}


sub javascript_include {
    my $self = shift;
    
    my @t = $self->db->arrayHashQuery(qq|SELECT * FROM qo_files WHERE type='javascript' AND active='true' ORDER BY id|);
    push( @t, $self->db->arrayHashQuery(qq|SELECT * FROM qo_dialogs WHERE type='javascript'|) );

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
    |,[$self->user->group_id],\@t);
    
    my $path = $self->pwd;

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

# XXX bench this, and determine if non buffered has any benefits
# use trickle for example
#    $|++;
    
    my $lastmod = $lm[0]->{stat}->[1];
    require HTTP::Date;
    my $lm = HTTP::Date::time2str($lastmod);
    if ( $ENV{HTTP_IF_MODIFIED_SINCE} ) {
        my $mtime = HTTP::Date::str2time($ENV{HTTP_IF_MODIFIED_SINCE});
        if ( $mtime && $lastmod <= $mtime ) {
            $self->header(
                "Status: 304",
                "Last-Modified: $lm",
                "Content-Length: 0"
            );
            $self->out();
            return;
        }
    }
    
    $self->header( "Last-Modified: $lm" );
    $self->content_type ( 'text/javascript' );
    my $version = $self->version;
    $self->out( qq|/*
 * Comet Desktop
 * Copyright (c) 2008 - David W Davis, All Rights Reserved
 * xantus\@cometdesktop.com     http://xant.us/
 * http://code.google.com/p/cometdesktop/
 * http://cometdesktop.com/
 *
 * License: GPL v3
 * http://code.google.com/p/cometdesktop/wiki/License
 *
 * Comet Desktop is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License
 *
 * Comet Desktop is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Comet Desktop.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Comet Desktop is a fork of qWikiOffice Desktop v0.7.1
 *
 * -----
 *
 * qWikiOffice Desktop v0.7.1
 * Copyright(c) 2007-2008, Integrated Technologies, Inc.
 * licensing\@qwikioffice.com
 * http://www.qwikioffice.com/license.php
 *
 * -----
 *
 * Ext JS Library
 * Copyright(c) 2006-2008, Ext JS, LLC.
 * licensing\@extjs.com
 *
 * http://extjs.com/license
 *
 * -----
 * Comet Desktop v$version
 * Last Modified: $lm
 * 
 */\n\n| );
    my $module_meta = {};
    foreach my $h ( @t ) {
        if ( $h->{meta} ) {
            if ( exists( $module_meta->{$h->{moduleId}} ) ) {
                next if ( ref( $module_meta->{$h->{moduleId}} ) && $module_meta->{$h->{moduleId}}->{onDemand} );
            } else {
                $module_meta->{$h->{moduleId}} = slurp( $path.$h->{path}.'plugin.meta' );
                
                my $metadata = eval $module_meta->{$h->{moduleId}};
                if ( $@ ) {
                    $self->out( "/* error loading meta file for $h->{moduleId}, loading inline */\n" );
                } else {
                    $module_meta->{$h->{moduleId}} = $metadata;
                    if ( $metadata->{onDemand} ) {
                        delete $metadata->{files};
                        $self->out(
                            "/* $h->{moduleId} - onDemand */",
                            "app.register(".$self->encode_json( $metadata ).");\n"
                        );
                        next;
                    } else {
                        # meta file exists, but onDemand is disabled
                        $self->out( "/* onDemand disabled for $h->{moduleId}, loading inline */\n" );
                    }
                }
            }
        }
        if ( $h->{stat}->[2] ) {
            my $src = slurp( $path.$h->{path}.$h->{name} );
            if ( $self->user->is_admin ) {
                $self->out( "/* $h->{path}$h->{name} ($h->{stat}->[0] bytes) */", $src );
            } else {
                $self->out( $self->js_compress($src) );
            }
        } else {
            $self->out(
                "/* $h->{path}$h->{name} not found */",
                "log('javascript: file not found: $h->{path}$h->{name}');\n"
            ) if ( $self->user->is_admin );
        }
    }

    return;
}

sub get_modules {
    my ( $self, $group_id ) = @_;
    
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
    |,[ $group_id || $self->user->group_id ],\@t);

    # XXX hack
    # move registry to the top
    @t = sort { $b =~ m/Registry/ } @t;

    return \@t;
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
    _merge( $styles, $group );
    _merge( $styles, $member );
    my $user = $self->user;
#    require Socket;
    return {
        config => {
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
            localmode => $self->localmode,
#            dip => unpack( 'N', inet_aton( $ENV{REMOTE_ADDR} ) ), # decimal ip
#            env => ( $self->user->is_admin ? \%ENV : {} ),
        },
        version => $self->version,
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

    return unless ( $launchers->{$data->{what}} );

    my $modules = { $self->db->keyvalHashQuery(qq|
    SELECT
        moduleId, id
    FROM 
        qo_modules
    |) };
    #WHERE active='true'

    $self->db->doQuery(qq|
    DELETE
    FROM
        qo_modules_has_launchers
    WHERE
        qo_members_id=? AND qo_groups_id=? AND qo_launchers_id=?
    |,[ @{$ud}{qw( id groups_id )}, $launchers->{$data->{what}} ]);
    #warn "delete ".join(',',(@{$ud}{qw( id groups_id )}, $launchers->{$data->{what}}));
    
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
        $insert->{sort_order}++;
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
    my $self = shift;
    require JSON::Any;
    import JSON::Any;
    my $r = eval { JSON::Any->jsonToObj(@_); };
    $self->error( 'Error while decoding json: '.$@ )->throw if ( $@ );
    return $r;
}

sub encode_json {
    my $self = shift;
    require JSON::Any;
    import JSON::Any;
    my $r = eval { JSON::Any->objToJson(@_) };
    $self->error( 'Error while encoding json: '.$@ )->throw if ( $@ );
    # convert true/false
    $r =~ s/:\s?"(true|false)"/:$1/g;
    return $r;
}

sub js_compress {
    my ( $self, $js ) = @_;
#    $js =~ s!/\*.*\*/!!xsmg;
    require JavaScript::Minifier;
    return JavaScript::Minifier::minify(
        input => $js,
    );
}

# merge hash keys overwriting $x with keys from $y
# not an object method
sub _merge {
    my ( $x, $y ) = @_;
    while( my ( $k, $v ) = each ( %{$y} ) ) {
        $x->{$k} = $v if ( defined $v );
    }
}

sub error {
    my $self = shift;
    return CometDesktop::Exception->new(
        error => shift,
        throw_die => !$self->{use_exceptions},
        @_
    );
}

sub load_config {
    my ( $self, $loadfile, $o ) = @_;
    unless ( defined $o ) {
        # pinpoints a line in code if called from within a library
        $o = {}; @{$o}{qw( file line cmd )} = ( (caller(1))[1,2], 'load_config' );
    }

    # recursive config file load detection
    if ( my $src = $self->{config_files}->{$loadfile} ) {
        my $error = "You have a looping load_config in $o->{file}, line:$o->{line}"
            ." ($loadfile was loaded previously in $src->{file} line:$src->{line})";
        return $self->error( $error, dump_var => $self->{config_files} );
    }

    # take the file we are loading, and save where it was loaded from
    $self->{config_files}->{$loadfile} = { map { $_ => "$o->{$_}" } keys %$o };

    open (my $fh, $loadfile) or return $self->error( "error opening config file [$loadfile]: $!" );

    my $lines = 0;
    while (my $confline = <$fh>) {
        $lines++;
        # we only care about errors here
        # config txt, line it is on, file, line file was loaded on, previous file, previous line
#        $o->{line} = $lines;
#        $o->{cmd} = $confline;
#        $o->{file} = $loadfile;
        my $err = $self->config_command( $confline, $loadfile, $lines, $o );
        return $err if ( $err && UNIVERSAL::isa( $err, 'CometDesktop::Exception' ) );
    }
    $self->{config_files}->{$loadfile}->{lines} = $lines;

    close($fh);
    return;
}

sub config_command {
    my ( $self, $cmd, $file, $line, $o ) = @_;
    # config txt, line it is on, file, line file was loaded on, previous file, previous line

    # skip empty lines and comments
    foreach ( qr/^\s+/, qr/#.*/, qr/\s+$/ ) {
        $cmd =~ s/$_//;
    }
    $cmd =~ s/\s+/ /g;
    my $orig = $cmd;
    $cmd =~ s/^([^=]+)/lc($1)/e;
    return unless $cmd =~ /^\S/; # blank
    
    # use ENV vars
    $cmd =~ s/\$(\w+)/$ENV{$1}/g;

    return $self->error( "syntax error (file:$file, line:$line)" ) unless ( $cmd =~ /^(\w+)/ );
    
    $cmd = $1;
    my $h = UNIVERSAL::can( $self, "cmd_$cmd" );
    return $self->error( "command not found $cmd (file:$file, line:$line)" ) unless ( $h );
    
    $o->{cmd} = $orig;
    $o->{file} = $file;
    $o->{line} = $line;
    return $h->( $self, $o );
}

# set foo = bar
# set foo.bar = baz
sub cmd_set {
    my ( $self, $o ) = @_;
    
    my @set = grep { defined } ( $o->{cmd} =~ /^set (?:(\w+)[ \.])?([\w\.]+) ?= ?(.+)$/i );
    $self->{ $set[0] } = $set[1] if ( @set == 2 );
    $self->{ $set[0] }->{ $set[1] } = $set[2] if ( @set == 3 );
    
    return;
}

# include lib
sub cmd_include {
    my ( $self, $o ) = @_;
    
    my @set = ( $o->{cmd} =~ /^include (.+)$/i );
    unshift( @INC, split( /\s+/, $set[0] ) );
    
    return;
}

sub cmd_load_config {
    my ( $self, $o ) = @_;
    # config txt, line it is on, file, line file was loaded on, previous file, previous line

    my @set = ( $o->{cmd} =~ /^load_config (if exists )?(.+)$/i );
    return $self->load_config( $set[0], $o ) if ( $#set == 0 );
    return $self->load_config( $set[1], $o ) if ( $#set == 1 && -e $set[1] );
    
    return $self->error( "bad load_config command (file:$o->{file}, line:$o->{line}" );
}

sub set_env {
    my ( $self, $o ) = @_;

    my @set = grep { defined } ( $o->{cmd} =~ /^set_env ([\w\.]+) ?= ?(.+)$/i );
    $ENV{ $set[0] } = $set[1];
    
    return;
}

1;

