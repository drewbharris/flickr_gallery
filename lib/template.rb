require 'liquid'

module Template

	@template_dir = File.expand_path(File.join(File.dirname(__FILE__), "..", "templates"))

	def self.render(template_name, vars)
        template = File.read("#{@template_dir}/#{template_name.to_s}.liquid")
        return Liquid::Template.parse(template).render(vars)
    end
end