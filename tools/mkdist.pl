#!/usr/bin/perl

use strict;
use warnings;

open ( my $fh, "cometdesktop/VERSION" ) or die "VERSION: $!";

my ( $v ) = <$fh>;
chomp $v;

my $file = "cometdesktop-v${v}.zip";

system("rm $file") if ( -e $file );

system('zip -r '.$file.' cometdesktop -i@tools/include.list -x@tools/exclude.list');

print "\n\ncreated $file\n";
