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

QoDesk.HuluPlayer = Ext.extend(Ext.app.Module, {

    moduleType : 'app',
    moduleId : 'hulu-player',
    cards: [
        'hulu-player-card-0', // nav
        'hulu-player-card-1',  // grid
        'hulu-player-card-2'  // player
    ],
    
    init : function() {
        this.launcher = {
            handler: this.createWindow,
            iconCls: 'hulu-player-icon',
            scope: this,
            shortcutIconCls: 'hulu-player-shortcut',
            text: 'Hulu TV',
            tooltip: '<b>Hulu TV</b><br />Play TV episodes, movies, and clips from Hulu.com'
        }
    },

    createWindow : function() {
        var win = app.desktop.getWindow('hulu-player-win');
        
        if (!win) {
            var contentPanel = new Ext.Panel({
            
                activeItem: 0,
                border: false,
                id: 'hulu-player-content-panel',
                layout: 'card',
                items: [
                    new QoDesk.HuluPlayer.NavPanel({owner: this, id: 'hulu-player-card-0'}),
                    new QoDesk.HuluPlayer.GridPanel({owner: this, id: 'hulu-player-card-1'}),
                    new QoDesk.HuluPlayer.PlayerPanel({owner: this, id: 'hulu-player-card-2'})
                ],
                tbar: [{
                    disabled: true,
                    handler: this.navHandler.createDelegate(this, [-1]),
                    id: 'back',
                    scope: this,
                    text: 'Back',
                    iconCls: 'hulu-player-back-button'
                },{
                    disabled: true,
                    handler: this.navHandler.createDelegate(this, [1]),
                    id: 'next',
                    scope: this,
                    text: 'Forward',
                    iconCls: 'hulu-player-forward-button'
                },( new Ext.Toolbar.Fill() ),{
                    handler: this.viewCard.createDelegate(this, ['hulu-player-card-1',{ load: '/queue/706264', loadMsg: 'Xantus\' Queue' }]),
                    id: 'xantus-queue',
                    scope: this,
                    text: 'Xantus\' Queue',
                    iconCls: 'hulu-player-favorite-button'
                },{
                    handler: this.viewCard.createDelegate(this, ['hulu-player-card-1',{ load: '/starred', loadMsg: 'Your Starred Videos' }]),
                    id: 'my-starred',
                    scope: this,
                    text: 'Starred',
                    iconCls: 'hulu-player-starred-button'
                }, '-',{
                    xtype: 'textfield',
                    emptyText:'Search...',
                    selectOnFocus: true,
                    width:135,
                    maxLength: 150,
                    minLength: 1,
                    stateId: 'hulu-player-searchtext',
                    enableKeyEvents: true,
                    listeners: {
                        keydown: this.searchHandler,
                        scope: this
                    }
                }, ' ']
            });


            win = app.desktop.createWindow({
                title: 'Hulu TV',
                id: 'hulu-player-win',
                iconCls: 'hulu-player-icon',
                maximizable: true,
                width: 600,
                height: 400,
                minWidth: 400,
                minHeight: 200,
                layout: 'fit',
                constrain: true,
                items: contentPanel,
                bbar: new Ext.StatusBar({
                    defaultText: 'Done.',
                    id: 'hulu-player-win-statusbar'
                })
            });

            win.contentPanel = contentPanel;
            win.layout = win.contentPanel.getLayout();
            win.cardHistory = [ 'hulu-player-card-0' ];
            win.titleHistory = [ 'Hulu TV' ];
            win.statusHistory = [ 'Done.' ];
        }
        
        win.show();
    },

    searchHandler: function(f,e) {
        if ( e.keyCode && e.keyCode == 13 ) {
            e.stopEvent();
            var txt = f.getValue();
            if ( !txt || txt.length == 0 )
                return;
            this.viewCard('hulu-player-card-1',{
                load: '/search/'+encodeURIComponent(txt),
                title: 'Search for "'+txt+'"',
                loadMsg: 'Search Results for "'+txt+'"'
            });
        }
    },

    handleButtonState : function() {
        var win = app.desktop.getWindow('hulu-player-win');
        var cards = win.cardHistory, activeId = win.layout.activeItem.id,
            items = win.contentPanel.getTopToolbar().items, back = items.get(0), next = items.get(1);
        
        for (var i = 0, len = cards.length; i < len; i++) {
            if (cards[i] === activeId) {
                if (i <= 0) {
                    back.disable();
                    next.enable();
                } else if (i >= (len-1)) {
                    back.enable();
                    next.disable();
                } else {
                    back.enable();
                    next.enable();
                }
                break;
            }
        }
    },
    
    navHandler : function(index) {
        var win = app.desktop.getWindow('hulu-player-win');
        var cards = win.cardHistory,
            titles = win.titleHistory,
            stati = win.statusHistory,
            activeId = win.layout.activeItem.id,
            title,
            status,
            nextId;
        
        for (var i = 0, len = cards.length; i < len; i++) {
            if (cards[i] === activeId) {
                nextId = cards[i+index];
                title = titles[i+index];
                status = stati[i+index];
                break;
            }
        }
        // should nav back, index: -1 cause the store to stop what its doing
        win.layout.setActiveItem(nextId);
        if ( title )
            win.setTitle(title);
        if ( status ) {
            var statusBar = Ext.getCmp('hulu-player-win-statusbar');
            if ( statusBar ) {
                statusBar.clearStatus(); // clear busy
                if ( status == 'hide' )
                    statusBar.hide();
                else {
                    statusBar.show();
                    statusBar.setStatus({ text: status });
                }
            }
        }
        this.handleButtonState();
    },

    viewCard : function(card,data) {
        var win = app.desktop.getWindow('hulu-player-win');
        win.layout.setActiveItem(card);
        var activeCard = Ext.getCmp(card);
        if ( data && activeCard.setData )
            activeCard.setData( data );
//        if (win.cardHistory.length > 2)
//            win.cardHistory.pop();
//        win.cardHistory.push(card);
        var n = 0;
        if ( card.match( /card-(\d+)/ ) ) {
            n = RegExp.$1;
        }
        win.cardHistory[n] = card;
        this.handleButtonState();
    }
    
});

