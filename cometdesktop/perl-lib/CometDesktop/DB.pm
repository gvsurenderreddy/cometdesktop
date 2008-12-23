# Comet Desktop
# Copyright (c) 2008 - David W Davis, All Rights Reserved
# xantus@cometdesktop.com     http://xant.us/
# http://code.google.com/p/cometdesktop/
# http://cometdesktop.com/
#
# License: GPL v3
# http://code.google.com/p/cometdesktop/wiki/License

# This code is from from sdnwsg, which I am a coauthor (teknikill)
# sdnwsg's license: GPL
package CometDesktop::DB;

use strict;
use Time::HiRes qw(time);
use DBI;
use CometDesktop::Exception;

sub new {
    my $class = shift;
    my $self = bless( {
        last_query => '(no query available)',
    }, $class || ref( $class ) );
    
    $self->{dbh} = $self->get_dbh( @_ );

    return $self;
}

sub error {
    my $self = shift;
	my $dbh = defined $self->{use_dbh} ? $self->{use_dbh} : "dbh";
    my $error = defined $_[0] ? shift : $self->{$dbh}->errstr;

    return CometDesktop::Exception->new(
        error => $error,
        @_
    );
}

sub debug_start {
	my $p = shift;

	(my $q = shift) =~ s/\n\s*/\n/g; # remove leading whitespace on query
	my $t = time - $p->{dbdbst}; # how much time has elapsed since the session started
	my $c = shift; # caller of the query
	print { $p->{dbdbf} } "---($t)$c\n$q"; 

	return time; # return the time we started the query debug
}

sub debug_end {
	my $p = shift;
	my $sq = shift; # the time the query started
	my $cache_used = (shift) ? '*' : '';

	my $t = time-$sq; # how much time elapsed in the query
	print { $p->{dbdbf} } "\n---[$t]$cache_used\n"; 
}

sub quote_in {
	my $p = shift;
    my $query = $p->{last_query} = shift;

	my $g = sub { $p->{dbh}->quote($p->{in}{$_[0]}) };
	$query =~ s/\@\{(\w+)\}/$g->($1)/eg;

	return $query;
}

=item get_dbh($dbistring,$user,$pass)

C<$dbh>

Get a connection to a database and returns a DBI object.
If an error occurs then an exception is thrown

=cut

sub get_dbh {
	my $p = shift;
	my $dbistring = shift;
	my $username = shift;
	my $passwd = shift;
	
	# connect to a database
	my $dbh;

	eval {
        $dbh = DBI->connect("dbi:$dbistring",$username,$passwd, { RaiseError => 0 } )
    };
	if ( $@ || !$dbh ) {
		my $error = $@ || $DBI::err;
		# capture some common errors
		if ($error =~ m/ failed: (.*) at/) {
			$error = "Database Error: $@";
		}
        $p->error( $error )->throw;
	}

	# turn RaiseError off so any query errors we get don't trip up and throw an error
	$dbh->{RaiseError} = 0;

	return $dbh;
}

=item keyvalHashQuery($query,[\%hashref])

C<1 or %hash || 0>

Runs the query and build a hash using the first column as the key and the
second column as and value.

If a hashref is passed to the function it will add to that hashref, otherwise
it will return a hash.

Example:

	$p->keyvalHashQuery("select id, name from lookup_table",\%hash);
	my %hash = $p->keyvalHashQuery("select id, name from lookup_table");

=cut

sub keyvalHashQuery {
	my $p = shift;
	my $query = quote_in($p,shift);
	my $bind = [];
	$bind = shift if (ref($_[0]) eq 'ARRAY');
	my $hash_ref = shift;

	my (@row,$sth);
	my $dbh = (defined($p->{use_dbh})) ? $p->{use_dbh} : "dbh";
	
	my $st = debug_start($p,$query,(join ' ', caller)) if (defined($p->{dbdbf}));

	my %data;

	$p->error->throw unless($sth = $p->{$dbh}->prepare($query));
	$p->error->throw unless($sth->execute(@$bind));

	$p->{queries}++;
	
	debug_end($p,$st) if (defined($p->{dbdbf}));

	while ( @row = $sth->fetchrow_array() ) {
		if (defined($hash_ref)) {
			$$hash_ref{$row[0]} = $row[1];
		} else {
			$data{$row[0]} = $row[1];
		}
	}

	if (defined($hash_ref)) {
		return 1;
	} else {
		return %data;
	}
}

