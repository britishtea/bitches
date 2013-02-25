module Models
  class Recommendation
    include DataMapper::Resource

    property :id,             Serial
    property :recommendation, String, :required => true

    belongs_to :user
    belongs_to :source, 'User', :key => true
  end
end
