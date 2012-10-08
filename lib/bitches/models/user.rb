module Models
	class User
		include DataMapper::Resource

		storage_names[:default] = 'users'

		property :id,         Serial, :key => true
		property :nickname,   String, :required => true, :unique => true

		has n, :choons
	end
end
