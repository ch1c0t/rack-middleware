def app_from_file file
  name = File.basename file, '.rb'
  body = IO.read file

  eval %!
    class #{name}
      include Rack::Middleware
      #{body}
    end
  !, TOPLEVEL_BINDING
end
