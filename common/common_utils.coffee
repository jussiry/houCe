
try


  # Sugar.js extensions:
  #Array::equals = (another_arr)-> Object.equals this, another_arr
  #Object.defineProperties Object.prototype, a: value: 3 #, b: 4

  Array.prototype.get_num = -> for el in @
    return el if el.constructor == Number
  Array.prototype.get_str = -> for el in @
    return el if el.constructor == String
  Array.prototype.get_arr = -> for el in @
    return el if el.constructor == Array
  Array.prototype.get_func = -> for el in @
    return el if el.constructor == Function
  
  # object.each to work as (val,key) params? Or just use Object.each for also arrays when same order needed.
    #console.log  Object.each
    #orig_object_each = Object.prototype.each

    #Object.defineProperty Object.prototype, 'each',
    #  value: (func)-> Object.each @, func

  # GLOBALS:
  global ?= window

  #global.log = global.l = (msg) -> console.log(msg)
  global.log = global.l = console.log.bind console

  global.ins = (o) ->
    str = "#{o.constructor.name} (#{typeof o}):\n"
    str += "#{key}: #{val},\n" for own key,val of o

  global.delay = (ms, func)->
    if Object.isFunction ms then ms.delay() \
                            else func.delay ms

  # Sugar.js Object shorthands:
  global.each  = Object.each #(a,b)-> Object.each a, b #.bind Object
  global.merge = Object.merge


  # Missing functions in Sugar.js:
  
  Number.prototype.toDate = -> Date.create(@)
    
  String.prototype.parsesToNumber = -> not Object.isNaN this.toNumber()

  Object.remove_els = (obj, test_func)-> # using Object.prototype.remove would fuck things up properly; no idea why
    (delete obj[key] if test_func key, val) for key, val of obj
    obj
  
  Object.filter = (obj, test_func)->
    new_obj = {}
    for key, val of obj
      new_obj[key] = val if test_func key, val
    new_obj


  # Define .forEach also for objects; equal to .each,
  # except has same order of parameter as in Arrays: (value,key)
  # Object.forEach:
  Object.forEach = (obj, func)->
    Object.each obj, (key,val)-> func(val,key)
  # Object.prototype.forEach:
  if Object.defineProperty?
    Object.defineProperty Object.prototype, 'forEach',  value:
      (func)-> Object.each @, (key,val)-> func(val,key)

  
  # Object prototype:
  if Object.defineProperty?
    # Does not work on nokia, USE ONLY FOR DEBUGGING
    Object.defineProperty Object.prototype, 'first',  value: -> Object.values(@)[0]
    Object.defineProperty Object.prototype, 'remove_els', value: (test_func)-> Object.remove_els(@, test_func)
    Object.defineProperty Object.prototype, 'length', value: -> @.keys().length

    # NOTE: using Object.prototype.remove would fuck things up properly; no idea why
  
  #global.log = global.l = console.log # causes illegal invocation on client?
  #global.log = global.l = console.log.bind(console) # nah, don't help; log row just points inside sugar.js

  #global.desc = (msg)-> console.info(msg) # describes code

  
  # ifs: short version for returning the value (normally string) if argument
  # exists, otherwise returns empty string:
  global.ifs = (arg, true_str, false_str)->
    if arg then true_str else (if false_str? then false_str else '')

  global.is_blank = (obj)-> not obj? or (Object.isString(obj) and /^\s*$/.test obj) \
                                     or (Object.isObject(obj) and Object.keys(obj).length == 0)

  global.callbacks = (args...)->
    if args.length is 2
      # args: [async_func_1, af2, ...], final_cb
      async_funcs = args[0]
      final_cb    = args[1]
    else
      # args: async_func_1, af2, ..., final_cb
      final_cb    = args.pop()
      async_funcs = args[0]
    
    af_responses = []

    # executed after all async_funcs are ready:
    af_ready = (->
      #final_cb.apply null, af_responses
      final_cb af_responses
    ).after async_funcs.length

    for af, ind in async_funcs
      do ->
        i = ind
        af_callback = (res)->
          af_responses[i] = res
          af_ready()
        if typeof af is 'function'
          af af_callback
        else if Object.isArray af
          # af is [af, param1, param2, ...]
          params = af
          af     = params.shift()
          params = params.concat af_callback
          af.apply null, params
        else
          throw "Illegal asyn_func param for callbacks"
    return

catch err
  if alert? then alert "Error in common_utils: #{err.message}" \
            else throw err
