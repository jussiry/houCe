

# Use `dict('keyword')` for translations. Uses Config.lang to choose the right translation.

global.dict = (key, s1)->
  return null unless key?
  if s1 then Utils.dictionary[key][Config.lang].replace '%s', s1 \
        else Utils.dictionary[key][Config.lang]


Utils.dictionary =
  # translation_keyword:
  #   lang1_keyword: transtaltion
  #   ...
  page:
    en: 'page'
    fi: 'sivu'
  welcome_title:
    en: "Welcome to houCe!"
    fi: "Tervetuloa houCe:een!"

  # SPECIAL:
  
  # weekday_arr is currently not used anywhere, but just to show that you can
  # also store more comples stuff in here.
  weekday_arr:
    en: ['mo', 'tu', 'we', 'th', 'fr', 'sa', 'su']
    fi: ['ma', 'ti', 'ke', 'to', 'pe', 'la', 'su']
  