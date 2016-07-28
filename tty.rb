
class Tty
  class << self
    def tick
      # necessary for 1.8.7 unicode handling since many installs are on 1.8.7
      @tick ||= ["2714".hex].pack("U*")
    end

    def cross
      # necessary for 1.8.7 unicode handling since many installs are on 1.8.7
      @cross ||= ["2718".hex].pack("U*")
    end

    def strip_ansi(string)
      string.gsub(/\033\[\d+(;\d+)*m/, "")
    end

    def blue
      bold 34
    end

    def white
      bold 39
    end

    def red
      underline 31
    end

    def yellow
      underline 33
    end

    def reset
      escape 0
    end

    def em
      underline 39
    end

    def green
      bold 32
    end

    def gray
      bold 30
    end

    def highlight
      bold 39
    end

    def width
      `/usr/bin/tput cols`.strip.to_i
    end

    def truncate(str)
      str.to_s[0, width - 4]
    end

    private

    def color(n)
      escape "0;#{n}"
    end

    def bold(n)
      escape "1;#{n}"
    end

    def underline(n)
      escape "4;#{n}"
    end

    def escape(n)
      "\033[#{n}m" if $stdout.tty?
    end
  end
end


def ohai(title, *sput)
  title = Tty.truncate(title) if $stdout.tty?
  puts "#{Tty.blue}==>#{Tty.white} #{title}#{Tty.reset}"
  puts sput
end

def oh1(title)
  title = Tty.truncate(title) if $stdout.tty?
  puts "#{Tty.green}==>#{Tty.white} #{title}#{Tty.reset}"
end

# Print a warning (do this rarely)
def opoo(warning)
  $stderr.puts "#{Tty.yellow}Warning#{Tty.reset}: #{warning}"
end

def onoe(error)
  $stderr.puts "#{Tty.red}Error#{Tty.reset}: #{error}"
end

def odie(error)
  onoe error
  exit 1
end