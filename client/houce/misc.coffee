

$.ajaxSetup
  async: true
  crossDomain: true
  dataType: 'json'
  #dataType: 'jsonp'
  contentType: "application/x-www-form-urlencoded; charset=utf-8"
  beforeSend: null #($jqxhr, params)-> $.ajaxStack.push $jqxhr
  error: (request, statustext, errormsg)->
    log 'ajax error ', arguments
    Utils.try 'ajax error', ->
      unless errormsg?.matches?(['abort', 'error']) or statustext?.matches? ['abort', 'error']
        alert "ajax error: #{statustext} :: #{errormsg}"


window.reqAnimFrame = window.requestAnimationFrame or
                      window.webkitRequestAnimationFrame or
                      window.mozRequestAnimationFrame or
                      window.oRequestAnimationFrame or
                      window.msRequestAnimationFrame or
                      (callback)-> window.setTimeout(callback, 1000 / 60)

# TODO: which is faster: .parents() or .contains() ? http://api.jquery.com/jQuery.contains/
$.fn.is_in_dom = -> @parents('body').length > 0

$.fn.tap = (act)->
  # alert "ontouchstart " + ('ontouchstart' in document.querySelector 'body')
  # alert "touchstart " + ('touchstart' in document.querySelector 'body')
  # if 'ontouchstart' in document.documentElement
  #      alert 'ontouchstart found!'
  $(@).on 'touchstart', act
  #else $(@).click act


$.fn.cull = (selector)->
  @filter(selector).add @find(selector)
  # faster but don't get all cases:
  # filtered = @filter selector
  # if filtered.length then filtered \
  #                    else @find selector


#$.fn.animate_orig = $.fn.animate
$.fn.anim = (args...)->
  merge args[0],
    useTranslate3d:  true
    leaveTransforms: true
  #alert 'bef anim'
  $.fn.animate.apply @, args
  #alert 'after anim'

# Retuns title of the current, or given page
Houce.page_title = (templ)->
  page = Templates[templ] if typeof templ is 'string'
  page ?= Pager.get_page()
  title = page.title or ''
  result_of title # title or title()


do ->
  Houce.err_log = global.hel = (msg...)->
    msg = msg.map((m)->
              try JSON.stringify m
              catch e then typeof m
            ).join ', '
    hel.msgs.push msg
    log "HEL: #{msg}"
    hel.msgs.shift() if hel.msgs.length > 10
  hel.msgs = []

# Send errors to server and show error notice to user
Houce.error = (error_str, file_path, line_number)->
  # skip known bugs
  return if error_str.matches [
    # "Script error." # Apparently caused by same origin policy: http://stackoverflow.com/questions/5913978/cryptic-script-error-reported-in-javascript-in-chrome-and-firefox
  ] or not Houce.error.logging_on

  unless Utils.device?.is_mobile() #alert "error: #{error_str}, file: #{file_path}, line: #{line_number}"
    log 'error_str', error_str
    log 'file_path', file_path

  # Show error message to user
  Templates.notice.error (dict 'error_notice') or "Error!"  if Templates.notice?
  # Send to sever
  [title, msg...] = error_str.split ':'
  msg = msg.join ':'
  err_stack =  file_path?.split('/').last() or ''
  err_stack += ':' + line_number if line_number?
  $.post '/err_logs',
    ua:        navigator.userAgent
    err_title: title
    err_msg:   msg
    err_stack: err_stack
    err_logs:  Houce.err_log.msgs # JSON.stringify
    non_err_err:  JSON.stringify arguments
    timestamp:    Date.now()
    path_history: JSON.stringify Pager.path_history

