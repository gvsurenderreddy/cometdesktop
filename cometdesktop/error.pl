#!/usr/bin/perl

use strict;
use warnings;

# Note that we don't use CometDesktop here

my $qs = $ENV{QUERY_STRING};
my $error = 'Unknown';

my %errors = (
    403 => '403 Not Authorized',
    404 => '404 Not Found',
    500 => '500 Server error',
);

# XXX common 404's can be caught here
my $ec = 200;
if ( $qs && $qs =~ m/^\d+$/ && exists $errors{$qs} ) {
    $error = $errors{$qs};
    $ec = $qs;
    print "Status: $qs\n";
#    warn "$error for request: $ENV{REQUEST_URI} ".( $ENV{HTTP_COOKIE} ? "Cookie:$ENV{HTTP_COOKIE}" : '' )."\n";
}

print "Content-Type: text/html\n\n";
my $out = qq|<!DOCTYPE>
<html>
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <title>&#x2604; $error</title>
</head>
<body>
<h3>&#x2604; Comet Desktop: Error $error</h3>
</body>
</html>
|;

utf8::encode($out);
print $out;

1;
