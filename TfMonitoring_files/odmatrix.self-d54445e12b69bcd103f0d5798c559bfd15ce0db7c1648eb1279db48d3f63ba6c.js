(function() {
  $(document).on('page:change', function() {
    return $('#genODButton').click(function() {
      return $('#ODMatrixPanel').toggle();
    });
  });

}).call(this);