=item arrayHashQuery($query,[\@arrayref])

C<1 or @array || 0>

Runs the query and creates a array of hashes data structure from the
results.  Uses the column names as the hash keys.

If a reference to an array is passed in, it fills that, otherwise it
returns an array.

Example:

	my @tmp = $p->arrayHashQuery("select id, name from lookup_table order by name");

	@tmp = (
		{ id => 5, name => "a" },
		{ id => 2, name => "b" },
		{ id => 9, name => "c" },
		);

=cut

sub arrayHashQuery {
	my $p = shift;
	my $query = quote_in($p,shift);
	my $bind = [];
	$bind = shift if (ref($_[0]) eq 'ARRAY' && ref($_[1]) eq 'ARRAY');
	my $array_ref = shift;

	my ($i,%col,$c,$sth);
	my $dbh = (defined($p->{use_dbh})) ? $p->{use_dbh} : "dbh";

	my $st = debug_start($p,$query,(join ' ', caller)) if (defined($p->{dbdbf}));

	my @data;

	$p->error->throw unless($sth = $p->{$dbh}->prepare($query));
	$p->error->throw unless($sth->execute(@$bind));

	$p->{queries}++;

	debug_end($p,$st) if (defined($p->{dbdbf}));

	while ( my $hash = $sth->fetchrow_hashref() ) {
		if (defined($array_ref)) {
			push @{$array_ref}, { %{$hash} };
		} else {
			push @data, { %{$hash} };
		}
	}

	if (defined($array_ref)) {
		return 1;
	} else {
		return @data;
	}
}

=item sthQuery($query)

C<$sth || 0>

Returns a statement handle which can then be used to fetchrow_array or fetchrow_hashref.

Don't forget to $sth->finish!

=cut

sub sthQuery {
	my $p = shift;
	my $query = quote_in($p,shift);
	my $bind = [];
	$bind = shift if (ref($_[0]) eq 'ARRAY');

	my $sth;
	my $dbh = (defined($p->{use_dbh})) ? $p->{use_dbh} : "dbh";

	my $st = debug_start($p,$query,(join ' ', caller)) if (defined($p->{dbdbf}));

	$p->error->throw unless($sth = $p->{$dbh}->prepare($query));
	$p->error->throw unless($sth->execute(@$bind));

	$p->{queries}++;

	debug_end($p,$st) if (defined($p->{dbdbf}));

	return $sth;
}

=item hashHashQuery($query,$primarykey,[\%hashref])

C<1 or %hash || 0>

Runs a given query and builds a hash of hashes data structure.  If a hash reference
is provided, it fills that, otherwise it returns a hash.

$primarykey tells which column of the returning results is used as the main key.

Example:

	my %tmp = $p->hashHashQuery("select id, name from lookup_table","id");

	%tmp = (
		2 => { id => 2, name => "b" },
		5 => { id => 5, name => "a" },
		9 => { id => 9, name => "c" },
		);

=cut

sub hashHashQuery {
	my $p = shift;
	my $query = quote_in($p,shift);
	my $primekey = shift;
	my $bind = [];
	$bind = shift if (ref($_[0]) eq 'ARRAY');
	my $hash_ref = shift;

	my (@row,$i,%col,@cols,$c,$sth);
	my $dbh = (defined($p->{use_dbh})) ? $p->{use_dbh} : "dbh";

	my $st = debug_start($p,$query,(join ' ', caller)) if (defined($p->{dbdbf}));

	my %data;

	$p->error->throw unless($sth = $p->{$dbh}->prepare($query));
	$p->error->throw unless($sth->execute(@$bind));

	$p->{queries}++;

	debug_end($p,$st) if (defined($p->{dbdbf}));

	# Find the column names
	for $i ( 0 .. $sth->{NUM_OF_FIELDS}-1 ) {
		my $cn = $sth->{NAME}->[$i];
		$col{$cn} = $i;
		push @cols, $cn;
	}

	while ( @row = $sth->fetchrow_array() ) {
		foreach $c (@cols) {
			if (defined($hash_ref)) {
				$$hash_ref{$row[$col{$primekey}]}{$c} = $row[$col{$c}];
			} else {
				$data{$row[$col{$primekey}]}{$c} = $row[$col{$c}];
			}
		}
	}

	if (defined($hash_ref)) {
		return 1;
	} else {
		return %data;
	}
}

