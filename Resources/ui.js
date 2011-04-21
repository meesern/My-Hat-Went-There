
//Self calling function for encapsulation
(function() {
  MyHat.UI = {};

  MyHat.UI.createAppWindow = function() {
    return Titanium.UI.createWindow({
      backgroundColor:'green'
    })
  };

})();

