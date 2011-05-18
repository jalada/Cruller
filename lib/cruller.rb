begin
  require 'coffee-script'
rescue ExecJS::RuntimeUnavailable => e
  warn "No JavaScript runtime, won't be compiling"
end

# Singleton module wrapper around the Handler class. Methods available in the
# handler class are available to the Cruller singleton.
module Cruller

  autoload :Server, 'cruller/server'

  private
  def self.handler(options={})
    @handler ||= Cruller::Handler.new(options)
  end

  def self.method_missing(method, *args, &block)
    handler.send(method, *args, &block)
  end

  def self.respond_to?(method, include_private = false)
    handler.respond_to?(method, include_private) || super(method, include_private)
  end

  # Do not use the Handler class directly. Instead, call its methods using 
  # `Cruller.method_name`.
  class Handler

    attr_accessor :path

    def initialize(options={})
      configure(options)
    end

    # Configure Cruller, valid options are:
    #
    # - *source*: the source directory
    # - *destination*: the destination directory
    # - *path*: The URL path of the Javascript files (optional, required when
    #   using Cruller with a Rack app) default `/javascripts`
    # - *compile*: when to compile CoffeeScript. Options are always, auto
    #   (based on modified time) and never (only use cache)
    def configure(options={})
      # Location of the coffeescript files, default is current directory + 
      # coffeescripts
      @source = options[:source] || File.join(".", "coffeescripts")
      # Where to put the compiled files, default is current directory + 
      # javascripts. In development this should not be a location that will
      # be blindly served up by your web server because otherwise
      # you will only ever see the cached copy. On production, that's acceptable
      # obviously
      @destination = options[:destination] || File.join(".", "javascripts")
      if options[:path]
        @path = options[:path][0] == "/" ? options[:path] : "/" + options[:path]
      else
        @path = "/javascripts"
      end
      # Always compile? Never compile? Automatically compile?
      if defined?(CoffeeScript)
        @compile = options[:compile] || "auto"
      else
        @compile = "never"
      end
    end

    # Brew a CoffeeScript file
    #
    # @param [String] coffee the CoffeeScript file in your **source**
    # @return [String] the compiled output
    def brew(coffee)
      base = coffee.sub(/\.(coffee|js)$/, "")
      coffee = "#{base}.coffee"
      js = "#{base}.js"

      source = File.join(@source, coffee)
      destination = File.join(@destination, js)

      # Does the source exist?
      if File.file?(source)
        case @compile
        when "always"
          render_and_brew(coffee, destination)
        when "auto"
          if !File.file?(destination)
            render_and_brew(coffee, destination)
          elsif File.mtime(destination) < File.mtime(source)
            render_and_brew(coffee, destination)
          else
            read_file(destination)
          end
        when "never"
          read_file(destination)
        end
      else
        read_file(destination)
      end
    end

    private
    def read_file(file)
      if File.file?(file)
        File.open(file, "r").read
      else
        return false
      end
    end

    def render_and_brew(coffee, destination)
      source = File.join(@source, coffee)
      
      output = CoffeeScript.compile(File.open(source).read)
      File.open(destination, 'w') do |file|
        file << output
        file.close
      end
      return output

    end
  end
end
