(function() {
  var img_srcs, src, temp_image, _i, _len;

  img_srcs = [];

  temp_image = new Image();

  for (_i = 0, _len = img_srcs.length; _i < _len; _i++) {
    src = img_srcs[_i];
    temp_image.src = src;
  }

}).call(this);
