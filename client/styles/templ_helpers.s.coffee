
# These helper functions and variables are available to objects
# defined in templates (mainly for @style).
# TODO: store them also in Tempalates.helpers ?
# TODO: make these availabe for @html and @init? Would it slow down rendering?


# COLORS

@font_black = '#333'
@font_gray  = '#555'
@light_gray = '#aaa'



# EXTRA CLASSES

@secondary_font =
  fontFamily: 'Helvetica Neue, Helvetica'
  fontWeight: 'normal'



# FUNCTIONS


@borderRadius = (str)->
  MozBorderRadius:    str
  WebkitBorderRadius: str
  borderRadius:       str

@boxShadow = (str, str2)->
  str = "#{str}, #{str2}" if str2?
  MozBoxShadow:    str
  WebkitBoxShadow: str
  boxShadow:       str


# @vgradient (from, to)->
#   background: -webkit-gradient(linear, 0 0, 0 100%, from(@from), to(@to));
#   background: -moz-linear-gradient(90deg, @to, @from);


@transition = (str)->
  str = "all #{str} ease-out"
  WebkitTransition: str
  MozTransition:    str
  OTransition:      str
  MSTransition:     str
  transition:       str
