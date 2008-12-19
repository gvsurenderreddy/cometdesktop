# Comet Desktop
# Copyright (c) 2008 - David W Davis, All Rights Reserved
# xantus@cometdesktop.com     http://xant.us/
# http://code.google.com/p/cometdesktop/
# http://cometdesktop.com/
#
# License: GPL v3
# http://code.google.com/p/cometdesktop/wiki/License

package CometDesktop::Plugin::HuluPlayer;

use strict;
use warnings;

use CometDesktop qw(
    -HTML::Entities
    -WWW::Mechanize::Cached
    -Cache::FileCache
    -JSON::Any
);


$desktop->register_plugin( 'hulu-player' => 'HuluPlayer' );

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
    # XXX this blows
    my $path = $ENV{SCRIPT_FILENAME};
    $path =~ s/\/\w+\.pl$/\//;
    bless( {
        @_,
        agent => 'CometDesktop/1.0',
        from => 'David Davis <xantus@xantus.org>',
        referrer => 'http://cometdesktop.com/',
        cache_params => {
            cache_root => $path.'perl-lib/tmp',
            namespace => "www-hulu",
            default_expires_in => "1h",
        },
    }, $class || ref( $class ) );
}

sub ua {
    my $self = shift;
    # reduce, reuse, recycle
    return $self->{ua} if ( $self->{ua} );
    my $cache = Cache::FileCache->new( $self->{cache_params} );
    my $mech = WWW::Mechanize::Cached->new( autocheck => 1, cache => $cache );
    $mech->timeout(20);
    # referrer is misspelled in the HTTP spec as referer
    $mech->default_headers( HTTP::Headers->new(
        'Referer' => $self->{referrer}
    ) );
    $mech->agent( $self->{agent} );
    $mech->from( $self->{from} );
    $self->{ua} = $mech;
    return $mech;
}

sub cmd_fetch {
    my ( $self, $what ) = @_;

    return unless ( defined $what && $what =~ m!^/! );
    
    $what =~ s/\.{2,}//g;

    # special case
    if ( $what eq '/starred' ) {
        return shift->fetch_starred( @_ );
    }

    # for example: http://www.hulu.com/feed/popular/episode/today
    my $res = $self->ua->get( 'http://www.hulu.com/feed'.$what );

    unless ( $res->is_success ) {
        print $desktop->encode_json({
            success => 'false',
            error => 'Response from hulu server:'.$res->status_line,
        });
        return 1;
    }

    my $xml = $res->decoded_content;
    return unless ( defined $xml );
    unless ( $xml =~ m/^<(rss|\?xml)/ ) {
        if ( $xml =~ m/down for maintenance/i ) {
            warn "hulu is down for maintenance";
            print $desktop->encode_json({
                success => 'false',
                error => 'Hulu.com is down for maintenance, please try again later',
            });
        } else {
            warn "not xml!: ".substr($xml,0,100);
            print $desktop->encode_json({
                success => 'false',
                error => 'Response from hulu server was not xml/rss',
            });
        }
        return 1;
    }

    my $i = 0;
    my $grp = '';
    my ( @shows, @items );
    foreach ( split( /\n/, $xml ) ) {
        if ( m/<item>/ ) {
            $grp = '';
        } elsif ( m/<\/item>/ ) {
            push(@items,$grp);
            $grp = '';
        } else {
            $grp .= "$_\n";
        }
    }
    
    my ( $private, @ids );
    foreach ( @items ) {
        my $item = $_;
        $i++;
        my $x = {};
        my @tags = qw( title link pubDate guid description media:credit );
        foreach my $t ( @tags ) {
            if ( $item =~ m/<$t[^>]*>(.+)<\/$t>/s ) {
                $x->{$t} = $1;
            }
        }
        if ( $x->{title} && $x->{title} eq 'This feed is private' ) {
            $private = 1;
            last;
        }
        my @srctags = qw( media:thumbnail media:player );
        foreach my $t ( @srctags ) {
            if ( $item =~ m/<$t.*url="([^"]+)".*>/s ) {
                $x->{$t} = $1;
            }
        }
        next unless ( $x->{'media:player'} );

        $x->{description} ||= '';
        $x->{description} =~ s/.*<\!\[CDATA\[(.*)\]\]>/$1/;
        $x->{description} =~ s/href=/target="_blank_" href=/i;
        #$x->{description} = encode_entities($x->{description}, "\200-\377");
        #$x->{description} = encode_entities($x->{description}) if ( $x->{description} =~ m/\>|\</ );
        $x->{description} =~ s/"/&quot;/g;

        # get the show id
        if ( $x->{guid} && $x->{guid} =~ m/watch\/(\d+)\// ) {
            $x->{id} = int( $1 );
        }

        if ( $x->{title} ) {
            # /calendar is for hulu days of summer (movies)
            if ( $what eq '/calendar' ) {
                $x->{show} = '(Movie)';
            } elsif ( $x->{title} =~ s/^(.+): // ) {
                $x->{show} = $1;
            }
            if ( $x->{title} =~ s/ \(s(\d+) \| e(\d+)\)// ) {
                $x->{episode} = int($2); 
                $x->{season} = int($1);
            }
        }

        push( @ids, $x->{id} ) if ( $x->{id} );

        push( @shows, {
            n => $i,
            id => $x->{id} || '',
            starred => JSON::Any::false,
            show => $x->{show} || '',
            title => $x->{title},
            episode => $x->{episode} || '',
            season => $x->{season} || '',
            type => ( $x->{episode} ? 'Episode' : 'Video' ),
            guid => $x->{guid},
            link => $x->{link},
            description => $x->{description},
            pubDate => $x->{pubDate},
            mediaThumbnail => $x->{'media:thumbnail'},
            mediaCredit => $x->{'media:credit'},
            mediaPlayer => $x->{'media:player'},
        });
    }

    if ( $private ) {
        warn "not xml!: $xml";
        # TODO get petdance to add an expire method
        print $desktop->encode_json({
            success => 'false',
            error => 'This feed is private.  Change the privacy and wait 1h before retrying',
        });
        return 1;
    }

    if ( @ids ) {
        my $starred = {};
        $desktop->db->keyvalHashQuery(qq|
        SELECT
            id, 1
        FROM 
            qo_hulu_starred
        WHERE qo_members_id=? AND id IN (|.join(',',( map { '?' } @ids ) ).')',
        [$desktop->user->user_id,@ids],$starred);
        if ( $desktop->db->{error} ) {
            warn $desktop->db->{error};
        }
    
        if ( keys %$starred ) {
            foreach ( @shows ) {
                next unless ( $_->{id} && $starred->{ $_->{id} } );
                $_->{starred} = JSON::Any::true;
            }
        }
    }

    print $desktop->encode_json({
        success => 'true',
        shows => \@shows,
    });
    return 1;
}

