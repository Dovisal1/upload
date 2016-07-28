#!/usr/bin/ruby

std_trap = trap("INT"){exit! 130} # no backtrace thanks

require 'tty.rb'
require 'episode.rb'
require 'medialibrary.rb'
require 'sshwrapper.rb'

MEDIA_PATHS = [
  "/media/green/tv",
  "/media/pink/tv",
  "/media/black/tv",
  "/media/pink/Anime"
]

begin
  raise ArgumentError, "Expecting one filename for upload" unless ARGV.size == 1
  file = ARGV.first
  ep = Episode.new file
rescue ArgumentError => e
  odie e.message
end

begin
  Server.load
rescue SSHWrapper::ERRCONN => e
  odie e.message
end

begin
  library = MediaLibrary.new(MEDIA_PATHS)
  # library.view
  library.search(ep)
  trap("INT", std_trap) # restore default CTRL-C handler, for the upload
  Server.s.upload ep.file, ep.upload_path
rescue MediaLibrary::ShowNotFoundError, MediaLibrary::SeasonNotFoundError
  odie "#{ep.upload_path} was not found in the library"
rescue MediaLibrary::EpisodeDuplicateError
  odie "#{ep} is already in the library"
rescue ArgumentError => e
  odie e.message
rescue Interrupt
  puts "Cancelling..."
end
