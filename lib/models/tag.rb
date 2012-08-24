module Models
	class Tag
		include DataMapper::Resource
	
		storage_names[:default] = 'tags'
	
		property :id,   Serial
		property :name, String, :required => true, :unique => true
	
		has n, :choons, :through => Resource
	end
end