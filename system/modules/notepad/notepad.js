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

QoDesk.Notepad = Ext.extend(Ext.app.Module, {

	moduleType : 'app',
	moduleId : 'notepad',
	
	init : function() {		
		this.launcher = {
			handler: this.createWindow,
			iconCls: 'notepad-icon',
			scope: this,
			shortcutIconCls: 'notepad-shortcut',
			text: 'Notepad',
			tooltip: '<b>Notepad</b><br />Jot down notes'
		};
        this.currentId = 0;
        this.fetchNotes();
	},

    fetchNotes: function() {
        Ext.Ajax.request({
            url: app.connection,
            success: function(r) {
                var data = {};
                if ( r && r.responseText )
                    data = Ext.decode( r.responseText );
                if ( data.success ) {
                    var len = data.notes.length;
                    for (var i = 0; i < len; i++)
                        this.openNote( 'notepad-win-'+data.notes[ i ].id, data.notes[ i ].note );
                }
            },
            failure: function() {
                // TODO
            },
            params: {
                moduleId: 'notepad',
                task: 'fetch',
                what: 'notes'
            },
            scope: this
        });
    },

    createId: function() {
        this.currentId++;
        // windows with ext- aren't saved in the registry
        return 'ext-notepad-win-'+this.currentId;
    },

	createWindow : function() {
        this.openNote();
    },

    openNote: function( id, note ) {
        if ( !id )
            id = this.createId();
       
        var form = new Ext.form.FormPanel({
            baseCls: 'x-plain',
            labelWidth: 55,
            defaultType: 'textfield',
            items: [{
                xtype: 'hidden',
                name: 'moduleId',
                value: 'notepad'
            },{
                xtype: 'hidden',
                name: 'task',
                value: 'save'
            },{
                xtype: 'hidden',
                name: 'what',
                value: 'notes'
            },{
                xtype: 'textarea',
                hideLabel: true,
                name: 'note',
                anchor: '100% 100%',
                value: note || '',
                listeners: {
                    change:{
                        fn: function(f,val) {
                            this.saveNote(win.id,val);
                        },
                        scope: this
                    }
                }
            }]
        });

        var cfg = {
            title: 'Notepad',
            iconCls: 'notepad-icon',
            maximizable: true,
            width: 300,
            height: 200,
            minWidth: 175,
            minHeight: 100,
            layout: 'fit',
            items: form,
            stateId: id,
            id: id
        };

	    var win = app.desktop.createWindow(cfg);
        win.on('close',function() {
            // clear the setting
            // confirm close
            this.deleteNote(win.id);
        }, this);
        win.show();
    },

    saveNote:function( id, note ) {
        var newNote = false;
        var m = id.match( /^notepad-win-(\d+)/ );
        if ( m && m[ 1 ] )
            id = m[ 1 ];
        else
            newNote = true;
        Ext.Ajax.request({
            url: app.connection,
            success: function(r) {
                var data = {};
                if ( r && r.responseText )
                    data = eval( "(" + r.responseText + ")" );
                if ( data.success ) {
                    if ( data.noteId ) {
                        if ( newNote ) {
		                    var w = app.desktop.getWindow(id);
                            if ( w ) {
                                w.id = w.stateId = 'notepad-win-'+data.noteId;
                                // fire state update?
                                w.fireEvent('show',w);
                            }
                        }
                    }
                }
            },
            failure: function() {
            },
            params: {
                moduleId: 'notepad',
                task: 'save',
                what: newNote ? 'new' : id,
                note: note
            },
            scope: this
        });
    },
    
    deleteNote:function( id ) {
        var m = id.match( /notepad-win-(\d+)/ );
        if ( m && m[ 1 ] )
            id = m[ 1 ];
        else
            return;
        Ext.Ajax.request({
            url: app.connection,
            success: function() {
            },
            failure: function() {
            },
            params: {
                moduleId: 'notepad',
                task: 'delete',
                what: id
            },
            scope: this
        });
    }
    
});


