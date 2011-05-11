/*
var MyHat = {};
Titanium.include('ui.js');  //Ti not valid, inclide not valid!

var win = MyHat.UI.createAppWindow();
win.open();

//CommonJs require example
var logger = require('logger')  //Require not known either!
logger.info("Starting");
*/

$(document).ready( Loaded );

var Hash = new Array();

open_file_dialog_callback = function(filenames) {
  //back to Ruby
  fileChosen(filenames);
} 

function ChooseFile() 
{
  Titanium.UI.openFileChooserDialog( open_file_dialog_callback, {
    multiple: true,
    title: "Select GPS file",
    types: ['gpx'],
    typesDescription: "GPS",
    path: ".",
    });
};


function Loaded()
{
    Titanium.API.log("*** DOM loaded ***");

    Hash['uploaded'] = 0;


    //requiring jquery
    var button = $('#b1');
    //var button = document.getElementById('b1');
    if (button == null) alert("Element b1 not found");
    button.click(ChooseFile);
    AppReport("Waiting for file to upload");

};


function ViewUpload(file)
{
   Titanium.API.log(" add view for file: " + file); 

   Hash['uploaded']++;
   //link the filename to the progress bar to get it back later
   id = "upload_" + Hash['uploaded'];
   Hash[file] = id;

   //create a new display box for this upload
   $('<div/>', {'class': 'upview', id: id}).appendTo('#inner');

   $("<p>Uploading: <span class='filename'>" + basename(file)+"</span></p>").appendTo('#'+id);
   
   //create a progress bar
   $('#'+id).append("<div class='progressbar'></div>");
   
   // Test (the space matters)
   $('#'+id + ' .progressbar').progressbar({ value: 20 });
};


function SetProgress(file, progress)
{
   id = Hash[file]

   $('#'+id+' .progressbar').progressbar({ value: progress });
};

function AppReport(message)
{
  $("<p>"+message+"</p>").appendTo('#status')
}

