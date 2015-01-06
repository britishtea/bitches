require "sequel"

Sequel.connect(ENV["DATABASE_URL"])

module Bitches
  module Models
    class Badword < Sequel::Model(:bad_words)
      plugin :validation_helpers
      
      def validate
        super

        validates_presence [:word]
        validates_unique   [:word]
      end
    end

    class User < Sequel::Model(:users)
      plugin :validation_helpers
      
      def self.by_nickname(nickname)
        result = find(Sequel.ilike(:nickname, nickname))

        if result.nil?
         result = create(:nickname => nickname)
        end

        return result
      end

      def validate
        super

        validates_presence [:nickname]
        validates_unique   [:nickname]
      end
    end
  end
end
