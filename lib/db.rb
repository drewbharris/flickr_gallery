require 'sqlite3'

module Db

	NAME = 'flickr_gallery.db'

	@connection = nil

	def self.init
		path = File.expand_path(File.join(File.dirname(__FILE__), ".."))
		@connection = SQLite3::Database.new("#{path}/#{NAME}")
		@connection.results_as_hash = true
		@connection.type_translation = true

		begin 
			@connection.execute("SELECT count(*) FROM photosets")
			@connection.execute("SELECT count(*) FROM photos")
		rescue Exception => e
			puts "Creating database..."
			@connection.execute("
				CREATE TABLE photosets (
					id INTEGER PRIMARY KEY UNIQUE,
					create_date INTEGER,
					title TEXT,
					short_title TEXT,
					description TEXT
				)
			")
			@connection.execute("
				CREATE TABLE photos (
					id INTEGER PRIMARY KEY UNIQUE,
					title TEXT,
					url_large TEXT,
					url_medium TEXT,
					url_small TEXT,
					create_date INTEGER
				)
			")
			puts "Done"
		end
	end

	def self.query(query_string)
		return @connection.execute(query_string)
	end

	def self.last_insert_row_id
		return @connection.last_insert_row_id
	end
end