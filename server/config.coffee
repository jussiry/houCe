

# GENERAL LIBRARIES:
require 'sugar'
Object.extend()

# APP SPECIFIC LIBRARIES:
require "../common/common_utils.coffee"

# CONFIG:
global.config =
  app_name: __dirname.split('/').at -2 # assumes config.coffee is in first level folder (e.g. /server)
  app_dir:  __dirname.split('/').to(-1).join('/') + '/'
  port:     process.env.PORT or 3001
  apis:
    fb:
      permissions: 'offline_access'
      auth_url: 'https://m.facebook.com/dialog/oauth'
      get_url: 'https://graph.facebook.com' # TODO: change get_url to url (same as Kovalo config)


(config.by_host = {})["localhost:#{config.port}"] =
  apis:
    fb:
      app_id: 278442548891895 # If you use Facebook API, change this to your fb_app_id; otherwise you can remove it.
      auth_url: 'https://www.facebook.com/dialog/oauth'
      docs: 'http://developers.facebook.com/docs/reference/api/'
      get_url: 'https://graph.facebook.com' # TODO: change get_url to url (same as Kovalo config)
      permissions: 'user_likes'
    google:
      app_id: '679211380191.apps.googleusercontent.com' # Change this to your own google app id.
      auth_url: "https://accounts.google.com/o/oauth2/auth"
      docs: 'https://developers.google.com/+/api/'
      get_url: 'https://www.googleapis.com/plus/v1' # TODO: change get_url to url (same as Kovalo config)
      permissions: encodeURIComponent 'https://www.googleapis.com/auth/plus.me'
  env:  'development'
  lang: 'en'


config.js_files = [
 #[compress?, file_path]
  [true, "lib/modernizr.custom.js"]
  [true, "lib/jquery-1.7.1.min.js"]
  [true, "lib/jquery.animate-enhanced.min.js"]
  [true, "lib/sugar-1.2.5.min.js"]
  [false, "lib/coffeekup.js"]
  [true, 'templates.js']
  [true, 'client_app.js']
]

config.env = 'production' if process.argv[2] is 'production'
