def args content_type = 'text/html'
  @content_type = content_type
end

def after
  unless Rack::Utils::STATUS_WITH_NO_ENTITY_BODY.include? @status
    header_hash[Rack::CONTENT_TYPE] ||= @content_type
  end
end