sub fetch_starred {
    my ( $self, $what ) = @_;

    my $starred = {};
    $desktop->db->keyvalHashQuery(qq|
    SELECT
        id, record
    FROM 
        qo_hulu_starred
    WHERE qo_members_id=?
    |,[$desktop->user->user_id],$starred);
    if ( $desktop->db->{error} ) {
        warn $desktop->db->{error};
        print $desktop->encode_json({
            success => 'false',
            error => 'DB Error, please try again later',
        });
        return 1;
    }

    my @shows;
    foreach ( values %$starred ) {
        push( @shows, $desktop->decode_json( $_ ) );
        $shows[-1]->{starred} = JSON::Any::true;
    }

    print $desktop->encode_json({
        success => 'true',
        shows => \@shows,
    });
    return 1;
}

sub cmd_star {
    my ( $self, $what ) = @_;
    
    return unless ( $what && $what =~ m/^\d+$/ );
    my $record = $desktop->cgi_param('record');
    return unless ( $record && $record =~ m/^{/ );

    $desktop->db->insertWithHash('qo_hulu_starred',{
        qo_members_id => $desktop->user->user_id,
        id => $what,
        record => $record,
    });
    if ( $desktop->db->{error} ) {
        warn $desktop->db->{error};
        print $desktop->encode_json({
            success => 'false',
        });
        return 1;
    }

    print $desktop->encode_json({
        success => 'true',
    });
    return 1;
}

sub cmd_unstar {
    my ( $self, $what ) = @_;

    return unless ( $what && $what =~ m/^\d+$/ );

    $desktop->db->doQuery(qq|
        DELETE FROM qo_hulu_starred WHERE qo_members_id=? AND id=?
    |,[$desktop->user->user_id,$what]);
    if ( $desktop->db->{error} ) {
        warn $desktop->db->{error};
        print $desktop->encode_json({
            success => 'false',
        });
        return 1;
    }

    print $desktop->encode_json({
        success => 'true',
    });
    return 1;
}
1;
