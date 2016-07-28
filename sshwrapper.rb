
require 'shellwords'
require 'net/sftp' rescue odie "net-sftp gem is required"
require 'extend/file'
require 'tty.rb'
require 'timeout'

class SSHWrapper
  
  attr_reader :user, :host
  
  def initialize args
    @user = args[:user]
    @host = args[:host]
    
    unless @user and @host
      raise ArgumentError,
      "A user and hostname are required to establish a connection"
    end
    
    @conn = Net::SFTP.start(@host, @user)
    #UploadLog.log.debug "Establish connection to #{@user}@#{@host}"
  end
  
  def exec cmd
    ls cmd
  end
  
  def upload file, destpath
    uploadhandler file, destpath
  end
  
  def uploadhandler file, destpath
    ohai("Uploading")
    system "scp #{escape file} #{user}@#{host}:#{escape destpath}"
    #UploadLog.log.debug "#{file} upload to #{destpath}"
  end
  
  def uploadhandler2 file, destpath
    
    #  Nice idea but too slow
    
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
  
  def self.s
    if @server.nil?
      try = 0
      begin
        host = HOSTS[try]
        Timeout.timeout(TIMEOUT){@server = SSHWrapper.new user: 'dovi', host: host}
        
      rescue Timeout::Error
        #UploadLog.log.error "Unable to establish connection to #{HOSTS[try]}"
        
        try += 1
        if try == HOSTS.size
          #UploadLog.log.fatal "Unable to establish connection to any server"
          raise SSHWrapper::ERRCONN, "Could not connect to the server"
        end
        
        retry
      end
    end
    @server
  end
  
  def self.load
    if Server.s then true else false end
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
  
