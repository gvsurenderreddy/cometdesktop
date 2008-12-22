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
 * -----
 *
 * This is a port from one of the samples that come with Extjs
 * http://extjs.com/deploy/dev/examples/feed-viewer/view.html
 *
 * It has been modified to persist the feed list
 */

QoDesk.FeedViewer = {};

QoDesk.FeedReader = Ext.extend(Ext.app.Module, {

    moduleType : 'app',
    moduleId : 'feed-reader',
    
    init : function() {
        this.launcher = {
            handler: this.createWindow,
            iconCls: 'feed-reader-icon',
            scope: this,
            shortcutIconCls: 'feed-reader-shortcut',
            text: 'Feed Reader',
            tooltip: '<b>Feed Reader</b><br />Read feeds and search the extjs forums'
        }
    },

    createWindow : function() {
        var win = app.desktop.getWindow('feed-reader-win');
        
        if (!win) {
            /* stupid hack */
            if ( !document.getElementById( 'feed-reader-preview-tpl' ) ) {
                var ta = document.createElement( 'textarea' );
                ta.id = 'feed-reader-preview-tpl';
                ta.style.display = 'none';
                ta.value = [
                    '<div class="post-data">',
                        '<span class="post-date">{pubDate:date("M j, Y, g:i a")}</span>',
                        '<h3 class="post-title">{title}</h3>',
                        '<h4 class="post-author">by {author:defaultValue("Unknown")}</h4>',
                    '</div>',
                    '<div class="post-body">{content:this.getBody}</div>'
                ].join('\n');
                document.body.appendChild( ta );
            }
            
            var tpl = Ext.Template.from('feed-reader-preview-tpl', {
                compiled:true,
                getBody : function(v, all){
                    return Ext.util.Format.stripScripts(v || all.description);
                }
            });
            QoDesk.FeedViewer.getTemplate = function(){
                return tpl;
            }
        
            var feeds = new QoDesk.FeedPanel();
            var mainPanel = new QoDesk.MainPanel();
        
            feeds.on('feedselect', function(feed){
                mainPanel.loadFeed(feed);
            });
            
            win = app.desktop.createWindow({
                title: 'Feed Reader',
                id: 'feed-reader-win',
                iconCls: 'feed-reader-icon',
                maximizable: true,
                width: 700,
                height: 450,
                minWidth: 400,
                minHeight: 200,
                layout: 'border',
                constrain: true,
                items: [
                    feeds,
                    mainPanel
                ]
            });

            /*
                    new Ext.BoxComponent({
                        region:'north',
                        el: 'header',
                        height:32
                    }),
            */
    
            var feedlist = Ext.state.Manager.get( 'feed-reader-feeds', [
                {
                    url: 'http://feeds.feedburner.com/extblog',
                    text: 'ExtJS.com Blog'
                },
                {
                    url: 'http://extjs.com/forum/external.php?type=RSS2',
                    text: 'ExtJS.com Forums'
                },
                {
                    url: 'http://feeds.feedburner.com/ajaxian',
                    text: 'Ajaxian'
                }
            ]);

            for ( var i = 0, len = feedlist.length; i < len; i++ ) {
                feeds.addFeed(
                    feedlist[ i ],
                    ( i == 0 ? false : true ), // inactive
                    ( i == 0 ? false : true ), // prevent animation
                    true                       // don't save
                );
            }
            
            // save a copy of feedlist, or the apply from addFeed will add extra properties
            // we don't need to save
            var savelist = [];
            for ( var i = 0, len = feedlist.length; i < len; i++ ) {
                savelist.push( { url: feedlist[ i ].url, text: feedlist[ i ].text } );
            }
            Ext.state.Manager.set( 'feed-reader-feeds', savelist );

            // add some default feeds
            /*
            feeds.addFeed({
                url:'http://feeds.feedburner.com/extblog',
                text: 'ExtJS.com Blog'
            }, false, true);
        
            feeds.addFeed({
                url:'http://extjs.com/forum/external.php?type=RSS2',
                text: 'ExtJS.com Forums'
            }, true);
        
            feeds.addFeed({
                url:'http://feeds.feedburner.com/ajaxian',
                text: 'Ajaxian'
            }, true);
            */
        }
        win.show();
    }

});

// This is a custom event handler passed to preview panels so link open in a new windw
QoDesk.FeedViewer.LinkInterceptor = {
    render: function(p){
        p.body.on({
            'mousedown': function(e, t){ // try to intercept the easy way
                t.target = '_blank';
            },
            'click': function(e, t){ // if they tab + enter a link, need to do it old fashioned way
                if(String(t.target).toLowerCase() != '_blank'){
                    e.stopEvent();
                    window.open(t.href);
                }
            },
            delegate:'a'
        });
    }
};
