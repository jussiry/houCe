

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



Utils.get_geolocation = (recalculate=false, cb)->

  cb = recalculate if recalculate.constructor is Function

  coord = Data.misc.coord
  if Houce.cache_valid 'coordinates' # coord.updated? and Date.now() - coord.updated < 20.minutes() and not recalculate
    cb coord
  else
    geo_success = (gp)->
      coord.latitude  = gp.coords.latitude
      coord.longitude = gp.coords.longitude
      Data.cache_updated.coordinates = Date.now()
      cb coord
    geo_failed = (err)->
      alert 'Failed to retrieve geolocation'
      cb null
    geo_args = timeout: Config.get_geo_timeout
    if navigator.geolocation?.getCurrentPosition?
      navigator.geolocation.getCurrentPosition geo_success, geo_failed, geo_args
    else
      geo_failed code: -1

