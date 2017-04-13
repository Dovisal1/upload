
require_relative 'medialibrary.rb'
require_relative 'episode.rb'
require_relative 'sshwrapper.rb'
require_relative 'tty.rb'

def upload(file)
  ep = Episode.new file
  Server.load
  MediaLibrary::Lib.l.search(ep)
  Server.s.upload ep.file, ep.upload_path
rescue SSHWrapper::ERRCONN => e
  odie e.message
rescue MediaLibrary::ShowNotFoundError, MediaLibrary::SeasonNotFoundError
  odie "#{ep.upload_path} was not found in the library"
rescue MediaLibrary::EpisodeDuplicateError
  opoo "#{ep} is already in the library"
rescue ArgumentError => e
  odie e.message
rescue Interrupt
  puts "Cancelling..."
end
