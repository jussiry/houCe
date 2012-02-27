
# GENERAL LIBRARIES:
require 'sugar'
Object.extend()

# APP SPECIFIC LIBRARIES:
require "../common/common_utils.coffee"

# CONFIG:
global.config =
  app_name: __dirname.split('/').at -2 # assumes config.coffee is in first level folder (e.g. /server)
  port:     process.env.PORT or 3001

config.app_dir = __dirname.split('/'+config.app_name+'/')[0]+'/'+config.app_name+'/'


# Use environment variable 'houce_mode' to determine deployment configuration:
config.merge switch process.env.houce_mode
  when 'production_fi'
    env:  'production'
    lang: 'fi'
  when 'production_en'
    env:  'production'
    lang: 'en'
  else
    # localhost development
    env:  'development'
    lang: 'en'