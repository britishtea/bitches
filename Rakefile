desc 'Run the bot'

task :run do
	environment = ENV['ENVIRONMENT'] || 'development'
	Rake::Task["run:#{environment}"].invoke
end

namespace :run do
	desc 'Run in development mode'

	task :development do
		ENV['ENVIRONMENT'] = 'development'
		ENV['DATABASE_URL'] = "sqlite://#{Dir.pwd}/../bitches-gallery/test_database"
		`bundle exec ruby -I lib app.rb`
	end

	desc 'Run in production mode'

	task :production do
		ENV['ENVIRONMENT'] = 'production'
		`bundle exec ruby -I lib app.rb`
	end

	task :stop do
		`kill \`cat tmp/bitches.pid\``
	end
end
