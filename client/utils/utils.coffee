

# Keep minimum of 100% height for page
# + hide scroll bar

do ->
  timeout = null
  last_checked = 0
  delay_ms = 500
  q_wrap = null

  Utils.init_page_height_autoadjust = ->
    q_wrap = $ '#wrapper'
    q_wrap.bind 'DOMSubtreeModified', ->
      return if timeout?
      if (free = last_checked + delay_ms) > Date.now()
        timeout = setTimeout adjust, free - Date.now()
      else reqAnimFrame adjust

  Utils.adjust_page_height = adjust = ->
    double_act = ->
      min_page_height = window.innerHeight + Utils.device.banner_height()
      q_wrap.css 'height', ''
      #log 'min_page_height', min_page_height
      #log 'q_wrap.height()', q_wrap.height()
      if q_wrap.height() < min_page_height
        q_wrap.css 'height', min_page_height+'px'
      # hide scrollBar:
      window.scrollTo 0,1 unless window.pageYOffset > 1

    # For best result the check is done twice.
    # sometime on the first run the DOM element height's have not yet been changed,
    # the second run with 'reqAnimFrame' on the other hand can case small flicker
    #double_act()
    double_act()
    # remove timeout to allow new checks, but store current time,
    # to allow next check only after delay_ms has passed.
    timeout = null
    last_checked = Date.now()



Utils.days_remaining = (end_time, short)->
  end_time  = Date.create end_time if end_time.constructor == String
  time_left = end_time - Date.now()
  days_left = time_left / 1000 / 60 / 60 / 24
  days_left.round()

# min / h / d
Utils.time_left = (end_time)->
  end_time  = Date.create end_time if end_time.constructor == String
  if    end_time.minutesFromNow() < 60 then "#{end_time.minutesFromNow()} min"
  else if end_time.hoursFromNow() < 24 then "#{end_time.hoursFromNow()} h"
  else "#{end_time.daysFromNow()} #{if Config.lang is 'fi' then 'pv' else 'd'}"

# minutes / hours / days
Utils.time_since = (end_time)->
  end_time  = Date.create end_time #if end_time.constructor == String
  str = if end_time.minutesAgo() < 60 then "#{end_time.minutesAgo()} #{dict 'minutes'}"
  else if  end_time.hoursAgo() < 24 then "#{end_time.hoursAgo()} #{dict 'hours'}"
  else "#{end_time.daysAgo()} #{dict 'days'}" # #{if Config.lang is 'fi' then 'pv' else 'd'}"
  str += ' ' + dict 'ago'











#  API's

Utils.get_geolocation = (recalculate=false, cb)->
  cb = recalculate if recalculate.constructor is Function

  coord = Data.misc.coord
  if Houce.cache_valid 'coordinates' # coord.updated? and Date.now() - coord.updated < 20.minutes() and not recalculate
    cb coord
  else
    if Config.demo_hack?.coord?
      log "Using demo_hack coordinates:", Config.demo_hack.coord
      merge coord, Config.demo_hack.coord
      cb Config.demo_hack.coord
      return
    geo_success = (gp)->
      return geo_failed code: -2 if gp.coords.longitude < 0
      coord.latitude  = gp.coords.latitude
      coord.longitude = gp.coords.longitude
      Data.cache_updated.coordinates = Date.now()
      #log 'geo success', gp
      cb coord
    geo_failed = (err)->
      default_msg = 'Näytämme paikannuksen suhteessa Helsingin keskustaan.'
      msg = switch err.code
        when  1 then 'Et sallinut sijainnin jakamista.'
        when  2 then 'Selaimesi ei salli paikannusta; sallimalla sen saat tarkempia suosituksia.'
        when  3 then 'Paikannus epäonnistui, yritä myöhemmin uudelleen.'
        when -1 then 'Laitteesi ei tue paikantamista.'
        when -2
          skip_warning = true
          'Paikassasi ei ole tarjouksia saatavilla.'
        else ''
      merge coord, Config.geo.default_coordinates
      Templates.notice.warning msg+' '+default_msg unless Config.geo.skip_warning or Config.lang isnt 'fi'
      cb coord
    geo_args = timeout: Config.geo.timeout
    if navigator.geolocation?.getCurrentPosition?
      navigator.geolocation.getCurrentPosition geo_success, geo_failed, geo_args
    else
      geo_failed code: -1




