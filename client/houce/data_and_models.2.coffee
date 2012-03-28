

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
    Data[Houce.pluralize(name).toLowerCase()] ?= {}
  # Merge app defaults
  merge Data, Houce.init_data.app_defaults
  Data.version = Houce.init_data.version
  
  # Handle cache
  if Config.storage_on

    prev_version = localStorage.DataVersion.toNumber()
    
    if remove_cache or Data.version is 'no_cache' or Data.version > prev_version
      # _Remove old cache_
      localStorage.removeItem 'Data'
      localStorage.setItem.DataVersion = Houce.init_data.version
      # init also session storage
      sessionStorage.removeItem key for key of sessionStorage
    else
      # _Load Data from cache_
      data_str = localStorage.Data
      merge Data, Houce.objectify data_str if data_str?

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

Houce.objectify = (str)->
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
      #log key+' '+parent[key]
      parent[key] = unescape parent[key]
      if parent[key][0...7] is 'Model::'
        #log "returning #{parent[key]} from", parent
        [m, type, id] = parent[key].split '::'
        parent[key] = Data[Houce.pluralize(type.toLowerCase())][id]
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

Houce.cache_data = ->
  return unless Config.storage_on
  console.info "Caching data"
  Data.cache_updated.last_stored = Date.now()
  localStorage.setItem 'Data', Houce.stringify Data
  localStorage.setItem 'DataVersion', Data.version
  if false and Config.env is 'development'
    temp_data = Object.clone Data
    window.object_again = Houce.objectify localStorage.getItem 'Data'
    unless Object.equal temp_data, object_again
      throw Error "in cache_data: Objectified data not equal to original"

Houce.cache_valid = (type)->
  updated  = new Date Data.cache_updated[type]
  time_str = Config.cache_update_after[type]
  updated.isAfter time_str


# If you have model names with irregular pluralization,
# add the correct pluralization here
Houce.pluralize = (word)->
  switch word.toLowerCase()
    when 'person' then 'people'
    else "#{word}s"


# ## Model helpers

Houce.model_new_data = (class_var)-> # , fetch_str
  #do ->
  c_name        = class_var.name
  c_name_plural = Houce.pluralize c_name
  
  class_var.new_data = (data)->
    return data if typeof data isnt 'object'
    throw message: "#{c_name} data requires an ID", stack: data unless data?.id?

    # merge or create (and link to data)
    if Data[c_name_plural][data.id]?
      Data[c_name_plural][data.id].merge data
    else Data[c_name_plural][data.id] = new class_var data


# WARNING: this is not ready  
Houce.deferred_get = (parent, child_name, fetch_str, callback)->
  # This needs some thinking still..

  if parent[child_name]?
    callback parent[child_name]
  else
    Houce.apis.fb_get fetch_str, (res)->
      res = res.data if res.data?
      Object.each res, (el, key)->





