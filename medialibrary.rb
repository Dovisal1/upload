require 'sshwrapper.rb'
require 'episode.rb'
require 'extend/string.rb'

class MediaPath
  
  attr_reader :path
  
  def initialize path
    @path = path
    @shows = Server.s.ls path
  end
  
  def view
    ohai @path, @shows
  end
  
  def search show
    trimshow = trim(show)
    @shows.each do |s|
      return s if trim(s) == trimshow
    end
    nil
  end
  
  def looser_search show
    trimmed_show = trim(show)
    @shows.each do |s|
      return s if looser_compare(trimmed_show, trim(s))
    end
    nil
  end
  
  def compare(x,y)
    trim(x) == trim(y)
  end
  
  def looser_compare(x,y)
    x.include?(y) or y.include?(x) 
  end
  
  def trim show
    show.delete('-').downcase.strip_prefix('the')
  end
  
end

class MediaLibrary
  
  attr_reader :library
  
  def initialize paths
    @library = []
    
    Array(paths).each do |path|
      @library << MediaPath.new(path)
    end
  end
  
  def search ep
    show = nil
    
    @library.detect do |media_path|
      show = media_path.looser_search(ep.show)
      ep.media_path, ep.show = media_path.path, show if show
      not show.nil? # break for match
    end
    
    raise ShowNotFoundError if show.nil?
    validate(ep)
  end
  
  def validate e 
    seasons = Server.s.ls e.media_path, e.show
    unless seasons.map{|s| s[/\d+$/i].to_i}.include? e.season_i
      raise SeasonNotFoundError
    end
    
    episodes = Server.s.ls e.media_path, e.show, "Season#{e.season_i}"

    #consider subtitles vs. video files
    if Episode::VIDEO_EXTS.include? e.ext
      episodes.delete_if{|s| Episode::SUBTITLE_EXTS.include? s[/\w\w\w$/] }
    elsif Episode::SUBTITLE_EXTS.include? e.ext
      episodes.delete_if{|s| Episode::VIDEO_EXTS.include? s[/\w\w\w$/] }
    end
    
    if episodes.map{|s| s[/(?<=[ex])\d+/i].to_i}.include? e.episode_i
      raise EpisodeDuplicateError
    end
  end
  
  def view
    @library.each do |p|
      p.view
    end
  end
  
  ###################
  #  Error classes  #
  ###################

  class LibraryError < ArgumentError; end

  class DuplicateEntryError < LibraryError; end

  class NotFoundError < LibraryError; end

  class ShowNotFoundError < NotFoundError; end

  class SeasonNotFoundError < NotFoundError; end

  class EpisodeDuplicateError < LibraryError; end

end

