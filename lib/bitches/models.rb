require 'bitches/models/picture'
require 'bitches/models/user'
require 'bitches/models/video'
require 'bitches/models/bad_word'
require 'bitches/models/recommendation'

# Assume DataMapper is already required.
DataMapper::Property::String.length(255)
