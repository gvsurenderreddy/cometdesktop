#!/usr/bin/perl

use strict;
use warnings;

use lib $ENV{COMETDESKTOP_ROOT} ? $ENV{COMETDESKTOP_ROOT}.'/perl-lib' : 'perl-lib';

use CometDesktop;

print "Pragma: nocache\n";
print "Cache-Control: no-cache\n";
print "Expires: 0\n";

my $out;
$desktop->localmode( 1 ) if ( $ENV{LOCAL_MODE} );

my $v = $desktop->version;
my $ga = qq|
<!-- GA -->
<script type="text/javascript">
var gaJsHost = (("https:" == document.location.protocol) ? "https://ssl." : "http://www.");
document.write(unescape("%3Cscript src='" + gaJsHost + "google-analytics.com/ga.js' type='text/javascript'%3E%3C/script%3E"));
</script>
<script type="text/javascript">
    var pageTracker;
    if ( window._gat ) {
        pageTracker = _gat._getTracker("UA-248266-13");
        pageTracker._trackPageview();
    }
</script>
|;

$ga = '<!-- disabled for localhost -->' if ( $ENV{REMOTE_ADDR} && $ENV{REMOTE_ADDR} eq '127.0.0.1' );
$ga = '<!-- disabled for local mode -->' if ( $desktop->localmode );

unless( $desktop->user->logged_in ) {
#    print "Location: login.pl\n\n";
    print "Content-Type: text/html\n\n";

$out = qq|<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html lang="en">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title>\x{2604} Comet Desktop - Web Desktop - JavaScript Desktop - Extjs - Comet [ v$v ]</title>
<meta http-equiv="generator" content="Sprocket" />
<meta name="keywords" content="comet, desktop, web desktop, webos, web os, webtop, javascript desktop, perl, javascript, sprocket, comet, cometd, dojo, extjs, ext, ajax, xantus, mtfnpy, david davis, sprocket, sprocket.socket, websocket, web socket, sprocket.gateway, javscript socket, poe, sprocketframework" />
<link rel="shortcut icon" type="image/x-icon" href="/favicon.ico" />
<link rel="icon" type="image/x-icon" href="/favicon.ico" />
<style type="text/css">
    body {
        color: #fff;
        background: #000;
    }
</style>
</head>
<body>
    <h3>Comet Desktop, the web desktop.  Also known as a webOS, webtop, or JavaScript desktop</h3>
    Comet Desktop usess technologies like: Extjs, ajax, web sockets (Sprocket.Socket and Sprocket.Gateway) and cross domain comet.
    <br/><br/>
    <div id="message"></div>
    <noscript>
        <h2>JavaScript Required</h2>
        Please enable JavaScript, and refresh this page.  You're really missing out!
    </noscript>
    $ga    
    <script type="text/javascript">
        var msg = document.getElementById('message');
        if ( msg )
            msg.innerHTML = '<strong>Please wait while you are redirected</login>';
        window.onload = function() { window.location.href = 'login.pl'; };
    </script>
</body>
</html>|;
    utf8::encode($out);
    print $out;
    exit;
}

my $css = $desktop->css_includes();
my $hash = $desktop->javascript_hash;
#my $debug = ( $desktop->user->group_id == 1 ) ? '<script src="lib/debug.js?v='.$v.'"></script>' : '';
my $debug = '';
my $config = $desktop->encode_json($desktop->get_config);
my $https = ($ENV{HTTPS} && $ENV{HTTPS} eq 'on') ? 1 : 0;
my $extcss = ( $https || $desktop->localmode ) ? qq|
<link rel="stylesheet" type="text/css" href="lib/ext-2.2/resources/css/ext-all.css" />
| : qq|
<!-- CacheFly CDN -->
<link rel="stylesheet" type="text/css" href="http://extjs.cachefly.net/ext-2.2/resources/css/ext-all.css" />
|;
my $extjs = ( $https || $desktop->localmode ) ? qq|
<script src="lib/ext-2.2/adapter/ext/ext-base.js"></script>
<script src="lib/ext-2.2/ext-all.js"></script>
| : qq|
<!-- CacheFly CDN -->
<script type="text/javascript" src="http://extjs.cachefly.net/ext-2.2/adapter/ext/ext-base.js"></script>
<script type="text/javascript" src="http://extjs.cachefly.net/ext-2.2/ext-all.js"></script>
|;

print "Content-Type: text/html\n\n";

$out = qq|<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html lang="en">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title>\x{2604} Comet Desktop - David Davis - Xantus [ v$v ]</title>
<meta http-equiv="generator" content="Sprocket" />
<meta http-equiv="imagetoolbar" content="no" />
<meta name="keywords" content="comet, desktop, web desktop, webos, web os, webtop, perl, javascript, sprocket, comet, cometd, dojo, extjs, ext, ajax, xantus, mtfnpy, david davis" />
<link rel="shortcut icon" type="image/x-icon" href="/favicon.ico" />
<link rel="icon" type="image/x-icon" href="/favicon.ico" />

<style type="text/css">
#loading-mask{
    position: absolute;
    left: 0;
    top: 0;
    width: 100%;
    height: 100%;
    z-index: 20000;
    background-color: #000;
}
#loading{
    position: absolute;
    left: 45%;
    top: 40%;
    padding: 2px;
    z-index: 20001;
    height: auto;
}
#loading .loading-indicator{
    background: #000;
    background-image:url(lib/Ext/resources/images/default/grid/loading.gif);
    background-repeat: no-repeat;
    background-position:bottom center;
    color: #fff;
    font: bold 13px tahoma,arial,helvetica;
    padding: 20px;
    margin: 0;
    text-align:center;
    height:auto;
}
</style>

<!-- ExtJS CSS -->
$extcss

<!-- CSS -->
$css

</head>

<body scroll="no">
<div id="x-desktop">
<div id="loading-mask"></div>
<div id="loading">
    <div class="loading-indicator"> Loading....</div>
</div>
</div>

<div id="ux-taskbar">
	<div id="ux-taskbar-start"></div>
	<div id="ux-taskbar-panel-wrap">
		<div id="ux-quickstart-panel"></div>
		<div id="ux-taskbuttons-panel"></div>
		<div id="ux-tray-panel"></div>
	</div>
<div class="x-clear"></div>
</div>
<!-- ExtJS -->
$extjs

$debug
<!-- JS -->
<script type="text/javascript">
    if ( window.console ) {
        window.log = function(m) { window.console.log(m); };
    } else if ( Ext.log ) {
        window.log = window.Ext.log;
    } else {
        window.log = Ext.emptyFn;
    }
    var desktopConfig = $config;
</script>
<script type="text/javascript" src="javascript.pl?v=$v&amp;h=$hash"></script>
$ga
</body>
</html>|;

utf8::encode($out);
print $out;