QoDesk.HuluPlayer.NavPanel = function(config) {
    this.owner = config.owner;
    
    QoDesk.HuluPlayer.NavPanel.superclass.constructor.call(this, {
        autoScroll: true,
        bodyStyle: 'padding:15px',
        border: false,
        html: '<a href="http://hulu.com/" target="_blank_" onclick="javascript:app.gaPageview(\'/out/hulu.com\');"><img src="'+Ext.BLANK_IMAGE_URL+'" class="hulu-player-nav-header"/></a> \
            <table border="0"><tr><td> \
            <ul class="hulu-player-nav-panel"> \
                <li> \
                    <img src="'+Ext.BLANK_IMAGE_URL+'" class="hulu-player-card-shortcut"/> \
                    <a id="hulu-recent-episodes" href="#">Recently Added Episodes</a><br /> \
                </li> \
                <li> \
                    <img src="'+Ext.BLANK_IMAGE_URL+'" class="hulu-player-card-shortcut"/> \
                    <a id="hulu-recent-shows" href="#">Recently Added shows</a><br /> \
                </li> \
                <li> \
                    <img src="'+Ext.BLANK_IMAGE_URL+'" class="hulu-player-card-shortcut"/> \
                    <a id="hulu-recent-movies" href="#">Recently Added movies</a><br /> \
                </li> \
                <li> \
                    <img src="'+Ext.BLANK_IMAGE_URL+'" class="hulu-player-card-shortcut"/> \
                    <a id="hulu-highest-rated" href="#">Highest Rated Videos</a><br /> \
                </li> \
                <li> \
                    <img src="'+Ext.BLANK_IMAGE_URL+'" class="hulu-player-card-shortcut"/> \
                    <a id="hulu-popular-today" href="#">Most Popular Videos Today</a><br /> \
                    <!--span>Popular Shows for today</span--> \
                </li> \
            </ul> \
            </td><td><img src="'+Ext.BLANK_IMAGE_URL+'" width="50" /></td><td> \
            <ul class="hulu-player-nav-panel"> \
                <li> \
                    <img src="'+Ext.BLANK_IMAGE_URL+'" class="hulu-player-card-shortcut"/> \
                    <a id="hulu-popular-week" href="#">Most Popular Videos This Week</a><br /> \
                </li> \
                <li> \
                    <img src="'+Ext.BLANK_IMAGE_URL+'" class="hulu-player-card-shortcut"/> \
                    <a id="hulu-popular-month" href="#">Most Popular Videos This Month</a><br /> \
                </li> \
                <li> \
                    <img src="'+Ext.BLANK_IMAGE_URL+'" class="hulu-player-card-shortcut"/> \
                    <a id="hulu-popular-all" href="#">Most Popular Videos of All Time</a><br /> \
                </li> \
                <li> \
                    <img src="'+Ext.BLANK_IMAGE_URL+'" class="hulu-player-card-shortcut"/> \
                    <a id="hulu-soon-to-expire" href="#">Soon-To-Expire Videos</a><br /> \
                </li> \
                <li> \
                    <img src="'+Ext.BLANK_IMAGE_URL+'" class="hulu-player-card-shortcut"/> \
                    <a id="hulu-days-of-summer" href="#">Hulu <i>Days of Summer</i></a><br /> \
                </li> \
            </ul> \
            </td></tr></table>',
        cls: config.id,
        id: config.id
    });
    
    this.actions = {
        'hulu-recent-episodes' : function(owner) {
            owner.viewCard('hulu-player-card-1',{
                load: '/recent/episode',
                loadMsg: 'Recently added episodes'
            });
        },
        
        'hulu-recent-shows' : function(owner) {
            owner.viewCard('hulu-player-card-1',{
                load: '/recent/shows',
                loadMsg: 'Recently added shows'
            });
        },
        
        'hulu-recent-movies' : function(owner) {
            owner.viewCard('hulu-player-card-1',{
                load: '/recent/movies',
                loadMsg: 'Recently added movies'
            });
        },
        
        'hulu-highest-rated' : function(owner) {
            owner.viewCard('hulu-player-card-1',{
                load: '/recent/highest_rated/videos',
                loadMsg: 'Highest rated videos'
            });
        },
        
        'hulu-popular-today' : function(owner) {
            owner.viewCard('hulu-player-card-1',{
                load: '/popular/videos/today',
                loadMsg: 'Most popular videos today'
            });
        },

        'hulu-popular-week' : function(owner) {
            owner.viewCard('hulu-player-card-1',{
                load: '/popular/videos/this_week',
                loadMsg: 'Most popular videos this week'
            });
        },
        
        'hulu-popular-month' : function(owner) {
            owner.viewCard('hulu-player-card-1',{
                load: '/popular/videos/this_month',
                loadMsg: 'Most popular videos this month'
            });
        },

        'hulu-popular-all' : function(owner) {
            owner.viewCard('hulu-player-card-1',{
                load: '/popular/videos/all_time',
                loadMsg: 'Most popular videos of all time'
            });
        },
        
        'hulu-soon-to-expire' : function(owner) {
            owner.viewCard('hulu-player-card-1',{
                load: '/popular/expiring/videos',
                loadMsg: 'Soon-to-expire videos'
            });
        },
        
        'hulu-days-of-summer' : function(owner) {
            owner.viewCard('hulu-player-card-1',{
                load: '/calendar',
                loadMsg: 'Hulu Days of Summer'
            });
        },

        'xantus-queue' : function(owner) {
            owner.viewCard('hulu-player-card-1',{
                load: '/queue/706264',
                loadMsg: 'My Queue (xantus)'
            });
        }
        
    };
};

