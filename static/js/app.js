function register_models_stores() {
	Ext.regModel('bet', {
		fields: [
			{name: 'id', type: 'int'}
		, {name: 'bookie', type: 'int'}
		]
		, proxy: {
				type: 'rest'
			, url : '/service/bet'
			, reader: {
					type: 'json'
				, root: 'bet'
				}
			}
	});

	Ext.regModel('user', {
		fields: [
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
	, autoLoad: false
	}));

	//var abet = Ext.ModelMgr.create({bookie: 1}, 'bet');

	//console.debug(abet);

	//abet.save();
}

function get_bet_form() {
  var tform = Ext.create('Ext.form.FormPanel', {
		url:'save-form.php'
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
			anchor: '100%'
		}
	, items: [{
			fieldLabel: 'Bet udbyder'
		, name: 'bookie'
		, allowBlank: false
		, xtype: 'combo'
		, valueField: "id"
		, displayField: 'name'
		, queryMode: 'local'
		, typeAhead: true
		, store: 'user'
		},{
			fieldLabel: 'Beskrivelse'
		, name: 'description'
		, xtype: 'textareafield'
		, allowBlank: false
		, grow: true
		},{
			fieldLabel: 'Bet start'
		, name: 'bet_start'
		, allowBlank: false
		, xtype: 'datefield'
		},{
			fieldLabel: 'Bet slut'
		, name: 'bet_end'
		, allowBlank: false
		, xtype:'datefield'
		}
		]
	, buttons: [
			{ text: 'Cancel' }
		, { text: 'Save' }
		]
	});

	return tform;
}


Ext.onReady(function(){
	Ext.QuickTips.init();

	register_models_stores();

	new Ext.Viewport({
		layout: "border"
	, items: [{
				region: "north"
			, border: false
			, contentEl: 'header'
		}
		,{
			region: "west"
		, collapsible: true
		, width: 200
		, title: 'Menu'
		, titleCollapse: true
		, contentEl: 'menu'
		, items: [
			]
		}
		,{
			region: "center"
		, border: false
		, contentEl: 'content'
		, items: [
			get_bet_form()
		]
		}
	]});
});