=item hashQuery($query,[\%hashref])

C<1 or %hash || 0>

Runs the query and then either fills in a hashref provided or returns a hash.

Uses the column names as hash keys.

Make sure the query returns only 1 row or know which row will return first because
it only get information from the first row returned.

=cut

sub hashQuery {
	my $p = shift;
	my $query = quote_in($p,shift);
	my $bind = [];
	$bind = shift if (ref($_[0]) eq 'ARRAY');
	my $hash_ref = shift;

	my ($sth,$i);
	my $dbh = (defined($p->{use_dbh})) ? $p->{use_dbh} : "dbh";

	my $st = debug_start($p,$query,(join ' ', caller)) if (defined($p->{dbdbf}));

	my %data;

	$p->error->throw unless($sth = $p->{$dbh}->prepare($query));
	$p->error->throw unless($sth->execute(@$bind));

	$p->{queries}++;

	debug_end($p,$st) if (defined($p->{dbdbf}));

	my @row = $sth->fetchrow_array();

	if (scalar(@row)) {
		# Find the column names
		for $i ( 0 .. $sth->{NUM_OF_FIELDS}-1 ) {
			my $cn = $sth->{NAME}->[$i];
			if (defined($hash_ref)) {
				$$hash_ref{$cn} = $row[$i];
			} else {
				$data{$cn} = $row[$i];
			}
		}
	}

	if (defined($hash_ref)) {
		return 1;
	} else {
		return %data;
	}
}

=item arrayQuery($query,[\@arrayref])

C<1 or @array || 0>

Runs query, takes the first column of the results and pushes into provided
arrayref or returns array.

Make sure query only returns one column or that the information you want
returned in the array is in the first column.

=cut

sub arrayQuery {
	my $p = shift;
	my $query = quote_in($p,shift);
	my $bind = [];
	$bind = shift if (ref($_[0]) eq 'ARRAY' && ref($_[1]) eq 'ARRAY');
	my $array_ref = shift;

	my ($sth);
	my $dbh = (defined($p->{use_dbh})) ? $p->{use_dbh} : "dbh";

	my $st = debug_start($p,$query,(join ' ', caller)) if (defined($p->{dbdbf}));

	$p->error->throw unless($sth = $p->{$dbh}->prepare($query));
	$p->error->throw unless($sth->execute(@$bind));

	$p->{queries}++;

	debug_end($p,$st) if (defined($p->{dbdbf}));

	my @tmp;
	while ( my @row = $sth->fetchrow_array() ) {
		if (defined($array_ref)) {
			push @{$array_ref}, @row;
		} else {
			push @tmp, @row;
		}
	}

	if (defined($array_ref)) {
		return 1;
	} else {
		return @tmp;
	}
}

=item scalarQuery($query,[\$scalarref])

C<1 or $scalar>

Runs the query and takes the first row, first column results and returns then in the
provided scalar reference or just returnes the value.

Make sure the query returns only 1 row and 1 column or the results you want back are
in the first row and first column.

=cut

sub scalarQuery {
	my $p = shift;
	my $query = quote_in($p,shift);
	my $bind = [];
	$bind = shift if (ref($_[0]) eq 'ARRAY');
	my $scalar_ref = shift;

	my ($sth);
	my $dbh = (defined($p->{use_dbh})) ? $p->{use_dbh} : "dbh";

	my $st = debug_start($p,$query,(join ' ', caller)) if (defined($p->{dbdbf}));

	my $data;

    $p->error->throw unless($sth = $p->{$dbh}->prepare($query));
	$p->error->throw unless($sth->execute(@$bind));

	$p->{queries}++;

	debug_end($p,$st) if (defined($p->{dbdbf}));

	if (defined($scalar_ref)) {
		$$scalar_ref = $sth->fetchrow_array();
		$sth->finish;
		return 1;
	} else {
		$data = $sth->fetchrow_array();
		$sth->finish;
		return $data;
	}
}