Ext.extend(QoDesk.HuluPlayer.NavPanel, Ext.Panel, {

    afterRender : function() {
        this.body.on({
            'mousedown': {
                fn: this.doAction,
                scope: this,
                delegate: 'a'
            },
            'click': {
                fn: function(e,t) {
                    if ( this.actions[t.id] )
                        e.stopEvent();
                },
                scope: this,
//                preventDefault: true,
                delegate: 'a'
            }
        });
        
        QoDesk.HuluPlayer.NavPanel.superclass.afterRender.apply(this,arguments);
    },
    
    doAction : function(e, t) {
        var act = this.actions[t.id];
        /* prevent the selected link box from surrounding the link */
        e.stopEvent();
        if ( act )
            act(this.owner);
    }

});

QoDesk.HuluPlayer.GridPanel = function(config) {
    this.owner = config.owner;

    var grid = this.createGrid(config.id+'-grid');

    this.descQtipTpl = new Ext.XTemplate(
        '<tpl for=".">'
        //,'<div class=&quot;hulu-player-quicktip&quot;>{[Ext.util.Format.htmlEncode(values.description)]}</div>'
        ,'<div class=&quot;hulu-player-quicktip&quot;>'
        ,'<h3>{[Ext.util.Format.htmlEncode(values.title)]}</h3>'
        ,'{description}</div>'
        ,'</tpl>'
    );

    QoDesk.HuluPlayer.GridPanel.superclass.constructor.call(this, {
        autoScroll: true,
        border: false,
        layout: 'fit',
        constrain: true,
        items: grid,
        cls: config.id,
        id: config.id
    });

};

