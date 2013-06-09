module Nyara
  class Response
    def initialize request
      @status = 200
      @header = HeaderHash.new
      @header._aset 'Connection', 'close'
      @header._aset 'Content-Type', 'text/plain; charset=UTF-8'
      @extra_header = []
      @request = request
    end
    attr_reader :status, :header, :extra_header

    def send_data data
      @request.send_data data.to_s
    end

    def render_header
      data = [HTTP_STATUS_FIRST_LINES[@status], *@extra_header]
      @header.each do |k,v|
        data << "#{k}: #{v}\r\n"
      end
      data << "\r\n"
      @request.send_data data.join
    end
  end
end
