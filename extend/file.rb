require 'extend/string'

class File
  class << self
    def path_from_root *pieces
      path = "/"
      pieces.each do |piece|
        next if piece.nil?
        path += piece.to_s.chomp("/").strip_prefix("/")
        path += "/"
      end
      path
    end
  end
end
      