Ext.extend(QoDesk.HuluPlayer.GridPanel, Ext.Panel, {

    renderDesc: function(val, cell, record) {
        var qtip = this.descQtipTpl.apply({
            title: record.get('title'),
            description: record.get('description')
        });
        return '<div qtip="' + qtip +'">' + val + '</div>';
    },

    createGrid: function(id) {
        var reader = new Ext.data.JsonReader({
            root: 'shows',
            fields: [
                {name: 'id'},
                {name: 'starred'},
                {name: 'show'},
                {name: 'title'},
                {name: 'season'},
                {name: 'episode'},
                {name: 'type'},
                {name: 'link'},
                {name: 'description'},
                {name: 'pubDate', dateformat: 'D, d M Y G:H:i:s O'},
                {name: 'mediaThumbnail'},
                {name: 'mediaCredit'},
                {name: 'mediaPlayer'}
            ]
        });
    
        var store = this.store = new Ext.data.GroupingStore({
            reader: reader,
            url: app.connection,
            baseParams: {
                moduleId: 'hulu-player',
                task: 'fetch',
                what: '/recent/episode'
            },
            sortInfo: { field: 'episode', direction: 'DESC' },
            groupField: 'show'
        });

        var checkColumn = new Ext.grid.StarColumn({
            id: 'starred',
            header: "Star",
            dataIndex: 'starred',
            sortable: true,
            width: 42,
            url: app.connection,
            moduleId: 'hulu-player'
        });

        var grid = new Ext.grid.GridPanel({
            id: id,
            stateId: id,
            store: store,
            border : false,
            columns: [
                checkColumn,
                {id: 'show', header: "Show", width: 132, sortable: true, dataIndex: 'show'},
                {id: 'title', header: "Title", width: 250, sortable: false, dataIndex: 'title',renderer:this.renderDesc.createDelegate(this)},
                {id: 'season', header: "Season", width: 64, sortable: true, type: 'int', dataIndex: 'season'},
                {id: 'episode', header: "Episode", width: 64, sortable: true, type: 'int', dataIndex: 'episode'},
//                {header: "Type", width: 30, sortable: true, dataIndex: 'type'},
//                {header: "Publisher", width: 40, sortable: true, dataIndex: 'mediaCredit'},
                {id: 'pubDate', header: "Date", width: 105, type: 'date', sortable: true, dataIndex: 'pubDate', renderer: Ext.util.Format.dateRenderer('D, d M Y')}
            ],
            view: new Ext.grid.GroupingView({
                forceFit: true,
                groupTextTpl: '{text} ({[values.rs.length]} {[values.rs.length > 1 ? "Videos" : "Video"]})'
            }),
            emptyText: 'There are no videos for the current search criteria',
            deferEmptyText: true,
            stripeRows       : true,
            plugins: checkColumn,
            autoExpandColumn : 'title'
        });
    
        store.on('load', function(o) {
            var statusBar = Ext.getCmp('hulu-player-win-statusbar');
            if ( !statusBar )
                return;
            var win = app.desktop.getWindow('hulu-player-win');
            var status;
            if ( o.totalLength == 0 ) 
                status = 'No results';
            else
                status = o.totalLength + ' result' + ( o.totalLength > 1 ? 's' : '' );
//            if (win.statusHistory.length > 2)
//                win.statusHistory.pop();
//            win.statusHistory.push(status);
            win.statusHistory[1] = status;
            statusBar.clearStatus(); // clear busy
            statusBar.show();
            statusBar.setStatus({ text: status });
        },this);
        
        store.on('loadexception', function(s,r,o) {
            var statusBar = Ext.getCmp('hulu-player-win-statusbar');
            if ( !statusBar )
                return;
            var data = {};
            var reason = 'Unknown';
            if ( o && o.responseText && ( data = Ext.decode(o.responseText) ) ) {
                if ( !data.success )
                    reason = 'Failed to load data from hulu.com';
                if ( data.error )
                    reason = data.error;
            }
            var win = app.desktop.getWindow('hulu-player-win');
            var status = 'Error: '+reason;
//            if (win.statusHistory.length > 2)
//                win.statusHistory.pop();
//            win.statusHistory.push(status);
            win.statusHistory[1] = status;
            statusBar.show();
            statusBar.clearStatus(); // clear busy
            statusBar.setStatus({ text: status });
        },this);
    
        grid.on('rowdblclick', function(grid, rowIndex, eventObj) {
            var record = grid.getStore().getAt(rowIndex);
    
            /* find an already opened window and close it */
            /*
            var fwin = app.desktop.getWindow('hulu-flash-player-win');
            if ( fwin )
                fwin.close();
            var win = app.desktop.getWindow('hulu-player-win');
            win.minimize();
            */
            var embed = record.get('mediaPlayer');
            var title = record.get('title');
            if ( record.get('show') )
                title = record.get('show') + ': ' + title;
            this.owner.viewCard('hulu-player-card-2',{
                load: embed,
                title: title
            });
            /* open the new video player */
            /*
            var playerWin = app.desktop.createWindow({
                title: 'Hulu: '+title,
                id: 'hulu-flash-player-win',
                iconCls: 'hulu-player-icon',
                hideMode: 'display',
                maximizable: true,
                width: 500,
                height: 300,
                minWidth: 300,
                minHeight: 200,
                layout: 'fit',
                constrain: true,
                bodyStyle:'padding:0px; width:100%; height:100%;',
                buttonAlign:'center',
                items: new Ext.Panel({
                    html: '<object width="100%" height="100%"><param name="movie" value="'+embed+'"></param>\
                    <embed src="'+embed+'" type="application/x-shockwave-flash" width="100%" height="100%"></embed></object>'
                })
            });
            playerWin.on('close', function() {
                var win = app.desktop.getWindow('hulu-player-win');
                if ( win )
                    win.show();
            }, this );
            playerWin.show();
            */
        },this);

        return grid;
    },

    setData: function(data) {
        if ( data.load ) {
            if ( !( data.load.indexOf('http:/') != -1 ) )
                app.gaPageview("/app/hulu-player"+data.load);
            if ( !data.title )
                data.title = data.loadMsg;
            if ( data.title ) {
                var win = app.desktop.getWindow('hulu-player-win');
                var title = 'Hulu TV: '+data.title;
///                if (win.titleHistory.length > 2)
//                    win.titleHistory.pop();
//                win.titleHistory.push(title);
                win.titleHistory[1] = title;
                win.setTitle(title);
            }
            this.store.baseParams.what = data.load;
            var statusBar = Ext.getCmp('hulu-player-win-statusbar');
            if ( statusBar ) {
                if ( data.loadMsg )
                    statusBar.showBusy({text:'Loading: '+data.loadMsg});
                else
                    statusBar.showBusy();
            }
            this.store.removeAll();
            this.store.load();
        }
    }

});

