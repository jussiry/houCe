


Houce.init_templates = ->
  for templ_name, container of Templates
    # bind name of template under each template
    container.name = templ_name

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
  
  Houce.render.counter += 1

  template_name = template_name.name if typeof template_name is 'object'
  templ = Templates[template_name]
  throw Error("Template '"+template_name+"' not found.") unless templ?
  
  # create child of data_obj, so it won't get modified by coffeekup (e.g. if data_obj is a deal)
  data_obj = child data_obj
  # merge extra data; again the principle here is to not modify the original object
  merge data_obj, extra_data if extra_data?

  # bind data of last rendered object to template (@d to access)
  templ.d = data_obj   
  
  html = CoffeeKup.render templ.html, data_obj,
                          me:    templ
                          cache: true
                          autoescape: false
  
  # TODO: make a better way to add raw/jquery content in templates
  # (performance wise also without raw-el left in DOM).
  # Probably should be done alredy in CoffeeKup.
  if html instanceof Array
    new_html = ''
    raws = []
    for el in html
      if typeof el is 'string'
        new_html += el
      else
        new_html += "<raw>#{raws.length}</raw>"
        raws.push el
    q_html = $(new_html)
    q_html.el('raw').each (ind, el)->
      $(el).html raws[parseInt el.innerHTML]
    html = q_html

  if templ.init?
    # Run init function and return template as jQuery object
    templ.el = $ html # jquery element is bound to template (@el to access)
    templ.init templ.el, data_obj # TODO: no need to send templ.el? or send as second param?
    templ.el
  else
    # If no init function (template is "partial") return template as string
    templ.el = html

Houce.render.counter = 0


# JQuery shortcuts for Houce.render
jQuery.fn.render = (args...)->
  args[0] = args[0].name if typeof args[0] is 'object'
  @.html (el = Houce.render.apply null, args)
  el
jQuery.fn.render_bottom = (args...)->
  @.append (el = Houce.render.apply null, args)
  el
jQuery.fn.render_top = (args...)->
  @.prepend (el = Houce.render.apply null, args)
  el

