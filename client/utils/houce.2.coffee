
# Utils for handling houce conventions:
#
# * Data initialization and caching
# * Model helpers
# * Template rendering

# 2 in houce.2.coffee means that this will be the second file exeuted in client_app.js

# ### Data initialization

Utils.init_data = (remove_cache)->

  # Namespace for all retrieved data
  global.Data   = {}
  Data.version  = 3 # increment this version each time Data structure changes; causes the cache to be flushed
  
  if localStorage? and remove_cache
    localStorage.removeItem 'Data'
    localStorage.setItem 'DataVersion', Data.version
    # Session storage:
    sessionStorage.each (key)-> sessionStorage.removeItem key

  for name, model of Models
    Data[Utils.pluralize(name).toLowerCase()] = {}
  
  Data.cache_updated =
    coordinates: null
    last_stored: null
  Data.misc =
    coord:
      latitude:  null
      longitude: null
    me: null
  Data.apis =
    fb:
      access_token: null
      #expires: null
    google:
      access_token: null
    
  global[Config.app_name].Data = Data



# ## Data caching

Utils.stringify = (main_obj)->

  # helpers to speed up iteration:
  models_arr = Object.values Models
  plur_model_names = Object.keys(Models).map (m_name)-> Utils.pluralize(m_name).toLowerCase()
  #log 'plur_model_names', plur_model_names
  is_in_models =   (obj)-> models_arr.has (el)-> el is obj?.constructor
  link_model_str = (obj)-> "'Model::#{obj.constructor.name}::#{obj.id}'"

  # iterator:
  stack = []
  (iterate = (obj)-> # , treat_as_object=false
    stack.push null # += 1
    res = switch typeof obj #obj.constructor
      when 'object'
        if obj is null then 'null'
        else
          # could be object, array, or anything that inherits object (presumably found from Models)
          if obj.constructor is Array
            obj_strings = for child_obj in obj
              if is_in_models child_obj then link_model_str child_obj \
                                        else iterate child_obj
            "[#{ obj_strings.join ',' }]"  
          else
            obj_strings = for own name, child_obj of obj
              stack.splice -1, 1, name
              if name is 'deferred'
                continue
              if is_in_models child_obj # Deal, Coupon, etc...
                #log 'model found', stack.clone()
                value = if stack.length is 2 and plur_model_names.has stack.at -2  #depth is 2 and plur_model_names.has name
                  iterate child_obj # parent has _store_type defined, so store full object
                else
                  link_model_str child_obj # store only string link
                "'#{name}': #{value}"
                #if obj._store_type then "'#{name}': #{iterate child_obj}" \
                #                     else "'#{name}_id': #{child_obj.id}"
              else "'#{name}': #{iterate child_obj}"
            "{ #{obj_strings.join ',\n'} }"
      when 'string'    then "'#{escape obj}'"
      when 'undefined' then 'undefined'
      when 'function'
        console.info "WARNING: Function found when stringifying Data", stack, obj.toString()
        'null'
      when 'number', 'boolean' then obj
      else console.error obj
    stack.pop() #depth -= 1
    res
  )( main_obj )

Utils.objectify = (str)->
  # to object:
  main_obj = eval "( #{str} )"
  
  # Create model objects:
  for model_name in Object.keys(Models)
    model_container = main_obj[Utils.pluralize(model_name).toLowerCase()]
    for id, obj of model_container
      model_container[id] = Models[model_name].new_data obj
  
  # helper func to unescape and return model object links:
  check_string = (parent,key)->
    if typeof parent[key] is 'string'
      #log key+' '+parent[key]
      parent[key] = unescape parent[key]
      if parent[key][0...7] is 'Model::'
        #log "returning #{parent[key]} from", parent
        [m, type, id] = parent[key].split '::'
        parent[key] = Data[Utils.pluralize(type.toLowerCase())][id]
      true
    else false
  
  # Iterate through main_obj to apply check_string for strings:
  stack = []
  (iterate = (parent_obj)->
    return if typeof parent_obj isnt 'object' or parent_obj is null
    # avoid infinite loops:
    if stack.has parent_obj then return \
                            else stack.push parent_obj
    if parent_obj.constructor is Array
      for obj, ind in parent_obj
        iterate obj unless check_string parent_obj, ind
    else
      for own key, obj of parent_obj
        iterate obj unless check_string parent_obj, key
    stack.pop() # keep stack slim for perfomance
    return
  )( main_obj )
  main_obj

