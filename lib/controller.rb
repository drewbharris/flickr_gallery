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

        set_title = request.path.match(/^\/set\/(.*)/)[1]
        photoset = Flickr.photosets(set_title)

        if !photoset
            return not_found
        end

        body = Template.render(:set, {
            'photoset' => photoset
        })
        return [200, {'Content-Type' => 'text/html'}, [body]]
    end

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



