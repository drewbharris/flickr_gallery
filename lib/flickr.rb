require 'json'
require 'net/http'
require 'rufus-scheduler'

module Flickr

	API_KEY = ENV['FLICKR_API_KEY']
	USERNAME = ENV['FLICKR_USERNAME']

	@photosets = nil
	@scheduler = nil

	def self.init(&block)

		# initialize the database
		Db.init

		# load the photos from the database
		restore

		# every 12 hours, fetch the photosets again
		@scheduler = Rufus::Scheduler.new

		@scheduler.in '10s' do
			update
		end

		@scheduler.every '12h' do
			update
		end

		# call the do block
		block.call
	end

	def self.photosets(set_title = nil)
		if set_title
			return @photosets.find {|set| set['short_title'] == set_title}
		else
			return @photosets
		end
	end

	def self.update
		puts 'Updating photos...'
		fetch
		persist
		puts 'Done. Sets:'
		@photosets.each do |set|
			puts set['short_title']
		end
	end

	def self.fetch
		new_photosets = []

		flickr_nsid = get_user_id
		flickr_photosets = get_photosets(flickr_nsid)
		flickr_photosets['photosets']['photoset'].each do |flickr_set|
			set = {
				'id' => flickr_set['id'],
				'title' => flickr_set['title']['_content'],
				'short_title' => flickr_set['title']['_content'].gsub(" ","_").downcase,
				'photos' => [],
				'create_date' => flickr_set['date_create'],
				'description' => flickr_set['description']['_content']
			}
			flickr_photos = get_photos_by_photoset(flickr_set['id'])
			flickr_photos['photoset']['photo'].each do |flickr_photo|
				set['photos'].push({
					'id' => flickr_photo['id'],
					'title' => flickr_photo['title'],
					'url_large' => flickr_photo['url_l'],
					'url_medium' => flickr_photo['url_m'],
					'url_small' => flickr_photo['url_s'],
					'create_date' => flickr_photo['dateupload']
				})
			end
			new_photosets.push(set)
		end

		@photosets = new_photosets.dup
	end

	def self.get_user_id
		uri = URI("http://api.flickr.com/services/rest/?api_key=#{API_KEY}&username=#{USERNAME}&method=flickr.people.findByUsername&format=json")
		body = Net::HTTP.get_response(uri).body
		body.slice!('jsonFlickrApi(')
		return JSON.parse(body[0...-1])['user']['nsid']
	end

	def self.get_photosets(nsid)
		uri = URI("http://api.flickr.com/services/rest/?api_key=#{API_KEY}&method=flickr.photosets.getList&format=json&user_id=#{nsid}")
		body = Net::HTTP.get_response(uri).body
		body.slice!('jsonFlickrApi(')
		return JSON.parse(body[0...-1])
	end

	def self.get_photos_by_photoset(photoset_id)
		uri = URI("http://api.flickr.com/services/rest/?api_key=#{API_KEY}&method=flickr.photosets.getPhotos&format=json&photoset_id=#{photoset_id}&extras=url_l,url_m,url_s,date_upload")
		body = Net::HTTP.get_response(uri).body
		body.slice!('jsonFlickrApi(')
		return JSON.parse(body[0...-1])
	end

	def self.persist
		puts "Persisting to database..."
		@photosets.each do |set|
			Db.query("
				INSERT OR IGNORE INTO photosets (id, create_date, title, short_title, description)
				VALUES (#{set['id']}, #{set['create_date']}, '#{set['title']}', '#{set['short_title']}', '#{set['description']}')
			")
			set['photos'].each do |photo|
				Db.query("
					INSERT OR IGNORE INTO photos (id, photoset_id, title, url_large, url_medium, url_small, create_date)
					VALUES (#{photo['id']}, #{set['id']}, '#{photo['title']}', '#{photo['url_large']}', '#{photo['url_medium']}', '#{photo['url_small']}', #{photo['create_date']})
				")
			end
		end
	end

	def self.restore
		puts "Restoring from database..."

		rows = Db.query("
			SELECT photos.*, photosets.create_date AS photoset_create_date, photosets.title AS photoset_title, photosets.short_title AS photoset_short_title, photosets.description AS photoset_description
			FROM photos JOIN photosets ON photosets.id = photos.photoset_id
		")

		if !rows[0]
			return update
		end

		photosets_by_id = {}

		rows.each do |row|
			if !photosets_by_id[row['photoset_id']]
				photosets_by_id[row['photoset_id']] = {
					'id' => row['photoset_id'],
					'create_date' => row['photoset_create_date'],
					'title' =>row['photoset_title'],
					'short_title' => row['photoset_short_title'],
					'description' => row['photoset_description'],
					'photos' => []
				}
			end
			photosets_by_id[row['photoset_id']]['photos'].push({
				'id' => row['id'],
				'title' => row['title'],
				'url_large' => row['url_large'],
				'url_medium' => row['url_medium'],
				'url_small' => row['url_small'],
				'create_date' => row['create_date']
			})
		end

		@photosets = photosets_by_id.values.dup

	end

end
