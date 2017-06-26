
require 'io/console'

module TracLang

  # Executable TRAC commands
  class Executor

    # Initialize executor, giving block to store forms in
    def initialize(d)
      @parser = Parser.new
      @dispatch = d
    end

    # Executes TRAC from an interactive prompt. 
    def prompt
      puts "TRAC Emulator #{VERSION}"
      puts
      idle = "#(PS,#(RS)\n)"
      loop do
        catch :reset do
          execute(idle)
        end
      end
    end
    
    # Executes a line of TRAC loaded from a file.
    def load(filename, lineno, line)
      @code ||= ''
      catch :reset do
        @code += line
        i = @code.index(@dispatch.meta)
        execute(@code.slice!(0...i)) if i
        return true
      end
      puts line
      puts "Error on or before line #{lineno} of #{filename}"
      return false
    end
    
    # Executes a string of TRAC.
    def execute(str)
      @parser.parse(str) do |to_call|
        if @dispatch.trace
          puts to_call
          c = IO.console.getch
          throw :reset unless c == "\r"
        end
        @dispatch.dispatch(to_call)
      end
    end
    
  end

end
