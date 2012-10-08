module Cinch
	module Helpers
		# Public: Provides a simple method to check if the command was sent by a
		# channel operator or not.
		module Admin

		private
      # Public: Checks wether the user is an admin in a specific channel or
      # not.
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
