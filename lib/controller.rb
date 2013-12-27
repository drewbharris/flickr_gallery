path = File.expand_path(File.dirname(__FILE__))

require 'rack'
require 'json'
require "#{path}/template"
require 'pp'

module Controller
    URL_MAP = {
        '/' => proc {|env| Controller.index(env)},
        '/set' => proc {|env| Controller.set(env)},
    }

    def self.set(env)
        request = Rack::Request.new(env)

        set_name = request.path.match(/^\/set\/(.*)/)
        body = Template.render(:set, {
            'photosets' => Flickr.photosets(set_name)
        })
        return [200, {'Content-Type' => 'text/html'}, [body]]
    end

    def self.index(env)
        request = Rack::Request.new(env)

        return [200, {'Content-Type' => 'text/html'}, ["hey"]]
    end

    def self.not_found
        return [404, {'Content-Type' => 'text/plain'}, ["not found"]]
    end

end



