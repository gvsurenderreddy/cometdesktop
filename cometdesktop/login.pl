#!/usr/bin/perl

use strict;
use warnings;

use lib $ENV{COMETDESKTOP_ROOT} ? $ENV{COMETDESKTOP_ROOT}.'/perl-lib' : 'perl-lib';

use CometDesktop qw(
    -Digest::SHA1[sha1_hex]
);

print "Pragma: nocache\n";
print "Cache-Control: no-cache\n";
print "Expires: 0\n";

if ( $ENV{REQUEST_METHOD} eq 'POST' ) {
    print "Content-Type: text/javascript\n\n";

    #if ( $desktop->user->logged_in ) {
    #    print qq|{redirect:'logout.pl'}|;
    #    exit;
    #}
    
    my $ret = $desktop->user->login( $desktop->cgi_params('user','sha1','token') );
    
    unless ( $ret ) {
        print qq|{errors:[{msg:'Not Allowed'}]}|;
        exit;
    }
    
    if ( $ret == 1 ) {
        print $desktop->encode_json({
            success => 'true',
            sessionId => $desktop->user->session_id_tokenized,
            userName => $desktop->user->email_address,
            ( $ENV{HTTPS} ? ( nonSecure => 'true' ) : () ),
            days => 365,
        });
    }

} else {
    if ( !exists $ENV{HTTPS} && $desktop->secure_login ) {
        my $url = $ENV{SCRIPT_URI};
        if ( $url ) {
            $url =~ s/^http:/https:/;
            print "Location: $url\n\n";
            exit;
        }
    }
    my $time = CORE::time(); # not HiRes
    my $token = $time.'~'.sha1_hex( $time.':'.$desktop->login_secret );
    my $v = $desktop->version;
    my $http = ( $ENV{HTTPS} && $ENV{HTTPS} eq 'on' ) ? 'https' : 'http';

    my $ga = qq|
<script type="text/javascript">
    var gaJsHost = (("https:" == document.location.protocol) ? "https://ssl." : "http://www.");
    document.write(unescape("%3Cscript src='" + gaJsHost + "google-analytics.com/ga.js' type='text/javascript'%3E%3C/script%3E"));
</script>
<script type="text/javascript">
    var pageTracker = _gat._getTracker("\$ga_id");
    pageTracker._trackPageview();
</script>
|;
    $ga = '<!-- disabled for localhost -->' if ( $ENV{REMOTE_ADDR} eq '127.0.0.1' );
    $ga = '<!-- disabled for local mode -->' if ( $desktop->localmode );
    if ( my $act = $desktop->ga_account ) {
        $ga =~ s/\$ga_id/$act/g;
    } else {
        $ga = '<!-- disabled, set ga_account in your config to enable -->';
    }
    print "Content-Type: text/html\n\n";
# TODO proper doctype
my $out = qq|<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html lang="en">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>\x{2604} Comet Desktop - Login</title>
<meta http-equiv="generator" content="Comet Desktop" />
<meta http-equiv="imagetoolbar" content="no" />
<meta name="keywords" content="comet, desktop, web desktop, webos, web os, webtop, perl, javascript, sprocket, extjs, ext js, ajax, web socket, xantus" />
<link rel="icon" type="image/x-icon" href="/favicon.ico" />

<!-- Extjs -->
<link rel="stylesheet" type="text/css" href="lib/ext-2.2/resources/css/ext-all.css" />
<script src="lib/ext-2.2/adapter/ext/ext-base.js"></script>
<script src="lib/ext-2.2/ext-all.js"></script>

<!-- Theme -->
<link id="theme" rel="stylesheet" type="text/css" href="resources/themes/xtheme-vistablack/css/xtheme-vistablack.css?v=$v" />

<!-- GA -->
$ga

<!-- Login app -->
<script src="system/login/cookies.js?v=$v"></script>
<link rel="stylesheet" type="text/css" href="resources/css/desktop.css?v=$v" />
<link rel="stylesheet" type="text/css" href="system/login/login.css?v=$v" />
<script type="text/javascript">
    window.loginToken = '$token';
</script>
<script src="system/login/login.js?v=$v"></script>

</head>

<body scroll="no">
</body>
</html>|;
    utf8::encode($out);
    print $out;
}

1;

    