Utils.cache_data = ->
  return unless localStorage?
  console.info "Caching data"
  Data.cache_updated.last_stored = Date.now()
  #Utils.speed_test 'stringifyng', 1, ->
  Utils.try 'Storing data to localStorage', ->
    localStorage.setItem 'Data', Utils.stringify Data
    localStorage.setItem 'DataVersion', Data.version
  if false and Config.env is 'development'
    temp_data = Object.clone Data
    window.object_again = Utils.objectify localStorage.getItem 'Data'
    unless Object.equal temp_data, object_again
      Utils.fail 'cache_data', "Objectified data not equal to original"

Utils.cache_valid = (type)->
  updated  = new Date Data.cache_updated[type]
  time_str = Config.cache_update_after[type]
  updated.isAfter time_str


# ## Model helpers

Utils.model_new_data = (class_var)-> # , fetch_str
  #do ->
  c_name        = class_var.name
  c_name_plural = Utils.pluralize c_name
  
  class_var.new_data = (data)->
    return data if typeof data isnt 'object'
    throw message: "#{c_name} data requires an ID", stack: data unless data?.id?

    # merge or create (and link to data)
    if Data[c_name_plural][data.id]?
      Data[c_name_plural][data.id].merge data
    else Data[c_name_plural][data.id] = new class_var data


# WARNING: this is not ready  
Utils.deferred_get = (parent, child_name, fetch_str, callback)->
  # This needs some thinking still..

  if parent[child_name]?
    callback parent[child_name]
  else
    Utils.apis.fb_get fetch_str, (res)->
      res = res.data if res.data?
      Object.each res, (el, key)->


# If you have model names with irregular pluralization, add the correct pluralization here
Utils.pluralize = (word)->
  switch word
    when 'person' then 'people'
    else "#{word}s"



# ### Helpers for debugging both on desktop and mobile environments
Utils.try = (str, cb)->
  try cb()
  catch err then Utils.fail str, err

# In mobile errors are alted. In future, when in production mode skip alerts
# and send errors to server for logging.
Utils.fail = (str, err)->
  err_msg = "Error in #{str}: #{err.message or err} " #  - #{err.stack}
  if Config.is_mobile
    alert err_msg + err.stack
  else
    console.error "------ERROR------"
    log err_msg
    log err.stack if err.stack


# Test performance of different functions.
Utils.speed_test = (args...)->
  start = Date.now()
  (args.get_num() or 1000).times args.get_func()
  msg = (args.get_str() or 'Speed test took') + " #{Date.now() - start} ms"
  if Config.is_mobile then alert       msg \
                      else console.log msg
  return



# ### Render function for templates.

# Use $(el).render(..), except for partials,
# for which you'll need to use `$(el).html( Utils.render(template\_name) )`.

Utils.render = (template_name, data_obj={}, extra_data)->
  
  Utils.try "Utils.render #{template_name}", =>
  
    try            ck_func = Templates[template_name].html
    catch err then throw "Template '"+template_name+"' not found." unless Templates[template_name]?
  
    # Extra data is bound to rendered object without modifying the original object
    if extra_data
      proto = data_obj.__proto__
      data_obj = merge Object.clone(data_obj), extra_data
      data_obj.__proto__ = proto
    
    html_str = CoffeeKup.render ck_func, data_obj, cache:true, autoescape:false
    
    # If no init function (is "partial") return template as string
    init_func = Templates[template_name].init
    return html_str unless init_func?
    # Otherwise run init function and return template as jQuery object
    $el = $ html_str
    init_func $el, data_obj
    $el


