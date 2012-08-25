module Cinch
	module Helpers
		module Admin
	      # Internal: Checks wether the user is an admin or not
	      #
	      # channel - The Cinch::Channel.
	      # user    - The Cinch::User that needs to be authorized.
	      #
	      # Returns a Boolean.
	      def authorized?(channel, user)
	        ['q', 'a', 'o', 'h'].each do |mode|
	          return true if channel.users[user].include? mode
	        end
	        
	        false
	      end
	    end
	end
end
