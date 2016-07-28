class String
  def strip_prefix(prefix)
    start_with?(prefix) ? self[prefix.length..-1] : self
  end
end