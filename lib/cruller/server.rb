module Cruller
  class Server

    def initialize(app)
      @app = app
    end

    def call(env)
      result = _call(env)
      if result[0] == 404
        @app.call(env)
      else
        result
      end
    end

    private

    def _call(env)
      @path_info = Rack::Utils.unescape(env['PATH_INFO'].to_s)
      # Path must start with the configured path
      return not_found unless @path_info.index(Cruller.path) == 0
      # Invalid path?
      return forbidden if @path_info.include? ".."
      # Try and brew the coffee (may still be 404)
      content = Cruller.brew(File.basename(@path_info))
      if content
        response_for_text content
      else
        not_found
      end
    end

    def forbidden
      @forbidden_response ||= begin
        body = "Forbidden\n"
        [403, {
          'Content-Type'   => 'text/plain',
          'Content-Length' => Rack::Utils.bytesize(body).to_s
        }, [body]]
      end
    end

    def not_found
      @not_found_response ||= begin
        body = "Not Found\n"
        [404, {
          'Content-Type'   => 'text/plain',
          'Content-Length' => Rack::Utils.bytesize(body).to_s
        }, [body]]
      end
    end

    def response_for_text(content)
      headers = {
        'Content-Type' => 'text/javascript',
        'Content-Length' => Rack::Utils.bytesize(content).to_s
      }
      [200, headers, [content]]
    end
  end
end
