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
 * qWikiOffice Desktop v0.7.1
 * Copyright(c) 2007-2008, Integrated Technologies, Inc.
 * licensing@qwikioffice.com
 * http://www.qwikioffice.com/license.php
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

Ext.SSL_SECURE_URL="resources/images/default/s.gif"; 
Ext.BLANK_IMAGE_URL="resources/images/default/s.gif";

Login = function(){
	var win,
		form,
        msgCt,
		submitUrl = 'login.pl';
		
	function onSubmit(){
		this.showMask();
		
		form.submit({
			reset: true
		});
	}

    function createBox(t, s){
        return ['<div class="msg">',
                '<div class="x-box-tl"><div class="x-box-tr"><div class="x-box-tc"></div></div></div>',
                '<div class="x-box-ml"><div class="x-box-mr"><div class="x-box-mc"><h3>', t, '</h3>', s, '</div></div></div>',
                '<div class="x-box-bl"><div class="x-box-br"><div class="x-box-bc"></div></div></div>',
                '</div>'].join('');
    }

	
	return{
		Init:function(){
			Ext.QuickTips.init();
			
    		new Ext.KeyMap(document, [
	    	{
		    	key: Ext.EventObject.BACKSPACE,
			    stopEvent: false,
    			fn: function(key, e){
	    			var t = e.target.tagName;
                    if ( !t )
                        return;
                    t = t.toLowerCase();
                    if(t != "input" && t != "textarea")
	    			    e.stopEvent();
		    	}
            }
    	    ]);

            // TODO, replace this with renterTo or something
			var logoPanel = new Ext.Panel({
//				baseCls: 'x-plain',
				id: 'login-logo',
                border: false,
                html: '<center><h1>Comet Desktop</h1>\
                    <br/>\
                    <a href="http://code.google.com/p/cometdesktop/" target="_blank">Project Website</a><br/>\
                    <br/>\
                    </center>\
                    ',
		        region: 'center'
			});
			
            var focusFirst = 'user';
            var email = 'guest';
            var pass = 'guest';
            var lastUser = get_cookie('lastUsername');
            if ( lastUser ) {
                email = lastUser;
                if ( lastUser != 'guest' ) {
                    pass = '';
                    focusFirst = 'pass';
                }
            }
            
			var formPanel = new Ext.form.FormPanel({
		        baseCls: 'x-plain',
		        baseParams: {
		        	module: 'login'
		        },
		        defaults: {
		        	width: 250
		        },
		        defaultType: 'textfield',
		        frame: false,
		        height: 70,
		        id: 'login-form',
		        items: [{
		            fieldLabel: 'Username',
		            name: 'user',
		            value: email
		        },{
		            fieldLabel: 'Password',
		            inputType: 'password',
		            name: 'pass',
		            value: pass
                },{
                    xtype: 'hidden',
                    name: 'sha1',
                    value: ''
                },{
                    xtype: 'hidden',
                    name: 'token',
                    value: ( window.loginToken ? window.loginToken : '' )
                }],
		        labelWidth:65,
		        listeners: {
					'actioncomplete': {
						fn: this.onActionComplete,
						scope: this
					},
					'actionfailed': {
						fn: this.onActionFailed,
						scope: this
					}
				},
		        region: 'south',
		        url: submitUrl
		    });
		
		    win = new Ext.Window({
                iconCls: ( Ext.isSecure ? 'lock-icon' : '' ),
		        buttons: [{
		        	handler: onSubmit,
		        	scope: Login,
		            text: 'Login'
		        }],
		        buttonAlign: 'right',
		        closable: false,
		        draggable: true,
		        height: 250,
		        id: 'login-win',
		        keys: {
		        	key: [13], // enter key
			        fn: onSubmit,
			        scope:this
		        },
		        layout: 'border',
		        minHeight: 250,
		        minWidth: 430,
		        plain: false,
		        resizable: false,
		        items: [
		        	logoPanel,
		        	formPanel
		        ],
				title: 'Login',
		        width: 430
		    });
			
			form = formPanel.getForm();

            form.on('beforeaction',function() {
                var pass = form.findField('pass');
                var token = form.findField('token').getValue().split( '~' )[ 1 ];
                var sha = sha1( pass.getValue() );
                form.findField('sha1').setValue( sha1( token + ':' + sha ) + ':' + sha );
                /* send the hash, not the password */
                pass.setValue('');
                return true;
            },this);

			formPanel.on('render', function(){
				var f = form.findField(focusFirst);
				
				if (f)
                    f.focus.defer(100,f);
			}, this, {delay: 200});
			
		    win.show();
		},
		
		hideMask : function(){
			this.pMask.hide();
			win.buttons[0].enable();
		},
		
		onActionComplete : function(f, a){
			this.hideMask();
			if(a && a.result){
				// get the path
				var path = window.location.pathname;
                path = path.substring(0, path.lastIndexOf('/') + 1);
					
                // delete older cookies without a domain
			    delete_cookie('sessionId', path );
                delete_cookie('lastUsername', path );
                
                set_cookie('lastUsername', a.result.userName || '', a.result.days || '', path, '.' + document.domain );
                
                if ( a.result.success && a.result.success == 'true' ) {
    				// set the cookies
	    			set_cookie('sessionId', a.result.sessionId, a.result.days || '', path, '.' + document.domain );
		        } else {
                    return this.onActionFailed(f,a);
                }
				
                win.destroy(true);

                if ( a.result.nonSecure && Ext.isSecure ) {
                    // we're secure and the server requested non secure mode
                    path = window.location.toString();
                    path = path.substring(0, path.lastIndexOf('/') + 1);
                    window.location.href = path.replace( /^https:/, 'http:' );
                } else
				    window.location = path;
			}
		},
		
		onActionFailed : function(f, a){
            this.hideMask();
            if ( a && a.result && a.result.errors )
                for ( var i = 0, len = a.result.errors.length; i < len; i++ )
                    if ( a.result.errors[i].msg )
                        this.msg('Error', a.result.errors[i].msg);

            if ( a && a.result && a.result.reload )
                window.location = window.location;

            if ( a && a.result && a.result.redirect )
                window.location = a.result.redirect;
		},
		
		showMask : function(msg){
			if(!this.pMask){
				// using this.pMask, seems that using this.mask caused conflict
		        // when this dialog is modal (uses this.mask also)
		        this.pMask = new Ext.LoadMask(win.body, {
		        	msg: 'Please wait...'
		        });
			}
			
			if(msg){
				this.pMask.msg = msg;
			}
	    	this.pMask.show();
	    	win.buttons[0].disable();
	    },

        msg: function(title, format){
            if( !msgCt )
                msgCt = Ext.DomHelper.insertFirst(document.body, {id:'msg-div'}, true);
            msgCt.alignTo(document, 'b-t');
            var s = String.format.apply(String, Array.prototype.slice.call(arguments, 1));
            var m = Ext.DomHelper.append(msgCt, {html:createBox(title, s)}, true);
            m.slideIn('t').pause(2).ghost("t", {remove:true});
        }
	};
}();

