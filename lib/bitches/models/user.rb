module Models
	class User
		include DataMapper::Resource

		storage_names[:default] = 'users'

		property :id,          Serial, :key => true
		property :nickname,    String, :required => true, :unique => true
    property :lastfm_name, String
    property :location,    String

    has n, :recommendations
	end
end
