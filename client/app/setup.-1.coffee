
# -1 in setup.-1.coffee means that this file will be
# the last one executed in client_app.js

Houce.init_houce
  # Define client specific configs here. 'global.Config' is merged
  # from this and configs from '/server/config.coffee'.
  config: {}
  # Initialize your data structure here to keep track on what exactly
  # are you storing into the 'global.Data' object.
  data_structure:
    cache_updated:
      coordinates: null
      last_stored: null
    misc:
      coord:
        latitude:  null
        longitude: null
      me: null
  # When structure of the Data changes increment data_version to flush old cached
  # data from all clients. You can also type Houce.init_data() in console of
  # a specific browser to empty its data and cache.
  data_version: 4
  # Name of the main page template; redirects from '/' to this page.
  main_page: 'intro'
  # 'before_open_page' functions is executed for all pages after 'close' event
  # of previous page and before 'open' event of new page.
  before_open_page: ->
    # init #page_content:
    pc = $('#page_content')
    pc.css
      opacity: 0
    pc.attr class: PageHandler.get_page().name
    $('body').scrollTop 0
    # Set app title
    $('head title').text "#{Houce.page_title()} - #{Config.app_name}"
  # 'after_open_page' is executed for every page after 'open' event of new page.
  after_open_page: ->
    reqAnimFrame -> $('#page_content').animate opacity: 1

  # 'init_app' is executed only once when the application starts;
  # if you have some app specific stuff to initialize, here's the place to call them.
  init_app: ->
    $('body').render_top 'header'

