
require 'highline/import'
require 'shellwords'
require 'net/sftp'
require 'extend/file.rb'
require 'tty.rb'
require 'timeout'
require 'resolv'

class SSHWrapper

  attr_reader :user, :host

  def initialize args
    @user = args[:user]
    @host = args[:host]

    unless @user and @host
      raise ArgumentError,
      "A user and hostname are required to establish a connection"
    end

    @conn = Net::SFTP.start @host, @user
  end

  def upload file, destpath
    uploadhandler file, destpath
  end

  def uploadhandler file, destpath
    ohai("Uploading", destpath)
    system "scp #{escape file} #{user}@#{host}:#{escape destpath}"
  end

  def uploadhandler2 file, destpath

    #  Nice idea, but Net::SFTP is too slow

    require 'ruby-progressbar'
    require 'filesize'

    if @conn.file.directory?(destpath)
      destpath = File.join(destpath, File.basename(file) )
    end

    handler = ProgressHandler.new
    @conn.upload!(file, destpath, progress: handler)

  rescue Interrupt
      # If download is interrupted we want to
      # remove the partially downloaded file
      handler.log "Cancelling..."
      @conn.remove!(destpath)
  end

  def entries path
    @conn.dir.entries(path).map{|e|e.name}
  end

  def ls *dir
    case dir.size
    when 0
      entries(".") # Home Directory, no need to raise error
    else
      entries(File.path_from_root *dir)
    end
  end

  alias run exec
  alias e exec

  private

  def escape(txt)
    Shellwords.escape(txt)
  end

  class ERRCONN < StandardError
  end

end

class Server

  HOSTS = ['doviserver', 'dovi.ddns.net'] # hosts to try, in order of precedence
  TIMEOUT = 5
  USER = 'dovi' # This should be from a config file

  def self.s
    if @server.nil?
      try = 0
      begin
        host = HOSTS[try]
        print "Trying #{Resolv.getaddress host}..."
        Timeout::timeout(TIMEOUT){@server = SSHWrapper.new user: USER, host: host}
        puts "done"
      rescue Timeout::Error
        puts "failed"
        try += 1
        if try == HOSTS.size
          raise SSHWrapper::ERRCONN, "Could not connect to the server"
        end
        retry
      end
    end
    @server
  end

  def self.load
    if @server.nil?
      Server.s
    end
    @server
  end

end


###################
#   Helper Class  #
###################

class ProgressHandler
  def on_open(uploader, file)
    ohai("Uploading",
      "#{File.basename file.remote} #{Filesize.from("#{file.size} B").pretty}")
    start_progress(file.remote, file.size)
  end

  def on_put(uploader, file, offset, data)
    @progbar.progress += data.length
  end

  def start_progress(remotefile, filesize)
    @progbar = ProgressBar.create(
      #title: remotefile,
      length: Tty.width,
      total: filesize,
      format: "%e |%b>>%i| %p%% %RMB/s",
      rate_scale: ->rate{rate / 1048576},
      smoothing: 0.75
    )
  end

  def log str
    @progbar.log str
  end
end
