module Models
  class Video
    include DataMapper::Resource
  
    storage_names[:default] = 'videos'
  
    property :id,         Serial, :key => true
    property :url,        String, :required => true, :unique => true
    property :created_at, DateTime, :default => proc { Time.now }
    property :updated_at, DateTime, :default => proc { Time.now }
  
    belongs_to :user
  end
end