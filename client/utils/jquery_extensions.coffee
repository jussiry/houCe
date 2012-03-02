


jQuery.fn.render = (args...)->
  @.html Utils.render.apply null, args

jQuery.fn.render_bottom = (args...)->
  @.append Utils.render.apply null, args

jQuery.fn.render_top = (args...)->
  @.prepend Utils.render.apply null, args

$.ajaxSetup
  async: true
  crossDomain: true
  dataType: 'json'
  #dataType: 'jsonp'
  contentType: "application/x-www-form-urlencoded; charset=utf-8"
  beforeSend: null #($jqxhr, params)-> $.ajaxStack.push $jqxhr
  error: (request, statustext, errormsg)->
    unless errormsg == 'abort' or statustext == 'abort'
      alert "ajax error: #{statustext} :: #{errormsg}"
