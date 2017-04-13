#!/usr/bin/ruby

std_trap = trap("INT"){exit! 130} # no backtrace thanks

require_relative 'upload_handler.rb'

DEF_DIR = File.join(Dir.home, "Torrents")
EXTENSIONS = ['mkv', 'mp4', 'avi', "srt"]

case ARGV.size
when 0
  Dir.glob(File.join DEF_DIR, "**/*{#{EXTENSIONS.join(",")}}") {|file| upload(file)}
else
  ARGV.each do |arg|
    if File.directory? arg
      # For some odd reason I must change directories
      # I can't glob directly
      dir = Dir.getwd
      Dir.chdir arg
      Dir.glob("**/*{#{EXTENSIONS.join(",")}}") {|file| upload(file)}
      Dir.chdir dir
    else
      upload(arg)
    end
  end
end
