class String
  unless method_defined?(:bytesize)
    alias_method :bytesize, :length
  end

  unless method_defined?(:jlength)
    alias_method :jlength, :length
  end
end
