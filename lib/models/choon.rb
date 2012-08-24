module Models
	class Choon
		include DataMapper::Resource
	
		storage_names[:default] = 'choons'
	
		property :id,         Serial
		property :url,        String, :required => true, :unique => true
		property :created_at, DateTime, :default => proc { Time.now }
	
		has n, :tags, :through => Resource
		belongs_to :user
	
		# Public: Gets a random choon. Filters on tags if needed.
		#
		# tag - A tag String (default: nil).
		#
		# Returns a Choon.
		def self.random(tag = nil)
			#
		end
	end
end