=item doQuery($query,\%hashref)

C<1 || 0>

Run a query.

=cut

sub doQuery {
	my $p = shift;
	my $query = quote_in($p,shift);
	my $bind = [];
	$bind = shift if (ref($_[0]) eq 'ARRAY');
	my ($rv,$sth);
	my $dbh = (defined($p->{use_dbh})) ? $p->{use_dbh} : "dbh";

	my $st = debug_start($p,$query,(join ' ', caller)) if (defined($p->{dbdbf}));

	$p->error->throw unless($sth = $p->{$dbh}->prepare($query));
	$p->error->throw unless($rv = $sth->execute(@$bind));

	$p->{queries}++;

	debug_end($p,$st) if (defined($p->{dbdbf}));

	return $rv;
}

=item updateWithHash($table,$column,$row,\%hashref)

C<1 || 0>

Take the given hash reference and updates the $table where $column=$row.

The keys of the hashref must match table column names.

If the value of a hash key is "", empty or the string "NULL" then the field
will be updated with a database NULL entry.

=cut

sub updateWithHash {
	my $p = shift;
	my $table = shift;
	my $column = shift;
	my $row = shift;
	my $hash = shift;

	my ($querystring,$key,@values,$sth,$rows);
	my @querylist;
	my $dbh = (defined($p->{use_dbh})) ? $p->{use_dbh} : "dbh";

	foreach $key (keys %$hash) {
		# skip the $column key because it causes unnessesary trigger checking
		# and we really should never be changing the primary key from here anyway right
		next if ($key eq $column);

		if ($$hash{$key} eq "") {
			push @querylist, qq($key=NULL);
		} elsif ($$hash{$key} eq "NULL") {
			push @querylist, qq($key=NULL);
		} elsif ($$hash{$key} =~ /^NOW\(\)$/) {
			push @querylist, "$key=NOW()";
#		} elsif ($$hash{$key} =~ /^_raw:(.+)$/) {
#			push @querylist, qq($key=$1);
		} else {
			push @querylist, qq($key=?);
			push @values, $$hash{$key};
		}
	}

	$row = $p->{$dbh}->quote($row);
	$querystring = join ',',@querylist;

	my $query = qq|UPDATE $table SET $querystring WHERE $column=$row|;

	my $st = debug_start($p,$query,(join ' ', caller)) if (defined($p->{dbdbf}));

    $p->error->throw unless($sth = $p->{$dbh}->prepare($query));
	$p->error->throw unless($rows = $sth->execute(@values));

	$p->{queries}++;

	debug_end($p,$st) if (defined($p->{dbdbf}));

	return $rows;
}

=item updateWithWhere($table,$where,\%hashref)

C<1 || 0>

Works exactly the same as updateWithHash except you can use a statement
to define which rows get updated.

Example:

	$p->updateWithWhere("table_name","id=5 AND name='test'",\%hashref);

=cut

sub updateWithWhere {
	my $p = shift;
	my $table = shift;
	my $where = quote_in($p,shift);
	my $bind = [];
	$bind = shift if (ref($_[0]) eq 'ARRAY');
	my $hash = shift;

	my ($querystring,$key,@values,$sth,$rows);
	my @querylist;
	my $dbh = (defined($p->{use_dbh})) ? $p->{use_dbh} : "dbh";

	$p->error( "Where clause not defined" )->throw unless($where);

	foreach $key (keys %$hash) {
		if ($$hash{$key} eq "") {
			push @querylist, qq($key=NULL);
		} elsif ($$hash{$key} eq "NULL") {
			push @querylist, qq($key=NULL);
		} elsif ($$hash{$key} =~ /^NOW\(\)$/) {
			push @querylist, "$key=NOW()";
#		} elsif ($$hash{$key} =~ /^_raw:(.+)$/) {
#			push @querylist, qq($key=$1);
		} else {
			push @querylist, qq($key=?);
			push @values, $$hash{$key};
		}
	}

    push( @values, @$bind ) if ( @$bind );

	$querystring = join ',',@querylist;

	my $query = qq|UPDATE $table SET $querystring WHERE $where|;

	my $st = debug_start($p,$query,(join ' ', caller)) if (defined($p->{dbdbf}));

	$p->error->throw unless($sth = $p->{$dbh}->prepare($query));
	$p->error->throw unless($rows = $sth->execute(@values));

	$p->{queries}++;

	debug_end($p,$st) if (defined($p->{dbdbf}));

	return $rows;
}

