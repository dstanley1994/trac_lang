
module TracLang

  # Executable TRAC commands
  class Executor

    # Initialize executor, giving block to store forms in
    def initialize(d = nil)
      @parser = Parser.new
      @dispatch = d || Dispatch.new
    end

    # Executes TRAC from an interactive prompt. 
    def prompt
      puts "TRAC Emulator #{VERSION}"
      puts
      catch :done do
        loop do
          idle = "#(PS,#(RS)\n)"
          catch :reset do
            execute(idle)
          end
        end
      end
      puts 'Exiting...'
      puts
    end

    # Executes TRAC from a file.
    def load_file(filename)
      File.new(filename, 'r').each do |line|
        break unless load(filename, $., line)
      end
    end
    
    # Executes a line of TRAC loaded from a file.
    def load(filename, lineno, line)
      @code ||= ''
      to_exe = ''
      catch :reset do
        @code += line
        i = @code.index(@dispatch.meta)
        # explanation of odd indexing:
        # slice everything off code including meta character
        # then execute that slice, without the meta character
        if i
          to_exe = @code.slice!(0..i)[0...-1]
          execute(to_exe)
        end
        return true
      end
      puts to_exe
      puts "Error on or before line #{lineno} of #{filename}"
      return false
    end
    
    # Executes a string of TRAC.
    def execute(str)
      @parser.parse(str) do |to_call|
        if @dispatch.trace
          puts to_call
          c = ImmediateRead.new.getch
          throw :reset unless c == "\n"
          puts
        end
        @dispatch.dispatch(to_call)
      end
    end
    
  end

end
