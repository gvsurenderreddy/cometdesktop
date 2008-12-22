/*
 * Comet Desktop
 * Copyright (c) 2008 - David W Davis, All Rights Reserved
 * xantus@cometdesktop.com     http://xant.us/
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
 * Ext JS Library
 * Copyright(c) 2006-2008, Ext JS, LLC.
 * licensing@extjs.com
 *
 * http://extjs.com/license
 *
 */

(function() {


function key() {
    var l = document.location.hostname.split('.').reverse();
    var domain = l[ 0 ];
    if ( l[ 1 ] )
        domain = l[ 1 ] + '.' + domain;
    
    if ( window.gmapKeys && typeof window.gmapKeys == 'object' )
         if ( window.gmapKeys[domain] )
            return window.gmapKeys[domain];
    
    switch ( domain ) {
        case 'cometdesktop.com':
            return 'ABQIAAAAYgQjst0JS5tHisqK_AAuVBQFH5yvK3J35cQLRePNcze-9ERIHhQGuVXzg0fnZTxpDJ76COLoxcuLww';
        default:
            /* localhost key */
            return 'ABQIAAAAJDLv3q8BFBryRorw-851MRT2yXp_ZAY8_ufC3CFXhHIE1NvwkxTyuslsNlFqyphYqv1PCUD8WrZA2A';
    }
}

if ( !desktopConfig.localmode ) {
    document.write('<'+'script src="http'+( Ext.isSecure ? "s" : "" )+'://www.google.com/jsapi?key='+key()+'">'+'<'+'/script>');
}

})();
