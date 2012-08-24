desc 'Run the bot'

task :run do
	environment = ENV['ENVIRONMENT'] || 'development'
	Rake::Task["run:#{environment}"].invoke
end

namespace :run do
	desc 'Run in development mode'

	task :development do
		ENV['ENVIRONMENT'] = 'development'
		ENV['DATABASE_URL'] = "#{Dir.pwd}/../indie-gallery/data/database.sqlite"
		`bundle exec ruby -I lib lib/bot.rb`
	end

	desc 'Run in production mode'

	task :production do
		ENV['ENVIRONMENT'] = 'production'
		`bundle exec ruby -I lib lib/bot.rb`
	end

	task :stop do
		`kill \`cat tmp/bitches.pid\``
	end
end