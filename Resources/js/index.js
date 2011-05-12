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
    AppReport("Waiting for file to upload");

};



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

