module Bitches
  module Models
  	class User
  		include DataMapper::Resource

  		storage_names[:default] = 'users'

  		property :id,          Serial, :key => true
  		property :nickname,    String, :required => true, :unique => true
      property :lastfm_name, String
      property :location,    String

      def self.find_user(nickname)
        result = first(:conditions => ["LOWER(nickname) = ?", nickname.downcase])
        
        result || create(:nickname => nickname)
      end
  	end
  end
end
