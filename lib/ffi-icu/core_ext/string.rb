class String
  unless method_defined?(:bytesize)
    alias_method :bytesize, :length
  end
end
