#!/usr/bin/ruby

std_trap = trap("INT"){exit! 130} # no backtrace thanks

# Assumes that the script is run from a symlink in PATH called upload
# Can change line below to the directory of repository for simplicity

$: << `dirname $(readlink $(which upload))`.chomp # no require_relatives
$:.delete("/Users/dovisalomon/Documents/ComputerStuff/ruby/")

require 'tty.rb'
require 'upload_handler.rb'
require 'medialibrary.rb'
require 'sshwrapper.rb'

case ARGV.size
when 0
  Dir.glob("**/*{mkv,mp4,avi}").each{|file| upload(file)}
else
  ARGV.each{|file| upload(file)}
end
