#!/usr/bin/perl

use strict;
use warnings;

open ( my $fh, "cometdesktop/VERSION" ) or die "VERSION: $!";

my ( $v ) = <$fh>;
chomp $v;

my $file = "cometdesktop-${v}.zip";

system("rm $file") if ( -e $file );

system('zip -r '.$file.' cometdesktop -x@tools/exclude.list -i@tools/include.list');

print "\n\ncreated $file\n";
