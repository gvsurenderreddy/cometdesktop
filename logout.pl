#!/usr/bin/perl

use strict;
use warnings;

use lib $ENV{COMETDESKTOP_ROOT} ? $ENV{COMETDESKTOP_ROOT}.'/perl-lib' : 'perl-lib';

use CometDesktop;

$desktop->user->logout();

print "Set-Cookie: sessionId=; path=/; expires=Thu, 01-Jan-1970 00:00:01 GMT\n";
print "Location: login.pl\n\n";

1;
