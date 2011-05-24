function get_user(id, td, obj) {
	return Ext.getStore('user').getById(id).get('name');
}
function get_users(arr) {
	return arr.map(get_user).join(', ');
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
		, {name: 'paid', type: 'boolean'}
		]
		, belongsTo: 'user'
	});

	Ext.define("user", {
		extend: "Ext.data.Model"
	, fields: [
			{name: 'id', type: 'int'}
		, {name: 'name'}
		]
	, hasMany: {model: 'bet', name: 'bets', foreignKey: 'bookie'}
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
	}));

	Ext.regStore(new Ext.data.Store({
		model: 'bet'
	, storeId: 'bet'
	, autoLoad: true
	, proxy: {
			type: 'ajax'
		, url : '/service/bet'
		, reader: {
				type: 'json'
			, root: 'bet'
			}
		}
	}));
		Ext.define("cal", {
				extend: "Ext.data.Model"
			, fields: [ 'name', 'start' ]
		})

	Ext.regStore('cal', {
		model: 'cal'
	, proxy: {
			type: 'ajax'
		, url : '/service/cal'
		, autoLoad: true
		, reader: {
				type: 'json'
			, root: 'cal'
			}
		}
	});
	console.debug(Ext.getStore('cal'));
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

	return tform;
}


Ext.onReady(function(){
	Ext.QuickTips.init();

	register_models_stores();

	var tabs = Ext.createWidget('tabpanel', {
		items: [
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
				, { text: "Betalt", dataIndex: 'paid', xtype: 'boolheader' }
				]
			})
		,	get_bet_form()
		,	{
				title: 'Kontigent'
			,	html: '&lt;empty panel&gt;'
			}
		,	{
				title: 'Status'
			,	html: '&lt;empty panel&gt;'
			}
		,	{
				title: 'Kalender'
			, items: [
					new Ext.grid.GridPanel({
						title: 'Se bets'
					, store: "cal"
					,	columnLines: true
					, columns: [
							{ text: "Race", dataIndex: 'name', flex: 1 }
						,	{ text: "Start", dataIndex: 'start' }
						]
					})
				]
			}
		]
	, listeners: {
			afterrender: function() {
				//tabs.setActiveTab(1);
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
