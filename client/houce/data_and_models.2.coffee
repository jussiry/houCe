

# Data initialization and caching
# Model helpers

# 2 in file name means that this will be the second file exeuted in client_app.js

# ### Data initialization

Houce.init_data = (remove_cache=true)->
  # Data init and Data.apis setup
  global.Data = apis: {}
  Data.apis[key] = {} for key,api of Config.apis

  # Model storage setup
  for name, model of Models
    Data[Houce.pluralize(name).toLowerCase()] = {}

  # Merge app defaults
  merge Data, Houce.init_data.app_defaults
  current_version = Houce.init_data.version

  if Config.storage_on
    # Load Data from cache
    prev_version = localStorage.DataVersion?.toNumber() or -1
    if  remove_cache                   or
        current_version is 'no_cache'  or
        current_version > prev_version
      # _Remove old cache_
      localStorage.removeItem 'Data'
      # init also session storage
      sessionStorage.removeItem key for key of sessionStorage
    else
      cached_data = if (lsd = localStorage.Data)? then Houce.objectify lsd else {}
      merge Data, cached_data

    cached_config = JSON.parse localStorage.Data_config or '{}'
    Data.config = merge Config.data_config, cached_config
    localStorage.setItem 'DataVersion', current_version
  else
    Data.config = Config.data_config

  # Bind to App Namespace
  global[Config.app_name].Data = Data


# ## Data caching

Houce.stringify = (main_obj)->

  # helpers to speed up iteration:
  models_arr = Object.values Models
  plur_model_names = Object.keys(Models).map (m_name)-> Houce.pluralize(m_name).toLowerCase()
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
              #if name is 'deferred'
              #  continue
              if is_in_models child_obj # Deal, Coupon, etc...
                #log 'model found', stack.clone()
                value = if stack.length is 2 and plur_model_names.has stack.at -2  #depth is 2 and plur_model_names.has name
                  iterate child_obj # parent has _store_type defined, so store full object
                else
                  link_model_str child_obj # store only string link
                "\"#{name}\": #{value}"
                #if obj._store_type then "'#{name}': #{iterate child_obj}" \
                #                     else "'#{name}_id': #{child_obj.id}"
              else "\"#{name}\": #{iterate child_obj}"
            "{ #{obj_strings.join ',\n'} }"
      when 'string'    then "'#{escape obj}'"
      when 'undefined' then 'undefined'
      when 'function'
        log "WARNING: Function found when stringifying Data", stack, obj.toString()
        'null'
      when 'number', 'boolean' then obj
      else console?.error obj
    stack.pop() #depth -= 1
    res
  )( main_obj )


Houce.objectify = (str)->

  start_time = Date.now()

  # to object:
  main_obj = eval "( #{str} )"

  # Create model objects:
  for model_name in Object.keys(Models)
    model_container = main_obj[Houce.pluralize(model_name).toLowerCase()]
    for id, obj of model_container
      model_container[id] = Models[model_name].new_data obj

  # helper func to unescape and return model object links:
  check_string = (parent,key)->
    if typeof parent[key] is 'string'
      parent[key] = unescape parent[key]
      if parent[key][0...7] is 'Model::'
        [m, type, id] = parent[key].split '::'
        parent[key] = Data[Houce.pluralize(type.toLowerCase())][id]
      true
    else false

  # Iterate through main_obj to apply check_string for strings:
  #parent_check_timer = 0
  stack = []
  (iterate = (parent_obj)->
    return if typeof parent_obj isnt 'object' or parent_obj is null
    # avoid infinite loops:
    # Why was this needed? Looping references alredy fail when stringifyin Data.
    # before_parent_check = Date.now()
    # if stack.has parent_obj
    #   log parent_obj, 'found from stack', stack
    #   return
    # else stack.push parent_obj
    # parent_check_timer += Date.now() - before_parent_check
    #log 'stack', stack.clone()
    if parent_obj instanceof Array
      for obj, ind in parent_obj
        iterate obj unless check_string parent_obj, ind
    else
      for own key, obj of parent_obj
        if typeof obj is 'object' then iterate obj \
                                  else check_string parent_obj, key
    stack.pop() # keep stack slim for perfomance
    return
  )( main_obj )
  #log "Objectifying #{parseInt str.length/1000} thousand chars took #{Date.now()-start_time}ms, of which parent check #{parent_check_timer}"
  main_obj


Houce.cache_data = ->
  return unless Config.storage_on
  log "Caching data"
  Data.cache_updated.last_stored = Date.now()
  localStorage.setItem 'Data', Houce.stringify Data
  localStorage.setItem 'Data_config', JSON.stringify (Data.config or {})
  if false and Config.env is 'development'
    temp_data = Object.clone Data
    window.object_again = Houce.objectify localStorage.getItem 'Data'
    unless Object.equal temp_data, object_again
      throw Error "in cache_data: Objectified data not equal to original"

Houce.cache_valid = (type)->
  return false if not Config.storage_on
  updated  = new Date Data.cache_updated[type]
  updated.isAfter Data.config.cache_update_after[type]


# If you have model names with irregular pluralization,
# add the correct pluralization here
Houce.pluralize = (word)->
  Models[word]?.plural or "#{word}s"


# ## Model helpers

Houce.model_new_data = (class_var)-> # , fetch_str
  c_name = class_var.name

  class_var.new_data = (data)->
    return data if typeof data isnt 'object'
    throw message: "#{c_name} data requires an ID", stack: data unless data?.id?

    plural = Houce.pluralize c_name
    # merge or create (and link to data)
    if Data[plural][data.id]?
      merge Data[plural][data.id], data
    else Data[plural][data.id] = new class_var data


# WARNING: this is not ready
Houce.deferred_get = (parent, child_name, fetch_str, callback)->
  # This needs some thinking still..

  if parent[child_name]?
    callback parent[child_name]
  else
    Houce.apis.fb_get fetch_str, (res)->
      res = res.data if res.data?
      Object.each res, (el, key)->


