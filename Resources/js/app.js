
//Create js controller object
AppCtl = {};

// Track preferences
AppCtl.db = Titanium.Database.open("MyHat");

// global notification object
AppCtl.notification = Titanium.Notification.createNotification(window);

// Factory Defaults
AppCtl.baseDir = "../../My Hat gps";
AppCtl.ocReportBy = "xmpp";
AppCtl.ocServer = "greenbean";
AppCtl.ocUser   = "hatlocation";
AppCtl.ocPassword  = "jabber";
AppCtl.ocDestination = "whathappened";

// Hash for working globals
AppCtl.hash = new Array();
AppCtl.uploads = 0;

$(document).ready( MhUi.Loaded );


AppCtl.open_file_dialog_callback = function(filenames) {
  filenames.forEach( function(file) {
  
    Titanium.API.log("--------file: " + file); 
    MhUi.ViewUpload(file);
    //To Ruby
    myHat_uploadFile(file);
  });
} 


// Reporting Type
AppCtl.getReportType = function()
{
	return AppCtl.getOneLineDb('RTYPE', AppCtl.ocReportBy);
};
AppCtl.setReportType = function(val)
{
	AppCtl.setOneLineDb('RTYPE',val);
};

// Server Name
AppCtl.getOcServer = function()
{
	return AppCtl.getOneLineDb('OCSERVER', AppCtl.ocServer);
}
AppCtl.setOcServer = function(val)
{
	AppCtl.setOneLineDb('OCSERVER',val);
};

// Server Jid Name
AppCtl.getOcDest = function()
{
	return AppCtl.getOneLineDb('OCDEST', AppCtl.ocDestination);
}
AppCtl.setOcDest = function(val)
{
	AppCtl.setOneLineDb('OCDEST',val);
};

//
//  Persist a value in a one line database table
//
AppCtl.getOneLineDb = function(table, init)
{
	var val = init;
	try
	{
		var dbrow = AppCtl.db.execute('SELECT * from '+table);
		if (dbrow.isValidRow())
		{
			val = dbrow.fieldByName('value');
		}
	}
	catch (e)
	{
		AppCtl.db.execute('CREATE TABLE '+table+' (value TEXT)');;
	}
	return val;
};

//
//  Persist a value in a one line database table
//
AppCtl.setOneLineDb = function(table, val)
{
	function insertValues()
	{
		AppCtl.db.execute('INSERT INTO '+table+' (value)  VALUES (?)',val);
	};

	try
	{
		AppCtl.db.execute('DELETE FROM '+table);
		insertValues();
	}
	catch(e)
	{
		AppCtl.db.execute('CREATE TABLE '+table+' (value TEXT)');
		insertValues();
	}
};