=item insertWithHash($table,\%hashref,[$insertidfield || \$lastinsertid])

C<1 or $lastinsertid || 0>

Take the given hash reference and inserts the $table.

The keys of the hashref must match table column names.

If the value of a hash key is "", empty or the string "NULL" then the field will
not be inserted and with either contain a NULL value in the database or whatever
value is defined as default by the database.

If the database is postgresql and you want to find out what the primary key of the
inserted row was, include the primary key field name as $insertidfield.

Example:

	my $insertid = $p->insertWithHash("table_name",\%hashref,"id");

If the database is mysql and you want to find out the primary key of the inserted
row, then give a scalar reference and mysql will do a LAST_INSERT_ID() function call
and return the value in the scalar reference.

Example:

	$p->insertWithHash("table_name",\%hashref,\$insertid);

=cut

sub insertWithHash {
	my $p = shift;
	my $table = shift;
	my $hash = shift;
	my $lastid = shift;

	my (@keys,@values,$key,@bind,$sth);
	my $dbh = (defined($p->{use_dbh})) ? $p->{use_dbh} : "dbh";

	foreach $key (keys %$hash) {
		next if ($$hash{$key} eq "");
		next if ($$hash{$key} eq "NULL");
		push @keys, qq($key);
#		if ($$hash{$key} =~ /^_raw:(.+)$/) {
#		    push @bind, $1;
#		    next;
#		}
		if ($$hash{$key} =~ /^NOW\(\)$/) {
			push @bind, 'NOW()';
			next;
		}
		push @bind, "?";
		push @values, $$hash{$key};
	}

	my $columns = join ',', @keys;
	my $bind = join ',', @bind;

	my $query = qq|INSERT INTO $table ($columns) VALUES ($bind)|;

	my $st = debug_start($p,$query,(join ' ', caller)) if (defined($p->{dbdbf}));

	unless($sth = $p->{$dbh}->prepare($query)) {
		$p->error->throw;
	}
	unless($sth->execute(@values)) {
		$p->error->throw;
	}
	$p->{queries}++;

	debug_end($p,$st) if (defined($p->{dbdbf}));

	if (defined($lastid)) {
		my ( $keyvalue, $sql );
		if (ref($lastid)) {
            $sql = "SELECT LAST_INSERT_ID()";
            unless ($$lastid = $p->{$dbh}->selectrow_array($sql)) {
                $p->{last_query} .= "\n\n$sql";
    			$p->error->throw;
            }
			$p->{queries}++;
			return 1;
		} else {
			# postgres method of getting the last insert id (or any other column from the last insert)
            $sql = "SELECT $lastid FROM $table WHERE oid='".$sth->{pg_oid_status}."'";
            unless($keyvalue = $p->{$dbh}->selectrow_array($sql)) {
                $p->{last_query} .= "\n\n$sql";
                $p->error->throw;
            }
			$p->{queries}++;
			return $keyvalue;
		}
	}
	
	return 1;
}

sub insert_row {
    my $p = shift;
    my $table = shift;
    my %col_val = @_;
    my @k = keys %col_val;

    my $sql = "INSERT INTO $table (".
        join(", ", @k).") VALUES (".
        join(", ", @col_val{@k}).")";
    return $p->doQuery($sql);
}

sub nextval {
    my $p = shift;
    my $sequence = shift;

	$p->{queries}++;

    return $p->scalarQuery("SELECT nextval('$sequence')");
}

sub currval {
    my $p = shift;
    my $sequence = shift;

	$p->{queries}++;

    return $p->scalarQuery("SELECT currval('$sequence')");
}

