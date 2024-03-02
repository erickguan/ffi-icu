# frozen_string_literal: true

class String
  alias bytesize length unless method_defined?(:bytesize)

  alias jlength length unless method_defined?(:jlength)
end
