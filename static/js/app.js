function get_user(id, td, obj) {
	return Ext.getStore('user').getById(id).get('name');
}
function get_users(arr) {
	return arr.map(get_user).join(', ');
}

function count_true (key, records){
	var i = 0,
			length = records.length,
			total = 0;

	for (; i < length; ++i) {
		if (records[i].get(key))
			++total;
	}
	return total;
}

function load_cal (records, operation, success) {
	var length = records.length,
			now = Ext.Date.now()
			i = 0
			cdate = 0;
	
	do {
		cdate = Ext.Date.clearTime(Ext.Date.parse(records[i].get('f1_start'), "d/m-Y g:i"));
		++i;
	}
	while(Ext.Date.add(cdate, Ext.Date.DAY, 1) < now);

	if (i > 0)
		i--;

	var view = Ext.getCmp('cal_grid').getView();

	//console.debug(view.getNodeByRecord(records[i]));

	console.debug(view);
	//console.debug(view.getNode(1));
	//console.debug(view.getNodes());
	//console.debug(view.all.elements);
}

function register_models_stores() {
	Ext.data.Types.INTARRAY = {
		convert: function(v, data) {
			if (v == null)
				return;

			return v.map(Ext.data.Types.INT.convert);
		}
	,	type: 'IntArray'
	};
	
	Ext.define('f1bet.grid.boolheader', {
		extend: 'Ext.grid.column.Boolean'
	, alias: 'widget.boolheader'
	, trueText: 'Ja'
	, falseText: 'Nej'
	,	undefinedText: '-'
	, constructor: function(cfg){
			this.callParent(arguments);
			ren = this.renderer;
			this.renderer = function(value) {
				if (value === null)
					value = undefined;

				return ren(value);
			}
		}
	});	

	Ext.define("user", {
		extend: "Ext.data.Model"
	, fields: [
			{name: 'id', type: 'int'}
		, {name: 'name'}
		]
	, hasMany: {model: 'bet', name: 'bets', foreignKey: 'bookie'}
	, hasMany: {model: 'bet_status', name: 'bets', foreignKey: 'user'}
	});

	Ext.define("bet", {
		extend: "Ext.data.Model"
	, fields: [
			{name: 'id', type: 'int'}
		, {name: 'bookie', type: 'int'}
		, {name: 'takers', type: 'IntArray'}
		, {name: 'description', type: 'text'}
		, {name: 'bet_start_text', type: 'text'}
		, {name: 'bet_end_text', type: 'text'}
		, {name: 'bookie_won', type: 'boolean'}
		, {name: 'house_won', type: 'boolean'}
		, {name: 'is_finished', type: 'boolean'}
		]
		, belongsTo: 'user'
	});

	Ext.define("bet_by_user", {
		extend: "Ext.data.Model"
	, idProperty: "bet_user"
	, fields: [
			{name: 'id', type: 'int'}
		, {name: 'user_name', type: 'text'}
		, {name: 'description', type: 'text'}
		, {name: 'user_lost', type: 'boolean'}
		, {name: 'twenties', type: 'int'}
		, {name: 'house_won', type: 'boolean'}
		, {name: 'is_finished', type: 'boolean'}
		, {name: 'is_paid', type: 'boolean'}
		]
		, belongsTo: 'user'
	});

	Ext.regStore(new Ext.data.Store({
		model: 'user'
	, storeId: 'user'
	, autoLoad: true
	, proxy: {
			type: 'ajax'
		, url : '/service/user'
		, reader: {
				type: 'json'
			, root: 'user'
			}
		}
	,	listeners: {
			load: function(me, recs) {
				me.findBy(function (rec){
					//console.debug(rec);
					//console.debug(rec.getValue('me'));
					return 0;
				});
				
				Ext.getStore('bet').load();
			}
		}
	}));

	Ext.regStore(new Ext.data.Store({
		model: 'bet'
	, storeId: 'bet'
//	, autoLoad: true
	, proxy: {
			type: 'ajax'
		, url : '/service/bet'
		, reader: {
				type: 'json'
			, root: 'bet'
			}
		}
	}));

	Ext.define("bet_status", {
			extend: "Ext.data.Model"
		, fields: [
				{ name: 'user', type: 'int' }
			,	{ name: 'lost', type: 'int' }
			,	{ name: 'paid', type: 'int' }
			]
		, belongsTo: 'user'
	});

	Ext.regStore('bet_by_user', {
		model: 'bet_by_user'
	, pageSize: 1000
	,	groupField: 'user_name'
	, proxy: {
			type: 'ajax'
		, url : '/service/bet_by_user'
		, reader: {
				type: 'json'
			, root: 'bet_by_user'
			}
		}
	});

	Ext.regStore('bet_status', {
		model: 'bet_status'
	, proxy: {
			type: 'ajax'
		, url : '/service/bet_status'
		, reader: {
				type: 'json'
			, root: 'bet_status'
			}
		}
	});

	Ext.define("cal", {
			extend: "Ext.data.Model"
		, fields: [ 'name', 'f1_start' ]
	});

	Ext.regStore('cal', {
		model: 'cal'
	, proxy: {
			type: 'ajax'
		, url : '/service/cal'
		, reader: {
				type: 'json'
			, root: 'cal'
			}
		}
	});
	//console.debug(Ext.getStore('cal'));
	//var abet = Ext.ModelMgr.create({bookie: 1}, 'bet');

	//console.debug(abet);

	//abet.save();
}

