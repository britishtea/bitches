require 'data_mapper'

require 'bitches/models/user'
require 'bitches/models/bad_word'

DataMapper::Property::String.length(255)

DataMapper.setup :default, ENV['DATABASE_URL']
DataMapper.finalize
DataMapper.auto_upgrade!
