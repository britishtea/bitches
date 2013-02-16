module Cinch
  module Plugins
    class Fun
      include Cinch::Plugin

      STDS = ['aids', 'chlamydia', 'syphilis', 'hepatitis B', 'herpes', 
        'crabs', 'pubic lice', 'chancroid', 'genital warts', 'gonorrhea', 
        'intestinal parasites']

      CHANCE = 0.10

      listen_to :nick, :method => :bitches
      listen_to :join, :method => :bitches_join

      match /makes .*love to (all of )?#?indie$/i, :method => :aids,
                                                   :react_on => :action,
                                                   :use_prefix => false
      #match /bitches\.?/i, :method => :response, :use_prefix => false
      
      def bitches(m)
        return if rand < CHANCE

        if m.user.last_nick == 'zz_xrated' && m.user.nick == 'xrated'
          Channel('#indie').send 'Bitches.'
        end
      end

      def bitches_join(m)
        return unless m.user.nick == 'xrated' && rand < CHANCE
        
        if rand < 0.25
          Channel('#indie').send 'Hi xrated. :D'
        else
          Channel('#indie').send 'Bitches.'
        end
      end

      def response(m)
        return unless m.user.nick == 'xrated'
        
        m.reply "Yes? What is it #{m.user.nick}?" if rand < 0.05
      end

      def aids(m)
        m.channel.action "has #{STDS.sample} lulz" if rand < 0.55
      end
    end
  end
end