Ext.onReady(Login.Init, Login, true);

/**
*
*  Secure Hash Algorithm (SHA1)
*  http://www.webtoolkit.info/
*  License: unknown, public domain assumed
*
**/

function sha1 (msg) {

    function rotate_left(n,s) {
        var t4 = ( n<<s ) | (n>>>(32-s));
        return t4;
    };

    function lsb_hex(val) {
        var str="";
        var i;
        var vh;
        var vl;

        for( i=0; i<=6; i+=2 ) {
            vh = (val>>>(i*4+4))&0x0f;
            vl = (val>>>(i*4))&0x0f;
            str += vh.toString(16) + vl.toString(16);
        }
        return str;
    };

    function cvt_hex(val) {
        var str="";
        var i;
        var v;

        for( i=7; i>=0; i-- ) {
            v = (val>>>(i*4))&0x0f;
            str += v.toString(16);
        }
        return str;
    };


    function Utf8Encode(string) {
        string = string.replace(/\r\n/g,"\n");
        var utftext = "";

        for (var n = 0; n < string.length; n++) {

            var c = string.charCodeAt(n);

            if (c < 128) {
                utftext += String.fromCharCode(c);
            }
            else if((c > 127) && (c < 2048)) {
                utftext += String.fromCharCode((c >> 6) | 192);
                utftext += String.fromCharCode((c & 63) | 128);
            }
            else {
                utftext += String.fromCharCode((c >> 12) | 224);
                utftext += String.fromCharCode(((c >> 6) & 63) | 128);
                utftext += String.fromCharCode((c & 63) | 128);
            }

        }

        return utftext;
    };

    var blockstart;
    var i, j;
    var W = new Array(80);
    var H0 = 0x67452301;
    var H1 = 0xEFCDAB89;
    var H2 = 0x98BADCFE;
    var H3 = 0x10325476;
    var H4 = 0xC3D2E1F0;
    var A, B, C, D, E;
    var temp;

    msg = Utf8Encode(msg);

    var msg_len = msg.length;

    var word_array = new Array();
    for( i=0; i<msg_len-3; i+=4 ) {
        j = msg.charCodeAt(i)<<24 | msg.charCodeAt(i+1)<<16 |
        msg.charCodeAt(i+2)<<8 | msg.charCodeAt(i+3);
        word_array.push( j );
    }

    switch( msg_len % 4 ) {
        case 0:
            i = 0x080000000;
        break;
        case 1:
            i = msg.charCodeAt(msg_len-1)<<24 | 0x0800000;
        break;

        case 2:
            i = msg.charCodeAt(msg_len-2)<<24 | msg.charCodeAt(msg_len-1)<<16 | 0x08000;
        break;

        case 3:
            i = msg.charCodeAt(msg_len-3)<<24 | msg.charCodeAt(msg_len-2)<<16 | msg.charCodeAt(msg_len-1)<<8    | 0x80;
        break;
    }

    word_array.push( i );

    while( (word_array.length % 16) != 14 ) word_array.push( 0 );

    word_array.push( msg_len>>>29 );
    word_array.push( (msg_len<<3)&0x0ffffffff );


    for ( blockstart=0; blockstart<word_array.length; blockstart+=16 ) {

        for( i=0; i<16; i++ ) W[i] = word_array[blockstart+i];
        for( i=16; i<=79; i++ ) W[i] = rotate_left(W[i-3] ^ W[i-8] ^ W[i-14] ^ W[i-16], 1);

        A = H0;
        B = H1;
        C = H2;
        D = H3;
        E = H4;

        for( i= 0; i<=19; i++ ) {
            temp = (rotate_left(A,5) + ((B&C) | (~B&D)) + E + W[i] + 0x5A827999) & 0x0ffffffff;
            E = D;
            D = C;
            C = rotate_left(B,30);
            B = A;
            A = temp;
        }

        for( i=20; i<=39; i++ ) {
            temp = (rotate_left(A,5) + (B ^ C ^ D) + E + W[i] + 0x6ED9EBA1) & 0x0ffffffff;
            E = D;
            D = C;
            C = rotate_left(B,30);
            B = A;
            A = temp;
        }

        for( i=40; i<=59; i++ ) {
            temp = (rotate_left(A,5) + ((B&C) | (B&D) | (C&D)) + E + W[i] + 0x8F1BBCDC) & 0x0ffffffff;
            E = D;
            D = C;
            C = rotate_left(B,30);
            B = A;
            A = temp;
        }

        for( i=60; i<=79; i++ ) {
            temp = (rotate_left(A,5) + (B ^ C ^ D) + E + W[i] + 0xCA62C1D6) & 0x0ffffffff;
            E = D;
            D = C;
            C = rotate_left(B,30);
            B = A;
            A = temp;
        }

        H0 = (H0 + A) & 0x0ffffffff;
        H1 = (H1 + B) & 0x0ffffffff;
        H2 = (H2 + C) & 0x0ffffffff;
        H3 = (H3 + D) & 0x0ffffffff;
        H4 = (H4 + E) & 0x0ffffffff;

    }

    var temp = cvt_hex(H0) + cvt_hex(H1) + cvt_hex(H2) + cvt_hex(H3) + cvt_hex(H4);

    return temp.toLowerCase();

}
