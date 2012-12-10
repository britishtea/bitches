module Models
  class Badword
    include DataMapper::Resource
  
    storage_names[:default] = 'bad_words'
  
    property :id,   Serial
    property :word, String, :required => true, :unique => true
  end
end
