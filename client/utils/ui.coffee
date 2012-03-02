# UI related utils:


Utils.days_remaining = (end_time, short)->
  end_time  = Date.create end_time if end_time.constructor == String
  time_left = end_time - Date.now()
  days_left = time_left / 1000 / 60 / 60 / 24
  days_left.round()

Utils.time_left = (end_time)->
  end_time  = Date.create end_time if end_time.constructor == String
  if    end_time.minutesFromNow() < 60 then "#{end_time.minutesFromNow()} min"
  else if end_time.hoursFromNow() < 24 then "#{end_time.hoursFromNow()} h"
  else "#{end_time.daysFromNow()} #{if Config.lang is 'fi' then 'pv' else 'd'}"



Utils.page_title = (path)->
  if path.constructor == String then page_str = path
  else page_str = path[0] + ifs ( path[1]? and not path[1].parsesToNumber() ), '__' + path[1] # Object.isNaN path[1].toNumber()
  Config.page_titles[page_str]


