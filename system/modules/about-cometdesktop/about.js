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

QoDesk.AboutCometDesktop = Ext.extend(Ext.app.Module, {

	moduleType : 'core',
	moduleId : 'about-cometdesktop',
	
	init : function(){		
		this.launcher = {
			handler: this.createWindow,
			iconCls: 'about-cometdesktop-icon',
			scope: this,
			shortcutIconCls: 'about-cometdesktop-shortcut',
			text: 'About',
			tooltip: '<strong>About Comet Desktop</strong>'
		}
	},

	createWindow : function(){
		var win = app.desktop.getWindow('about-cometdesktop-win');

		if (!win) {
            win = app.desktop.createWindow({
                title: 'About Comet Desktop',
                id: 'about-cometdesktop-win',
                layout:'fit',
                width:460,
                height:320,
                iconCls: 'about-cometdesktop-icon',
                bodyStyle:'color:#000',
                plain: true,
                items: new Ext.TabPanel({
                    autoTabs:true,
                    activeTab:0,
                    border:false,
                    defaults: {
                        autoScroll: true,
                        bodyStyle:'padding:5px'
                    },
                    items: [
                    {
                        title: 'About',
                        autoLoad: {url: 'system/modules/about-cometdesktop/html/about.html?v='+desktopConfig.version}
                    },
                    {
                        title: 'Credits',
                        autoLoad: {url: 'system/modules/about-cometdesktop/html/credits.html?v='+desktopConfig.version}
                    },
                    {
                        title: 'License',
                        autoLoad: {url: 'system/modules/about-cometdesktop/html/license.html?v='+desktopConfig.version}
                    }
                    ]
                })
            });
        }
        win.show();
    }

});