function get_bet_form() {
  var tform = Ext.create('Ext.form.FormPanel', {
		url:'/service/bet'
	, title: 'Lav nyt bet'
	, bodyPadding: 5
	, margins: '10'
	, width: 500
	, cls: 'bet-form'
	, fieldDefaults: {
			msgTarget: 'side'
		, labelWidth: 75
		}
	, defaultType: 'textfield'
	, defaults: {
			//anchor: '300'
		}
	, items: [{
			fieldLabel: 'Bet udbyder'
		, id: 'bookie'
		, name: 'bookie'
		, allowBlank: false
		, xtype: 'combo'
		, valueField: "id"
		, displayField: 'name'
		, queryMode: 'local'
		, typeAhead: true
		, store: 'user'
//		, listeners: {
//				blur: function (me, value) {
//					console.debug(me.store);
//					console.debug(me.getValue());
//					me.store.filterBy(function(rec) { return (rec.get('id') != me.getValue()) });
//					//me.store.filterBy(function(rec) { return (rec.get('id') != 1) });
//					//Ext.getCmp("combobox-1034").store.filterBy(function(rec) { return (rec.get('id') != 1) });
//					console.debug(me.store);
//
////					console.debug(value);
////					console.debug(value[0].get('name'));
////					console.debug(Ext.getCmp('takers'));
////					console.debug(this.up('form').getForm().findField('takers').doQuery(value[0].get('name')));
//				}
//			}
		},{
			fieldLabel: 'Beskrivelse'
		, name: 'description'
		, xtype: 'textareafield'
		, allowBlank: false
		,	width: 400
		, grow: true
		},{
			fieldLabel: 'Deltagere'
		, name: 'takers'
		, allowBlank: true
		, xtype: 'combo'
		, valueField: "id"
		, displayField: 'name'
		, queryMode: 'local'
		,	multiSelect: true
		, width: 400
		, store: 'user'
		, listeners: {
				expand: function (me) {
					var value = Ext.getCmp('bookie').getValue();

					if (!value)
						return;
						
					me.store.filterBy(function(rec) { return (rec.get('id') != value) });
					console.debug(me.store);
				}
			}
		},{
			xtype: 'fieldcontainer'
		, layout: 'hbox'
		, fieldLabel: 'Bet start'
    , combineErrors: true
		, defaults: {
				hideLabel: 'true'
			}
		, items: [{
				name: 'bet_start'
			, allowBlank: false
			, xtype: 'datefield'
			, format: 'd/m-Y'
			},{
				name: 'bet_start_time'
			, xtype: 'timefield'
			}
		]},{
			xtype: 'fieldcontainer'
		, layout: 'hbox'
		, fieldLabel: 'Bet slut'
    , combineErrors: true
		, defaults: {
				hideLabel: 'true'
			}
		, items: [{
				name: 'bet_end'
			, allowBlank: false
			, xtype: 'datefield'
			, format: 'd/m-Y'
			},{
				name: 'bet_end_time'
			, xtype: 'timefield'
			}
		]}
		]
	, buttons: [
			{ text: 'Cancel' }
		, { 
				text: 'Save'
			, handler: function() { 
					var form = this.up('form').getForm();
					form.submit({
						success: function() {
							Ext.Msg.alert('Bet gemt', "Bettet er gemt!");
							Ext.getStore('bet').load();
							form.reset();
						}
					,	failure: function(form, action) {
							console.debug(action);
							if (action.result)
								Ext.Msg.alert('Failed', action.result.msg);
						}
					}); 
				}
			}
		]
	});

	console.debug(Ext.getStore('user'));


	//tform.setValues();

	return tform;
}


