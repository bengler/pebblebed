# A simple echo service that emulates a pebble for the purpose of
# testing http interactions. The mock pebble is mounted at
# http://localhost:8666/api/mock/v1

require 'webrick'
require 'yajl/json_gem'

class MockPebble
  class Servlet < WEBrick::HTTPServlet::AbstractServlet

    def do_GET(request, response)
      status, content_type, body = do_stuff_with(request)

      response.status = status
      response['Content-Type'] = content_type
      response.body = body
    end

    def do_POST(request, response)
      status, content_type, body = do_stuff_with(request)

      response.status = status
      response['Content-Type'] = content_type
      response.body = body
    end

    def do_PUT(request, response)
      status, content_type, body = do_stuff_with(request)

      response.status = status
      response['Content-Type'] = content_type
      response.body = body
    end

    def do_DELETE(request, response)
      status, content_type, body = do_stuff_with(request)

      response.status = status
      response['Content-Type'] = content_type
      response.body = body
    end

    def do_stuff_with(request)
      return 200, "application/json", request.meta_vars.merge("BODY" => request.body).to_json
    end
  end

  def start
    @server = WEBrick::HTTPServer.new(:Port => 8666, :AccessLog => [])
    @server.mount "/api/mock/v1", Servlet
    @server_thread = Thread.new do
      @server.start
    end
  end

  def shutdown
    @server_thread.kill
  end

end
