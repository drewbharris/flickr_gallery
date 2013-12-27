path = File.expand_path(File.dirname(__FILE__))

require 'rack'
require 'logger'
require "#{path}/lib/controller"
require "#{path}/lib/flickr"
require 'rack/handler'

LOGFILE = "#{path}/rack.log"
PORT = 9292

# set up the app
controller = Rack::URLMap.new(Controller::URL_MAP)
builder = Rack::Builder.new do
	use(Rack::CommonLogger)
	use(Rack::Static, {:urls => ["/img", "/js", "/css"], :root => "public"})
	Logger.new(LOGFILE)
	run(controller)
end

# initialize flickr photos in memory before starting the app
Flickr.init do 
	Rack::Handler.get(:puma).run(builder, :Port => PORT)
end


