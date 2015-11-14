def args
  @content_type = yield
end

def before
  if request.delete?
    @message = 'delete'
  end
end

def after
  header_hash[Rack::CONTENT_TYPE] = @content_type
  response.write "#{@message} delivered"
end
