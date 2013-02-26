module Models
  class Recommendation
    include DataMapper::Resource

    property :id,             Serial
    property :recommendation, Text, :required => true

    belongs_to :user
    belongs_to :source, 'User', :key => true
  end
end
