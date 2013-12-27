require 'json'
require 'net/http'
require 'rufus-scheduler'

module Flickr

	API_KEY = ENV['FLICKR_API_KEY']
	USERNAME = ENV['FLICKR_USERNAME']

	@photosets = nil
	@scheduler = nil

	def self.init(&block)

		# get all of the [public] photos for a certain username and load them into @photosets
		fetch

		# @todo: store the photos in a local database

		# every 12 hours, fetch the photosets again
		@scheduler = Rufus::Scheduler.new
		@scheduler.every '12h' do
			puts 'Updating photos...'
			fetch
		end

		# call the do block
		block.call
	end

	def self.photosets
		return @photosets
	end

	def self.fetch
		@photosets = {}

		flickr_nsid = get_user_id
		flickr_photosets = get_photosets(flickr_nsid)
		flickr_photosets['photosets']['photoset'].each do |flickr_set|
			set_id = flickr_set['id']
			@photosets[set_id] = {
				'title' => flickr_set['title']['_content'],
				'short_title' => flickr_set['title']['_content'].gsub(" ","_").downcase,
				'photos' => [],
				'create_date' => flickr_set['date_create'],
				'description' => flickr_set['description']['_content']
			}
			flickr_photos = get_photos_by_photoset(flickr_set['id'])
			flickr_photos['photoset']['photo'].each do |flickr_photo|
				@photosets[set_id]['photos'].push({
					'id' => flickr_photo['id'],
					'title' => flickr_photo['title'],
					'url' => flickr_photo['url_l']
				})
			end
		end
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
		uri = URI("http://api.flickr.com/services/rest/?api_key=#{API_KEY}&method=flickr.photosets.getPhotos&format=json&photoset_id=#{photoset_id}&extras=url_l")
		body = Net::HTTP.get_response(uri).body
		body.slice!('jsonFlickrApi(')
		return JSON.parse(body[0...-1])
	end

end
