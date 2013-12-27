path = File.expand_path(File.dirname(__FILE__))

require 'rack'
require 'json'
require "#{path}/template"

module Controller
    URL_MAP = {
        '/' => proc {|env| Controller.index(env)}
    }

    def self.index(env)
        request = Rack::Request.new(env)

        body = Template.render(:index, {
            'photosets' => Flickr.photosets
        })
        return [200, {'Content-Type' => 'text/html'}, [body]]
    end

    def self.not_found
        return [404, {'Content-Type' => 'text/plain'}, ["not found"]]
    end

end



