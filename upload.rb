#!/usr/bin/ruby

std_trap = trap("INT"){exit! 130} # no backtrace thanks


# Assumes that the script is run from a symlink in PATH called upload
# Just change line below to the directory of repository for simplicity

$: << `dirname $(readlink $(which upload))`.chomp # no require_relatives
$:.delete("/Users/dovisalomon/Documents/ComputerStuff/ruby/")

require 'tty.rb'
require 'upload_handler.rb'
require 'getoptlong'

opts = GetoptLong.new(
  [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
  [ '--dir', GetoptLong::NO_ARGUMENT ]
)

dir = false
opts.each do |opt, arg|
  case opt
  when '--dir'
    dir = true
  end
end

if dir
  Dir.glob("**/*mkv").each {|file| upload(file)}
else
  odie "Expecting one filename for upload" unless ARGV.size == 1
  file = ARGV.shift
  upload(file)
end