QoDesk.HuluPlayer.PlayerPanel = function(config) {
    this.owner = config.owner;

    QoDesk.HuluPlayer.PlayerPanel.superclass.constructor.call(this, {
        layout: 'fit',
//        constrain: true,
        border: false,
        bodyStyle:'padding:0px; width:100%; height:100%; background-color:#000',
        html: '<div>&nbsp;</div>',
        cls: config.id,
        id: config.id
    });

};

Ext.extend(QoDesk.HuluPlayer.PlayerPanel, Ext.FlashPanel, {

    setData: function(data) {
        if ( data.load ) {
            if ( !( data.load.indexOf('http:/') != -1 ) )
                app.gaPageview("/app/hulu-player/"+data.load);
            if ( !data.title )
                data.title = data.loadMsg;
            var win = app.desktop.getWindow('hulu-player-win');
            if ( data.title ) {
                var title = 'Hulu TV: '+data.title;
//                if (win.titleHistory.length > 2)
//                    win.titleHistory.pop();
//                win.titleHistory.push(title);
                win.titleHistory[2] = title;
                win.setTitle(title);
            }
//            if (win.statusHistory.length > 2)
//                win.statusHistory.pop();
//            win.statusHistory.push('hide');
            win.statusHistory[2] = 'hide';
            var statusBar = Ext.getCmp('hulu-player-win-statusbar');
            if ( statusBar )
                statusBar.hide();
            this.body.update('<object width="100%" height="100%"><param name="movie" value="'+data.load+'">\
                    <param name="allowfullscreen" value="true"></param>\
                    <param name="allowscriptaccess" value="never"></param>\
                    <param name="wmode" value="transparent"></param>\
                    <param name="quality" value="high"></param>\
                    <param name="bgcolor" value="#000"></param>\
                    <embed src="'+data.load+'" type="application/x-shockwave-flash" width="100%" height="100%" allowfullscreen="true"\
                    allowscriptaccess="never" wmode="transparent" bgcolor="#000" quality="high"></embed>\
                    </object>');
        }
    }

});

