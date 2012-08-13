


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
        # don't loose child vars (bind normally does):
        for child_key in Object.getOwnPropertyNames child
          container[key][child_key] = child[child_key]
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

  #alert 'rendering '+template_name

  Houce.render.counter += 1

  template_name = template_name.name if typeof template_name is 'object'
  templ = Templates[template_name]
  throw Error("Template '"+template_name+"' not found.") unless templ?

  # create child of data_obj, so it won't get modified by coffeekup (e.g. if data_obj is a deal)
  data_obj = child data_obj
  # merge extra data; again the principle here is to not modify the original object
  merge data_obj, extra_data if extra_data?

  # bind data of last rendered object to template (@data to access)
  templ.data = data_obj

  html = null
  #Utils.try "rendering #{template_name}", ->
  try
    html = CoffeeKup.render templ.html, data_obj,
                            me:    templ
                            cache: true
                            autoescape: templ.autoescape ? false
  catch err
    throw Error "when rendering template '#{template_name}': #{err.message}"



  # TODO: make a better way to add raw/jquery content in templates
  # (performance wise also without raw-el left in DOM).
  # Probably should be done alredy in CoffeeKup.
  if html instanceof Array

    #global.arr = html
    new_html = ''
    raws = []
    #global.raws = raws if template_name is 'back_button'
    for el in html
      if typeof el is 'string'
        new_html += el
      else
        new_html += "<raw>#{raws.length}</raw>"
        raws.push el
    global.q_html = $(new_html)

    #log 'q_html for "'+template_name+'" before', q_html.clone()

    raw_to_html = ->
      raw_ind = parseInt @innerHTML
      raw = raws[raw_ind]
      #log 'raw', raw_ind, raw

      if raw[0] is 'sprite'
        #log 'raw sprite', raw
        Utils.sprite raw[1], raw[2], raw[3]
        #<div>SPRITE</div>"
      else
        log "ERROR! raw isn't single jq el:", raw unless raw.length is 1
        raw[0]

    q_html.each (ind)->
      if @nodeName is 'RAW' #q_html[ind]   #$(@).parent().length
        q_html[ind] = raw_to_html.call @
      else
        $(@).find('raw').replaceWith raw_to_html

    # try
    #   log 'q_html for "'+template_name+'" after', q_html
    # catch err
    #   log 'CLONE FAILED'
    html = q_html

  if templ.init?
    # Run init function and return template as jQuery object
    templ.el = $ html # jquery element is bound to template (@el to access)
    #Utils.try "initializin template '#{template_name}'", ->
    try
      templ.init templ.el, data_obj # TODO: no need to send templ.el? or send as second param?
    catch err
      console.error "in @init of template '#{template_name}': #{err.message}"
    templ.el
  else
    # If no init function (template is "partial") return template as string
    templ.el = html

Houce.render.counter = 0


# JQuery shortcuts for Houce.render
jQuery.fn.render = (args...)->
  # accepts name of template, or the template object itself:
  args[0] = args[0].name if typeof args[0] is 'object'
  @.html (el = Houce.render.apply null, args)
  el
jQuery.fn.render_bottom = (args...)->
  @.append (el = Houce.render.apply null, args)
  el
jQuery.fn.render_top = (args...)->
  @.prepend (el = Houce.render.apply null, args)
  el
jQuery.fn.render_outer = (args...)->
  @.first().before (el = Houce.render.apply null, args)
  @.remove()
  el

