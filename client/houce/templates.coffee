


Houce.init_templates = ->
  for templ_name, container of Templates
    # Bind template container to @ of every function inside the container -
    # except @html's CoffeeKup function, where @ stores the data for rendering.
    for key, child in container
      if typeof child is 'function' and key isnt 'html'
        child.bind container
    # Move @page under Pages: Tempaltes[name].page --> Pages[name]
    # and execute it if it is a function; as if:
    # @page = ->  -->  @page = do ->
    if container.page?
      Pages[templ_name] = switch typeof container.page
        when 'object'   then container.page 
        when 'function' then container.page()
      Pages[templ_name].name = templ_name
      # link @page under template to same object:
      Templates[templ_name].page = Pages[templ_name]


# Retuns title of the current, or given page
Houce.page_title = (page)->
  page = Pages[page] if typeof page is 'string'
  page ?= PageHandler.get_page()
  title = page.title or ''
  if typeof title is 'function' then title() \
                                else title


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

  html_str = CoffeeKup.render templ.html, data_obj,
                              templ: templ
                              cache: true
                              autoescape: false
  
  # If no init function (is "partial") return template as string
  return html_str unless templ.init?
  # Otherwise run init function and return template as jQuery object
  $el = $ html_str
  templ.init $el, data_obj, templ
  $el

# JQuery shortcuts for Houce.render
jQuery.fn.render = (args...)->
  @.html Houce.render.apply null, args
jQuery.fn.render_bottom = (args...)->
  @.append Houce.render.apply null, args
jQuery.fn.render_top = (args...)->
  @.prepend Houce.render.apply null, args