Ext.grid.StarColumn = function(config) {
    Ext.apply(this, config);
    if (!this.id)
        this.id = Ext.id();
    this.renderer = this.renderer.createDelegate(this);
};

Ext.grid.StarColumn.prototype = {

    init : function( grid ) {
        this.grid = grid;
        this.grid.on('render', function() {
            this.grid.getView().mainBody.on('mousedown', this.onMouseDown, this);
        }, this);
    },

    onMouseDown : function(e, t) {
        if (t.className && t.className.indexOf('x-grid3-cc-'+this.id) != -1) {
            e.stopEvent();
            var index = this.grid.getView().findRowIndex(t);
            var record = this.grid.store.getAt(index);
            record.set(this.dataIndex, !record.data[this.dataIndex]);
            Ext.Ajax.request({
                url: this.url,
                params: {
                    moduleId: this.moduleId,
                    task: ( record.data[this.dataIndex] ? 'star' : 'unstar' ),
                    what: record.get('id'),
                    record: ( record.data[this.dataIndex] ? Ext.encode( record.json ) : undefined )
                },
                success: function(o) {
                    if ( o && o.responseText && Ext.decode(o.responseText).success )
                        record.commit();
                },
                failure: function() {
                    
                },
                scope: this
             });
        }
    },

    renderer : function(v, p, record) {
        p.css += ' x-grid3-check-col-td'; 
        //return '<div class="x-grid3-check-col'+(v?'-on':'')+' x-grid3-cc-'+this.id+'">&#160;</div>';
        return '<div class="hulu-player-check-col'+(v?'-on':'')+' x-grid3-cc-'+this.id+'">&#160;</div>';
    }

};