Ext.onReady(function(){
	Ext.QuickTips.init();

	register_models_stores();

	var tabs = Ext.createWidget('tabpanel', {
		activeTab: 0
	,	items: [
			new Ext.grid.GridPanel({
				title: 'Se bets'
			,	store: 'bet'
			,	columnLines: true
			, columns: [
					{ text: "Better", dataIndex: 'bookie', renderer: get_user }
				,	{ text: "Deltagere", dataIndex: 'takers', flex: 1, renderer: get_users }
				, { text: "Bet", dataIndex: 'description', flex: 1 }
				, { text: "Start", dataIndex: 'bet_start_text' }
				, { text: "Slut", dataIndex: 'bet_end_text' }
				, { text: "Better vinder", dataIndex: 'bookie_won', xtype: 'boolheader' }
				, { text: "Huset!", dataIndex: 'house_won', xtype: 'boolheader' }
				, { text: "Afsluttet", dataIndex: 'is_finished', xtype: 'boolheader' }
				]
			})
		,	get_bet_form()
		,	{
				title: 'Kontigent'
			,	html: '&lt;empty panel&gt;'
			}
		,	{
				title: 'Bet overblik'
			, xtype: 'gridpanel'
			, listeners: {
					activate: function(tab){
						Ext.getStore('bet_by_user').load();
					}
				}
				,	store: "bet_by_user"
				, autoScroll: true
				,	columnLines: true
				,	features: [{
						ftype: 'groupingsummary',
						groupHeaderTpl: '{name}',
						hideGroupedHeader: true,
						enableGroupingMenu:true 
					}]
				, columns: [
						{ 
							text: "Better"
						,	dataIndex: 'user_name'
						}
					, { 
							text: "Bet"
						,	dataIndex: 'description'
						,	flex: 1
						,	summaryType: 'count'
						,	summaryRenderer: function(num) { 
								return "Bets: " + num; 
							}
						}
					, { 
							text: "Bet tabt"
						, dataIndex: 'user_lost'
						, xtype: 'boolheader'
						, summaryType: function(x) { 
								return count_true('user_lost', x); 
							}
						}
					, { 
							text: "Tabte 20ere"
						,	dataIndex: 'twenties'
						,	summaryType: 'sum'
						}
					, { 
							text: "Huset!"
						,	dataIndex: 'house_won'
						,	xtype: 'boolheader'
						,	summaryType: function(x) { 
								return count_true('house_won', x); 
							}
						}
					, { 
							text: "Betalt"
						,	dataIndex: 'is_paid'
						,	xtype: 'boolheader'
						,	summaryType: function(x) { 
								return count_true('is_paid', x);
							}
						}
					,	{ 
							text: "Afsluttet"
						,	dataIndex: 'is_finished'
						,	xtype: 'boolheader'
						,	summaryType: function(x) { 
								return count_true('is_finished', x);
							}
						}
					]
			}
		,	{
				title: 'Udeståender'
			, xtype: 'gridpanel'
			, listeners: {
					activate: function(tab){
						Ext.getStore('bet_status').load();
					}
				}
			,	store: "bet_status"
			,	columnLines: true
			, columns: [
					{ text: "User", dataIndex: 'user', flex: 1, renderer: get_user }
				,	{ text: "20ere", dataIndex: 'lost' }
				, { 
            xtype:'actioncolumn'
					, align: "center"
					,	items: [{
							icon: 'img/dankort.png'  // Use a URL in the icon config
						,	tooltip: 'Betal'
						,	handler: function(grid, rowIndex, colIndex) {
								var rec = grid.getStore().getAt(rowIndex)
										count = rec.get('lost')
										who = rec.get('user');
									;

								if (count < 1)
									return;

								Ext.Msg.prompt('Betal', 'Hvor mange tyvere lægger du? (max ' + count + ' 20ere)', function(btn, text){
										if (btn == 'ok') {
											var num = parseInt(text);
											if (isNaN(num) || num < 1 || num > count)
												return Ext.Msg.alert({
													title: 'Err'
												, msg: 'Suck this bitch'
												, icon: Ext.MessageBox.WARNING
												});

											Ext.Ajax.request({
												url: '/service/user_pays_bet'
											,	params: {
													how_many: num
												,	user: who
												}
											,	method: 'POST'
											,	success: function(req, opt) {
													console.debug(req);
												}
											});
											
											
										}
								});
							}
						}]
					}
				]
			}
		,	{
				title: 'Kalender'
			, xtype: 'gridpanel'
			,	id: 'cal_grid'
			, listeners: {
					activate: function(tab){
						var store = Ext.getStore('cal');

						//Ext.getCmp('cal_grid').on("afterlayout", function() { 
						//	console.debug('yyy');
						//	Ext.fly(view.getNode(i)).addCls('sel');
						//});

						//console.debug(Ext.getCmp('cal_grid').getView());
						//Ext.getCmp('cal_grid').getView().on("render", function() { 
						//	console.debug('xxx');
						//	Ext.fly(view.getNode(i)).addCls('sel');
						//});

						store.load(load_cal);
					}
				,	viewready: function() {
						console.debug('yyy');
	console.debug(Ext.getCmp('cal_grid'));
	console.debug(Ext.getCmp('cal_grid').getView());
						var view = Ext.getCmp('cal_grid').getView();
	console.debug(view.getNode(1));
	console.debug(view.getNodes());

						var store = Ext.getStore('cal')
							,	length = store.getCount()
							,	now = Ext.Date.now()
							,	i = 0
							,	cdate = 0;
						
						do {
							cdate = Ext.Date.clearTime(Ext.Date.parse(store.getAt(i).get('f1_start'), "d/m-Y g:i"));
							++i;
						}
						while(Ext.Date.add(cdate, Ext.Date.DAY, 1) < now);

						if (i > 0)
							i--;

						var view = Ext.getCmp('cal_grid').getView();
						Ext.fly(view.getNode(1)).addCls('sel');
					}
				}
				,	store: "cal"
				,	columnLines: true
				, columns: [
						{ text: "Start", dataIndex: 'f1_start' }
					,	{ text: "Race", dataIndex: 'name', flex: 1 }
					]
			}
		]
	, listeners: {
			afterrender: function() {
				new Ext.util.DelayedTask(tabs.setActiveTab, tabs, [4]).delay(1000);
			}
		}
	});

	new Ext.Viewport({
		layout: "border"
	, renderTo: document.body
	, items: [{
				region: "north"
			, border: false
			//, html: 'Formel1 bets'
			, contentEl: 'header'
			, height: 40
		}
//		,{
//			region: "west"
//		, collapsible: true
//		, width: 200
//		, title: 'Menu'
//		, titleCollapse: true
//		, contentEl: 'menu'
//		}
		,{
			region: "center"
		, border: false
		, layout: 'fit'
		, flex: 1
		, items: [
				tabs
			]
		}
	]});
});