sub create_select {
    my $p = shift;

    my %args = @_;

    my $sql = "SELECT ".join("\n    , ", map {
        ref $_ eq 'HASH' ? "$$_{format} AS $$_{name}" : $_
    } grep {
        (ref $_ eq 'HASH' and exists $$_{format} and exists $$_{name})
        or (not ref $_)
    }@{$args{columns}})."\n";

    $sql .= "FROM $args{from}\n";
    
    $sql .= join("\n", map {
        if (ref $_ eq 'HASH') {
            my $type = $$_{type} || 'JOIN';
            "$type $$_{table} AS $$_{name} ON $$_{on}";
        } else {
            $_;
        }
    } @{$args{joins}})."\n"
        if $args{joins};
    $sql .= "WHERE (".join(")\n    AND (", @{$args{wheres}}).")\n"
        if $args{wheres} and @{$args{wheres}};
    $sql .= "GROUP BY ".join("\n    , ", @{$args{group_bys}})."\n"
        if $args{group_bys} and @{$args{group_bys}};
    $sql .= "HAVING ".join("\n    AND ", @{$args{havings}})."\n"
        if $args{havings} and @{$args{havings}};
    $sql .= "ORDER BY ".join("\n    , ", @{$args{order_bys}})."\n"
        if $args{order_bys} and @{$args{order_bys}};
    $sql .= "LIMIT ".$args{limit}."\n"
        if exists $args{limit} and defined $args{limit};
    $sql .= "OFFSET ".$args{offset}."\n"
        if exists $args{offset} and defined $args{offset};

    return $sql;
}

sub sql_to_html {
    my $p = shift;
    my $sql = shift;

    my %par = @_;

    if (exists $par{error}) {
        if ($par{error} =~ /parse error at or near "(.*)" at character (\d+)/) {
            my $l = length $1;
            $sql = ($p->escapeHTML(substr $sql, 0, $2-1).
                "<span style='background-color: red; color: white;'>".
                $p->escapeHTML(substr $sql, $2-1, $l).
                "</span>".
                $p->escapeHTML(substr $sql, $2+$l-1));
        } elsif ($par{error} =~ /No such attribute (\S+)/) {
            $sql =~ s/^(^.*?)(\b$1\b)(.*)$/
                $p->escapeHTML($1).
                "<span style='background-color: red; color: white;'>".
                $p->escapeHTML($2).
                "<\/span>".
                $p->escapeHTML($3)/segi;
        } elsif ($par{error} =~ /Attribute "(\w+)" not found/) {
            $sql =~ s/^(^.*?)(\b$1\b)(.*)$/
                $p->escapeHTML($1).
                "<span style='background-color: red; color: white;'>".
                $p->escapeHTML($2).
                "<\/span>".
                $p->escapeHTML($3)/segi;
        }
    }
    # Get rid of tabs because they don't work so well when cut-and-pasting
    # to psql
    $sql =~ s/\t/    /g;

    # Do some rudimentary syntax highlighting.

    # Blue is for literals
    # '...'
    $sql =~ s/(&apos;.*?&apos;|null)/<span style='color: #000088;'>$1<\/span>/gi;

    # Red is for keywords
    my $match = '(\b'.
        join('\b|\b',
            'group\s+by', 'order\s+by', 'left\s+join',
            qw(select as from where join on and or having case
            when then else end asc desc)
        ).
        '\b)';
    $sql =~ s/$match/<span style="color: #880000;"><b>$1<\/b><\/span>/gi;

    # Green is for functions.
    $match = '(\b'.
        join('\b|\b',
            qw(to_char date_part date_extract date_trunc sum count avg stddev
            timestamp time interval)
        ).
        '\b)';
    $sql =~ s/$match/<span style="color: #008800;"><i>$1<\/i><\/span>/gi;

    return <<END;
<pre style='background-color: #ffffff; padding-left: 3em;'>
$sql
</pre>
END
    
}

sub disconnect {
	my $p = shift;

	my $dbh = (defined($p->{use_dbh})) ? $p->{use_dbh} : "dbh";

	return defined $p->{$dbh} ? $p->{$dbh}->disconnect() : undef;
}

1;
