
require 'io/console'
require_relative 'block'
require_relative 'decimal'
require_relative 'expression'
require_relative 'form'
require_relative 'octal'

module TracLang

  # Class to store dispatch table of pre-defined TRAC commands.  Also,
  # Also stores the following options needed to run TRAC:
  # [trace] Determines whether to display TRAC command before executing them
  # [meta] Meta character used to signal the end of input
  # [savedir] Directory to save blocks to and load them from
  class Dispatch

    # :section: Support definitions
    
    # Dispatch table.  All basic TRAC commands are stored in the dispatch table.
    # This is done instead of methods to prevent someone from inadvertently (or
    # on purpose) call a Ruby internal method instead of a TRAC command.
    class << self
      attr_accessor :table
    end

    # Initialize dispatch table.
    @table = {}
    
    # Defines a TRAC command to be added to the dispatch table.
    def self.on(sym)
      table[sym] = Proc.new
    end
    
    # Returns empty string.  All returns are wrapped in a hash containing
    # the return value and the force flag.
    def return_empty
      {value: '', force: false}
    end
    
    # Returns value.  All returns are wrapped in a hash containing the return
    # value and the force flag.
    def return_value(val)
      {value: val, force: false}
    end

    # Returns value and forces it to the active string.
    def return_force(val)
      {value: val, force: true}
    end
    
    # Determines the TRAC mnemonic name from the given method name.  This is 
    # used to map TRAC names to Form methods.
    def self.mnemonic(name)
      name.to_s.split('_').map {|w| w[0]}.join.to_sym
    end

    # Dispatches command to TRAC procedure.  If command received is a TRAC
    # command, it's looked up in the table and executed.  If not, the #(CL) 
    # command is called, and the result is forced to the active string.
    def dispatch(exp)
      if Dispatch.table.has_key?(exp.command)
        self.instance_exec(*exp.trac_args, &Dispatch.table[exp.command])
      else
        self.instance_exec(*exp.args, &Dispatch.table[:cl]).merge({force: true})
      end
    end
    
    # Flag for whether trace is on or off.  When trace is on,
    # each time an Expression is parsed for execution, the Executor
    # will display the Expression and wait for user input.  If the 
    # user presses enter, TRAC proceeds as normal.  If any other key
    # is pressed, the Executor is reset.
    attr_reader :trace
    
    # Meta character to end input.  When the Executor is reading from a file,
    # it will only pass the string on to the Parser after a meta character is
    # received.  Also, the TRAC #(RS) command will only return after a meta
    # character is pressed.
    attr_reader :meta
    
    # Initializes environment for TRAC with a set of bindings and options.
    # Options are:
    # [trace] Turn trace on or off
    # [savedir] Directory that blocks are written to and read from.
    def initialize(bindings, options)
      @root = bindings
      @meta = "'"
      @trace = options[:trace]
      @savedir = options[:savedir]
    end

    # :section: System Commands

    # Halt command.  Stops the TRAC processor.
    on :hl do
      throw :done
    end

    # Trace on command.  While trace is on, each Expression to be
    # executed will be displayed to the user first.  If the user
    # presses return, the Expression will be executed.  If any other
    # key is pressed, the active string will be cleared and the idle
    # string will be reloaded.
    on :tn do
      @trace = true
      return_empty
    end
    
    # Trace off command.  When trace is off, execution proceeds as
    # normal.
    on :tf do
      @trace = false
      return_empty
    end

    # Tests if two strings are equal.  Note that this is a string test
    # for equality, so will not work for numerics.  To compare numerically
    # see the #(GR) command.
    on :eq do |str1 = '', str2 = '', t = '', f = ''|
      return_force(str1 == str2 ? t : f)
    end
    
    # :section: I/O

    # Print string command.  
    on :ps do |str = ''|
      print str
      return_empty
    end
      
    # Read character from keyboard.
    def read_char
      c = IO.console.getch
      print c
      c
    end

    # Read character command.
    on :rc do
      return_value(read_char)
    end

    # Read string command.  Reads characters until the meta character
    # is typed.  Primitive editing characters are available
    # / erases the previous character
    # @ erases the entire input string
    # The editing characters don't change the appearance of input, they
    # just change what the processor eventually sees.  So for example,
    # the following:
    #
    # #(DD@#(PS,Hellp\o World!)'
    #
    # will cause TRAC to print Hello World!
    on :rs do
      str = ''
      loop do
        c = read_char
        case c
        when @meta then break
        when '/'   then str.pop
        when '@'   then str = ''
        else
          str << c
        end
      end
      return_value(str)
    end

    # Change meta command.  Changes the meta character to the
    # first character of the given string.
    on :cm do |str|
      @meta = str[0] if str
      return_empty
    end

    # :section: Forms
    
    # Define string command.  Creates a new form with the given
    # name and stores it in the current set of bindings.
    on :ds do |name = '', value = ''|
      @root.add([name, Form.new(value)])
      return_empty
    end
    
    # Defines mapping from dispatch command to form method.
    def self.dispatch_form(sym, type, pos = -1)
      table[mnemonic(sym)] = Proc.new do |name = '', *args|
        f = @root.fetch(name)
        if !f 
          return_empty
        else
          case type
          when :returning_empty
            f.send(sym, *args)
            return_empty
          when :returning_value
            return_value(f.send(sym, *args))
          when :rescuing_eos_at
            eos_result = args.slice!(pos)
            begin
              return_value(f.send(sym, *args))
            rescue EndOfStringError
              return_force(eos_result)
            end
          end
        end
      end
    end

    dispatch_form(:segment_string, :returning_empty)
    dispatch_form(:call_return, :returning_empty)
    dispatch_form(:call_lookup, :returning_value)
    dispatch_form(:call_character, :rescuing_eos_at, 1)
    dispatch_form(:call_segment, :rescuing_eos_at, 1)
    dispatch_form(:call_n, :rescuing_eos_at, 2)
    dispatch_form(:in_neutral, :rescuing_eos_at, 2)
    
    # Print form.  This is mostly used for debugging purposes.
    on :pf do |name = ''|
      f = @root.fetch(name)
      puts f if f
      return_empty
    end
    
    # Deletes given names from root binding.
    on :dd do |*names|
      names.each { |name| @root.delete(name) }
      return_empty
    end
    
    # Deletes all names from root binding.
    on :da do 
      @root.clear
      return_empty
    end
    
    # List names.  Lists names defined in the current binding using the given delimiter.
    # The delimiter defaults to the empty string, which means the names will all run together.
    on :ln do |delimiter = ''|
      return_value(@root.bindings.map { |b| b[0] }.join(delimiter))
    end
  
    # :section: Blocks
    
    # Store block.  Creates a new block with the given name and stores the valid given forms in it.
    # This will create a file in the savedir with the name given and an extension of .trl.  The 
    # file itself will contain the TRAC commands necessary to recreate the forms given and position
    # their form pointers to the correct place.
    on :sb do |name, *fnames|
      if name
        b = Bindings.new(fnames.map { |n| @root.fetch_binding(n) }.compact)
        filename = @savedir + name + '.trl'
        Block.write(filename, b)
        fnames.each { |n| @root.delete(fn) }
        @root.add([name, Form.new(filename)])
      end
      return_empty
    end
  
    # Fetch block.  Fetches the block with the given name and adds its forms to this environment.
    # This will read the file given by the form value and execute each line of it as series of
    # TRAC commands.  The contents of the block Form given by the name does not have to use the
    # same directory as the savedir, so you can load files from other directories if you want. 
    # However, the Executor that is executing the TRAC commands in the file is using the savedir
    # option, so if the file in question has a #(SB) command, it will use the savedir in the Executor.
    on :fb do |name = ''|
      f = @root.fetch(name)
      Block.read(f.value, @root, savedir: @savedir, trace: @trace) if f
      return_empty
    end

    # Erase block and its corresponding file.
    on :eb do |name = ''|
      f = @root.fetch(name)
      Block.delete(f.value) if f
      @root.delete(name)
      return_empty
    end

    # :section: Numerics
    
    # Compares the given TRAC decimals.  To test numerics for equality,
    # test if neither is greater than the other.
    on :gr do |num1 = '', num2 = '', t = '', f = ''|
      unless num1 && num2
        return_empty
      else
        n1 = Decimal.new(num1)
        n2 = Decimal.new(num2)
        return_force(n1.value > n2.value ? t : f)
      end
    end

    # Defines a decimal operation.  
    def self.dispatch_to_decimal(symbol)
      Proc.new do |s1 = '', s2 = '', overflow = ''|
        d1 = Decimal.new(s1)
        d2 = Decimal.new(s2)
        begin
          return_value(value: d1.send(symbol, d2).to_s)
        rescue ZeroDivisionError
          return_force(overflow)
        end
      end
    end
  
    on :ad, &dispatch_to_decimal(:+)
    on :sb, &dispatch_to_decimal(:-)
    on :ml, &dispatch_to_decimal(:*)
    on :dv, &dispatch_to_decimal(:/)

    # Defines an octal operation.  
    def self.dispatch_to_octal(symbol)
      Proc.new do |s1 = '', s2 = ''|
        o1 = Octal.new(s1)
        o2 = Octal.new(s2)
        return_value(o1.send(symbol, o2).to_s)
      end
    end
  
    on :bu, &dispatch_to_octal(:|)
    on :bi, &dispatch_to_octal(:&)

    # Bit complement command.  Takes the bit complement of
    # the given octal string.
    on :bc do |str = ''|
      return_value(Octal.new(str).send(:~).to_s)
    end

    # Defines a mixed decimal and octal operation.  
    def self.dispatch_to_mixed(sym)
      Proc.new do |oct = '', dec = ''|
        if dec.empty? || oct.empty?
          return_empty
        else
          o1 = Octal.new(oct)
          d1 = Decimal.new(dec)
          return_value(o1.send(sym, d1).to_s)
        end
      end
    end
  
    on :bs, &dispatch_to_mixed(:shift)
    on :br, &dispatch_to_mixed(:rotate)

  end

end