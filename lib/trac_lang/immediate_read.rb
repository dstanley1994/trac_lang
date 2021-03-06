
require 'io/console'
require 'highline/system_extensions'
include HighLine::SystemExtensions

module TracLang

  # Class to do console input.  This is put in a separate
  # class to make it easier to switch between implementations,
  # since this seems to be seomthing that has some incompatibilities
  # between operating systems.
  class ImmediateRead
  
    # Creates class with console input handler depending on operating system.
    def initialize
      if (/mingw|win|emx/=~RUBY_PLATFORM)!=nil
        @getchar=lambda{WinAPI._getch} # Windows
      else
        @getchar=lambda{STDIN.getbyte} # Unix
      end
      @method_name = :highline
    end
  
    # Get character from console input.
    def getch
      self.send(@method_name)
    end
  
    def console_io
      c = IO.console.getch
      print c
      c
    end

    # Get character from console input, doing any translation necessary.    
    def highline
      chr = @getchar[].chr
      case chr
      when "\r"
        chr = "\n"
        puts
      when "\u0003"
        throw :done
      else
        STDOUT.write chr
      end
      chr
    end
    
  end
  
end
