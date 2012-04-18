
# $ helpers
$.fn.is_in_dom = -> @parents('body').length > 0
# TODO: which is faster: .parents() or .contains() ? http://api.jquery.com/jQuery.contains/

# Retuns title of the current, or given page
Houce.page_title = (templ)->
  page = Templates[templ] if typeof templ is 'string'
  page ?= PageHandler.get_page()
  title = page.title or ''
  result_of title # title or title()


# No logical place for Houce.error?
Houce.error = (error_str, file_path, line_number)->
  # skip known bugs
  return if error_str.is_in [
    "Uncaught TypeError: Cannot call method 'replace' of undefined" # jquery.animate-enhanced bug
  ] or not Houce.error.logging_on

  # Show error message to user
  Templates.notice.error dict 'error_notice' if Templates.notice?
  # Send to sever
  [title, msg...] = error_str.split ':'
  msg = msg.join ':'
  $.post '/err_logs',
    ua:        navigator.userAgent
    err_title: title
    err_msg:   msg
    err_stack: "#{file_path?.split('/').last()}:#{line_number}"
    non_err_err:  JSON.stringify arguments
    timestamp:    Date.now()
    path_history: JSON.stringify PageHandler.path_history

