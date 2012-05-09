
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
  Array.prototype.get_bool = -> for el in @
    return el if el.constructor == Boolean
  
  # object.each to work as (val,key) params? Or just use Object.each for also arrays when same order needed.
    #console.log  Object.each
    #orig_object_each = Object.prototype.each

    #Object.defineProperty Object.prototype, 'each',
    #  value: (func)-> Object.each @, func

  console.log 'global:',global
  # GLOBALS:
  global ?= window

  global.log = global.l = (args...) -> console.log.apply console, args
  global.dir =            (args...) -> console.dir.apply console, args
  #global.log = global.l = console.log.bind console # bind messes up with remote console (which overwrites console.log)

  # alias for JQuery
  global.q = $ if $?
  
  # shorhand for query selector  
  global.get_el  = document?.querySelector.bind document
  global.get_els = document?.querySelector.bind document

  global.ins = (o) ->
    str = "#{o.constructor.name} (#{typeof o}):\n"
    str += "#{key}: #{val},\n" for own key,val of o

  global.delay = (ms, func)->
    if Object.isFunction ms then ms.delay() \
                            else func.delay ms

  # Sugar.js Object shorthands:
  global.each  = Object.each #(a,b)-> Object.each a, b #.bind Object
  global.merge = Object.merge
  global.equal = Object.equal


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


  #### Call same function many times with different params
  if Object.defineProperty?
    Object.defineProperty Function.prototype, 'repeat', value: (args...)->
      # TODO: add possibility for many params (given as array)
      # hmm, no so useful since can't retain functions 'this'..?
      @ param for param in args
    

  # Define .forEach also for objects; equal to .each,
  # except has same order of parameter as in Arrays: (value,key)
  # Object.forEach:
  Object.forEach = (obj, func)->
    Object.each obj, (key,val)-> func(val,key)
  # Object.prototype.forEach:
  if Object.defineProperty?
    Object.defineProperty Object.prototype, 'forEach',  value:
      (func)-> Object.each @, (key,val)-> func(val,key)

  # child() creates a new object that inherits from the given object
  global.child = (o, child={})->
    child.__proto__ = o
    child
  #Object.defineProperty Object.prototype, 'child',  (value: -> __proto__:@) if Object.defineProperty?

  
  # Object prototype:
  if Object.defineProperty?
    Object.defineProperty Object.prototype, 'first',  value: -> Object.values(@)[0]
    Object.defineProperty Object.prototype, 'remove_els', value: (test_func)-> Object.remove_els(@, test_func)
    
    # Chek if primitive is found in array or in object (as top level value)
    # e.g.  if some_str.is_in ['aa', 'bb', 'cc'] then ...
    # NOTE: works only for primitives, not objects!
    Object.defineProperty Object.prototype, 'is_in', value: (arr_or_obj)->
      for own k,v of arr_or_obj
        return true if @+'' is v+'' and typeof v isnt 'object'
      false
    # Same as .is_in, except check also for partial strings
    # e.g. "baad".matches['aa'] # true
    Object.defineProperty String.prototype, 'matches', value: (strings)->
      return null unless typeof strings is 'array' or typeof strings is 'object'
      for own k,str of strings
        return true if @.match str
      false


    # CONFLICTS WITH GOOGLE MAPS:
    # Object.defineProperty Object.prototype, 'length', value: -> Object.keys(@).length
    # # result invokes the object if it is a function, other wise just returns it
    # Object.defineProperty Object.prototype, 'result', value: ->
    #   if @.constructor is Function then @() else @
    #   # NOTICE: 123.result() isnt 123 (dunno how this should be fixed)

  
  global.result_of = (a)->
    if typeof a is 'function' then a() else a

  
  #global.desc = (msg)-> console.info(msg) # describes code

  
  # ifs: short version for returning the value (normally string) if argument
  # exists, otherwise returns empty string:
  global.ifs = (arg, true_str, false_str)->
    true_str = arg unless true_str?
    if arg then true_str else (if false_str? then false_str else '')

  global.is_blank = (obj)-> not obj? or (Object.isString(obj) and /^\s*$/.test obj) \
                                     or (typeof object is 'object' and Object.keys(obj).length == 0)

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
