path = File.expand_path(File.dirname(__FILE__))

require 'rack'
require 'json'
require "#{path}/template"
require 'pp'

module Controller
    URL_MAP = {
        '/admin' => proc {|env| Controller.admin(env)},
        '/api/v1/admin/update' => proc {|env| API.admin_update(env)},
        '/set' => proc {|env| Controller.set(env)},
        '/' => proc {|env| Controller.index(env)}
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

        # year and set title, or year, or index
        if request.path.match(/^\/(\d{4})\/(.*)/)
            set_title = request.path.match(/^\/(\d{4})\/(.*)/)[2]
            photoset = Flickr.photosets(set_title)
            body = Template.render(:set, {
                'photoset' => photoset
            })
        elsif request.path.match(/^\/(\d{4})/)
            year = request.path.match(/^\/(\d{4})/)[1]
            photosets = Flickr.photosets(nil, year)
            body = Template.render(:index, {
                'photosets' => photosets
            })
        else
            body = Template.render(:index, {
                'photosets' => Flickr.photosets
            })
        end

        return [200, {'Content-Type' => 'text/html'}, [body]]
    end

    def self.admin(env)
        request = Rack::Request.new(env)

        body = Template.render(:admin, {})

        return [200, {'Content-Type' => 'text/html'}, [body]]
    end

    def self.not_found
        return [404, {'Content-Type' => 'text/plain'}, ["not found"]]
    end

end

module API
    def self.admin_update(env)
        Flickr.update
        return [200, {'Content-Type' => 'application/json'}, [{
            'ok' => true
        }.to_json]]
    end
end



