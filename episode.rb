
# require 'extend/file.rb'

class Episode

  include Comparable
  
  SUBTITLE_EXTS = ['srt', 'sub', 'ass']
  VIDEO_EXTS = ['mp4', 'mkv', 'avi']
  VALID_EXTS = VIDEO_EXTS + SUBTITLE_EXTS
  REGEX = [
    /(?<show>.+?)s(?<season>\d\d)[\Wx]*e(?<episode>\d+).*?\.(?<ext>\w\w\w)$/i,
    /(?<show>.+?)\.(?<season>\d+)x(?<episode>\d+)\..*?\.(?<ext>\w\w\w)$/i,
    /(?<show>.+?)\.(?<season>\d)(?<episode>\d\d)\..*?\.(?<ext>\w\w\w)$/i
  ]
  
  attr_accessor :show, :episode, :ext, :filename, :media_path, :file
  
  def initialize file
    @file = file
    @filename = File.basename file
    extract()
  end

  def <=>(other)
    return nil unless other.instance_of? Episode

    show_compare = self.show <=> other.show
    episode_compare = self.episode_i <=> other.episode_i

    show_compare == 0 ? episode_compare : show_compare
  end
  
  def upload_path
    File.path_from_root media_path, show, "Season#{season_i}"
  end
  
  def to_s
    "#{show} <S#{season_s}E#{episode_s}>"
  end

  def show
    @show.capitalize
  end
  
  def season_i
    @season.to_i
  end
  
  def episode_i
    @episode.to_i
  end
  
  def season_s
    @season.rjust(2,'0')
  end
  
  def episode_s
    @episode.rjust(2,'0')
  end
  
  def fresh_file
    "#{show}.S#{season_s}E#{episode_s}.#{ext}"
  end
  
  private
  
  def extract

    regex = REGEX.dup

    loop do
      re = regex.shift
      if re.nil?
      	# We have used up all regex
        raise ArgumentError, "Filename must follow pattern: <showname>S##E##.<ext>"
      end
      re =~ @filename
      break unless $~.nil?
    end

    #Extracting data from the pattern
    @show = $~[:show]
    @season = $~[:season]
    @episode = $~[:episode]
    @ext = $~[:ext]
    
    trim()
    
    if @filename.upcase.include? "SAMPLE"
      raise ArgumentError, "#{fresh_file} is a sample"
    end
    
    unless VALID_EXTS.include? @ext
      raise ArgumentError, "#{ext} is not a valid filename extension"
    end
  end
  
  def trim
    @show.gsub!(/[\W_\.]/,'-') #Replace crap with dashes
    @show.gsub!(/\d{4}/, '') #Remove a year stuck in the name
  
    @show.chomp!('-') until show[-1] != '-' #Remove extra dashes off the end
    @show = @show.split('-').map{|s| s.capitalize}.join('-') #Capitalize each word
  end
  
end