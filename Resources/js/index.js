// define global object
MhUi = {};

// User interactions on index page can go here

MhUi.Loaded = function()
{
    Titanium.API.log("*** DOM loaded ***");

    AppCtl.uploads = 0;

    //requiring jquery
    var button = $('#b1');
    if (button == null) alert("Element b1 not found");
    button.click(MhUi.ChooseFile);

    //Add configuration options
    var cfg = $('#oc-config-content');

    cfg.append("\
    <fieldset> \
    <legend> Reporting Type </legend> \
      <p><label> <input id='xmpp-radio' type=radio name=type/> XMPP </label></p> \
      <p><label> <input id='html-radio' type=radio name=type/> HTML </label></p> \
    </fieldset> \
    <fieldset>  \
    <legend> JID: Name@Server </legend> \
      <p><label> Name </label> <input id='dest' type=text name=dest/></p> \
      <p><label> Server Name </label> <input id='server' type=text name=server/></p> \
    </fieldset> \
    <fieldset>  \
    <legend> HTTP Port </legend> \
      <p><label> Port </label> <input id='port' type=text name=port/></p> \
    </fieldset> \
    ");

    var sel = (AppCtl.getReportType() == 'xmpp')?'#xmpp-radio':'#html-radio'
    $(sel).attr('checked','true');

    $('#xmpp-radio').change(function(){MhUi.ReportType('xmpp')});
    $('#html-radio').change(function(){MhUi.ReportType('html')});

    $('#dest').attr('value',AppCtl.getOcDest());
    $('#dest').change(function(){AppCtl.setOcDest($('#dest').attr('value'))});
    $('#server').attr('value',AppCtl.getOcServer());
    $('#server').change(function(){AppCtl.setOcServer($('#server').attr('value'))});

    $('#port').attr('value',AppCtl.getPort());
    $('#port').change(function(){AppCtl.setPort($('#port').attr('value'))});

    AppReport("Waiting for file to upload");

};



MhUi.ReportType = function(type)
{
  if (type == 'html')
    AppCtl.ocReportBy = "html";
  else
    AppCtl.ocReportBy = "xmpp";
  //Store for another time
  AppCtl.setReportType(AppCtl.ocReportBy);
}



MhUi.ChooseFile = function()
{
  Titanium.UI.openFileChooserDialog( AppCtl.open_file_dialog_callback, {
    multiple: true,
    title: "Select GPS file",
    types: ['gpx'],
    typesDescription: "GPS",
    path: ".",
    });
};



MhUi.ViewUpload = function(file)
{
   Titanium.API.log(" add view for file: " + file); 

   AppCtl.uploads++;
   //link the filename to the progress bar to get it back later
   id = "upload_" + AppCtl.uploads;
   AppCtl.hash[file] = id;

   //create a new display box for this upload
   $('<div/>', {'class': 'upview', id: id}).appendTo('#inner');

   $("<p>Uploading: <span class='filename'>" + basename(file)+"</span></p>").appendTo('#'+id);
   
   //create a progress bar
   $('#'+id).append("<div class='progressbar'></div>");
   
   // Test (the space matters)
   $('#'+id + ' .progressbar').progressbar({ value: 20 });
};



MhUi.SetProgress = function(file, progress)
{
   id = AppCtl.hash[file]

   $('#'+id+' .progressbar').progressbar({ value: progress });
};



function AppReport(message)
{
  $("<p>"+message+"</p>").appendTo('#status')
}