# General utils:

# TODO
window.reqAnimFrame = window.requestAnimationFrame or
                      window.webkitRequestAnimationFrame or
                      window.mozRequestAnimationFrame or
                      window.oRequestAnimationFrame or
                      window.msRequestAnimationFrame or
                      (callback)-> window.setTimeout(callback, 1000 / 60)



# Test performance of different functions.
# You can give arguments in any order, with following types:
#   function  is the function being tested
#   number    indicates how many times the function is executed
#   string    is messaga indicating what we are testing
Utils.speed_test = (args...)->
  start = Date.now()
  (args.get_num() or 1000).times args.get_func()
  msg = (args.get_str() or 'Speed test took') + " #{Date.now() - start} ms"
  if Config.is_mobile then alert       msg \
                      else console.log msg
  return


Utils.try = (str, cb)->
  return cb() unless Utils.device.is_mobile() or Config.env is 'production'
  try cb()
  catch err
    err_str = "Error in #{str}: #{err.message}"
    if Utils.device.is_mobile()
      alert err_str
    else if Config.env is 'production'
      Houce.error err_str, err.stack?.split('at ')[1]
    else
      log 'ERROR: '+ err_str, err.stack
  return



#
# Browser detection
#

Utils.device =
  init: ->
    @browser = @searchString(@dataBrowser) or "An unknown browser"
    @version = @searchVersion(navigator.userAgent) or @searchVersion(navigator.appVersion) or "an unknown version"
    @OS = @searchString(@dataOS) or "an unknown OS"

  searchString: (data)->
    for el in data
      dataString = el.string
      dataProp   = el.prop
      @versionSearchString = el.versionSearch or el.identity
      if dataString
        return el.identity if (dataString.indexOf el.subString) != -1
      else if dataProp
        return el.identity

  searchVersion: (dataString)->
    index = dataString.indexOf @versionSearchString
    return if index == -1
    parseFloat dataString.substring index+@versionSearchString.length+1

  is_mobile: ->
    @OS.matches ['iPhone', 'Android', 'Windows Phone']

  banner_height: ->
    switch @OS
      when 'iPhone' then 100
      else 0

  dataBrowser: [
    string: navigator.userAgent
    subString: "Chrome"
    identity: "Chrome"
  ,
    string: navigator.userAgent
    subString: "Android"
    identity: "Android"
  ,
    string: navigator.userAgent
    subString: "iPhone"
    identity: "iPhone"
  ,
    string: navigator.userAgent
    subString: "Series60"
    identity: "Series60"
  ,
    string: navigator.vendor
    subString: "Apple"
    identity: "Safari"
    versionSearch: "Version"
  ,
    string: navigator.userAgent
    subString: "Firefox"
    identity: "Firefox"
  ,
    string: navigator.userAgent
    subString: "MSIE"
    identity: "IE"
    versionSearch: "MSIE"
  ,
    prop: window.opera
    identity: "Opera"
    versionSearch: "Version"
  ]

  dataOS: [
    string: navigator.platform
    subString: "Mac"
    identity: "Mac"
  ,
    string: navigator.userAgent
    subString: "iPhone"
    identity: "iPhone"
  ,
    string: navigator.userAgent
    subString: "Android"
    identity: "Android"
  ,
    string: navigator.userAgent
    subString: "Windows Phone"
    identity: "Windows Phone"
  ,
    string: navigator.platform
    subString: "Win"
    identity: "Windows"
  ,
    string: navigator.platform
    subString: "Linux"
    identity: "Linux"
  ]
Utils.device.init()


