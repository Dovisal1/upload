
require 'medialibrary.rb'
require 'episode.rb'
require 'sshwrapper.rb'

def upload(file)

  begin
    ep = Episode.new file
  rescue ArgumentError => e
    odie e.message
  end

  begin
    MediaLibrary::Lib.l.search(ep)
    Server.s.upload ep.file, ep.upload_path
  rescue MediaLibrary::ShowNotFoundError, MediaLibrary::SeasonNotFoundError
    odie "#{ep.upload_path} was not found in the library"
  rescue MediaLibrary::EpisodeDuplicateError
    opoo "#{ep} is already in the library"
  rescue ArgumentError => e
    odie e.message
  rescue Interrupt
    puts "Cancelling..."
  end

end
