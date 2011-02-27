// Path to the blank image should point to a valid location on your server
//Ext.BLANK_IMAGE_URL = '/extjs4/resources/images/default/s.gif';

Ext.onReady(function(){
	Ext.QuickTips.init();

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
		}
		,{
			region: "center"
			, border: false
			, contentEl: 'content'
		}
	]});
});
