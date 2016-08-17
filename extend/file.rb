class File
  class << self

    def path_from_root(*pieces)
      pieces.map!{|x| x.to_s}.delete("")
      File.join "/", *pieces
    end

  end
end
