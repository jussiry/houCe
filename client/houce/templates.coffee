


Houce.init_templates = ->
  for templ_name, container of Templates
    if container.page?
      # Execute page if it is a function. @page = ->  -->  @page = do ->
      Pages[templ_name] = switch typeof container.page
        when 'object'   then container.page 
        when 'function' then container.page()
      # Move @page under Pages: Tempaltes[name].page --> Pages[name]
      Pages[templ_name].name = templ_name
      # link @page under template to same object:
      Templates[templ_name].page = Pages[templ_name]

    # TODO: do binding of container iteratively ?

    # Bind template container to @ of every function inside the container -
    # except @html's CoffeeKup function, where @ stores the data for rendering.
    for key, child of container
      if typeof child is 'function' and key isnt 'html'
       container[key] = child.bind container
      else if typeof child is 'object'
        # when object, bind template container to all child functions
        for sub_key, sub_child of child
          if typeof sub_child is 'function'
            child[sub_key] = sub_child.bind container
  return



### Render function for templates. ###
# Use $(el).render(..), except for partials,
# for which you'll need to use `$(el).html( Houce.render(template\_name) )`.
Houce.render = (template_name, data_obj={}, extra_data)->
  template_name = template_name.name if typeof template_name is 'object'
  templ = Templates[template_name]
  throw Error("Template '"+template_name+"' not found.") unless templ?
  
  # Extra data is bound to rendered object without modifying the original object
  if extra_data
    proto = data_obj.__proto__
    data_obj = merge Object.clone(data_obj), extra_data
    data_obj.__proto__ = proto

  # bind data of last rendered object to template (@d to access)
  templ.d = data_obj   
  
  html_str = CoffeeKup.render templ.html, data_obj,
                              templ: templ
                              cache: true
                              autoescape: false
  
  if templ.init?
    # Run init function and return template as jQuery object
    templ.el = $ html_str # jquery element is bound to template (@el to access)
    templ.init templ.el, data_obj # TODO: no need to send templ.el? or send as second param?
    templ.el
  else
    # If no init function (template is "partial") return template as string
    templ.el = html_str
  

# JQuery shortcuts for Houce.render
jQuery.fn.render = (args...)->
  @.html Houce.render.apply null, args
jQuery.fn.render_bottom = (args...)->
  @.append Houce.render.apply null, args
jQuery.fn.render_top = (args...)->
  @.prepend Houce.render.apply null, args

# jQuery helpers
jQuery.fn.is_in_dom = -> @parents('body').length > 0
# TODO: which is faster: .parents() or .contains() ? http://api.jquery.com/jQuery.contains/

# Retuns title of the current, or given page
Houce.page_title = (page)->
  page = Pages[page] if typeof page is 'string'
  page ?= PageHandler.get_page()
  title = page.title or ''
  if typeof title is 'function' then title() \
                                else title


# No logical place for Houce.error?
Houce.error = (error_str, file_path, line_number)->
  
  if Templates.notice?
    Templates.notice.error dict 'error_notice'
  
  return unless Houce.error.logging_on

  # Send to sever
  $.post '/err_logs',
    ua:        navigator.userAgent
    err_msg:   error_str
    err_stack: "[#{line_number}, #{file_path}]"
    non_err_err:  JSON.stringify arguments
    err_title:    str
    timestamp:    Date.now()
    path_history: JSON.stringify PageHandler.path_history
