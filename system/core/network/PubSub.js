/* Hierarchical PubSub for Extjs
 * Ext.ux.Sprocket.PubSub
 * Version: 1.1
 * 
 * Copyright (c) 2008 - David Davis, All Rights Reserved
 * xantus@xant.us
 * http://xant.us/
 *
 * License: Same as Extjs v2.0
 *
 * Please do not remove this header
 */

Ext.namespace('Ext.ux.Sprocket');

Ext.override(Ext.util.Observable, {

    subscribe: function( eventName, fn, scope, o ) {
        Ext.ux.Sprocket.PubSub.addEvents( eventName );
        Ext.ux.Sprocket.PubSub.on( eventName, fn, scope, o);
    },

    publish: function( eventName, event ) {
        if ( Ext.ux.Sprocket.PubSub.eventsSuspended === true )
            return true;
        if ( !Ext.ux.Sprocket.PubSub.events )
            return false;
        
        if ( eventName.substr( 0, 1 ) == '/' && eventName.length > 1 ) {
            var chans = eventName.substr( 1 ).split( '/' );
            var matched = false;
            for ( var i = 0, len = chans.length; i <= len; i++ ) {
                var fn = Ext.ux.Sprocket.PubSub.events[ '/' + chans.slice( 0, i ).join( '/' ).toLowerCase() ];
                if ( fn ) {
                    matched = true;
                    if ( fn.fire.call( fn, event, eventName ) === false )
                        return true;
                }
            }
            return matched;
        } else {
            var fn = Ext.ux.Sprocket.PubSub.events[ eventName.toLowerCase() ];
            if ( fn ) {
                fn.fire.call( fn, event, eventName );
                return true;
            }
        }
        return false;
    },

    removeSubcribers: function( eventName ) {
        for ( var evt in Ext.ux.Sprocket.PubSub.events ) {
            if ( ( evt == eventName ) || ( !eventName ) ) {
                var fn = Ext.ux.Sprocket.PubSub.events[ evt ];
                if ( fn )
                    Ext.ux.Sprocket.PubSub.events[ fn ].clearListeners();
            }
        }
    }

});

Ext.ux.Sprocket.PubSub = new Ext.util.Observable();


/* Comet Desktop Example: log all events

if ( window.app ) {
    app.onReady(function() {
        this.subscribe( '/', function(event, channel) {
            log('event:'+channel,event);
        });
    },app);
}

*/
