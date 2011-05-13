
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


//
// get report type from DB
//
AppCtl.getReportType = function()
{
	var reportType = AppCtl.ocReportBy;
	try
	{
		var dbrow = AppCtl.db.execute('SELECT * from REPORTT');
		if (dbrow.isValidRow())
		{
			reportType = dbrow.fieldByName('report');
		}
	}
	catch (e)
	{
		AppCtl.db.execute('CREATE TABLE REPORTT (report TEXT)');;
	}
	return reportType;
};

//
// set permissions
//
AppCtl.setReportType = function(type)
{
	function insertValues()
	{
		AppCtl.db.execute('INSERT INTO REPORTT (report)  VALUES (?)',type);
	};

	try
	{
		AppCtl.db.execute('DELETE FROM REPORTT');
		insertValues();
	}
	catch(e)
	{
		AppCtl.db.execute('CREATE TABLE REPORTT (report TEXT)');
		insertValues();
	}
};

