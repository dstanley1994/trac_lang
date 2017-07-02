
require_relative 'block'
require_relative 'decimal'
require_relative 'expression'
require_relative 'form'
require_relative 'octal'

module TracLang

  # Class to dispatch TRAC commands to the proper code.  Also stores the following options needed to run TRAC:
  # [trace] Determines whether to display TRAC commands before executing them
  # [meta] Meta character used to signal the end of input
  # [savedir] Directory to save blocks to and load them from
  class Dispatch

    class << self
      # Dispatch table.  All basic TRAC commands are stored in the dispatch table.
      # This is done instead of methods to prevent someone from inadvertently (or
      # on purpose) calling a Ruby internal method instead of a TRAC command.
      attr_accessor :table
    end

    # Initialize dispatch table.
    @table = {}
    
    # Defines a TRAC command to be added to the dispatch table.
    # The following commands are defined.
    # 
    # ---
    # <em>System Commands</em>
    #
    # [on :hl] 
    #         Halt.  Halts the TRAC processor.
    # [on :tn]
    #         Trace On.  While trace is on, each Expression to be executed will be displayed to the 
    #         user first.  If the user presses return, the Expression will be executed.  If any other 
    #         key is pressed, the active string will be cleared and the idle string will be reloaded.
    # [on :tf]
    #         Trace Off.  When trace is off, execution proceeds as normal.
    # [on :pf do |name = ''|]
    #         Print Form.  Prints the form with the given name on the console.  The form text, segments, and form pointer
    #         will all be displayed.
    # 
    # ---
    # <em>Basic Commands</em>
    #
    # [on :ds do |name = '', value = ''|]
    #      Define String.  Creates a new Form with the given name and value, and stores it in the current set of bindings.
    # [on :eq do |str1 = '', str2 = '', t = '', f = ''|]
    #      Equal.  Tests if two strings are equal and returns the string t or f depending on the result of the test.  Note that 
    #      this is a string test for equality, so will not work for numerics.  To compare numerically see the greater than command.
    # [on :gr do |num1 = '', num2 = '', t = '', f = ''|]
    #      Greater Than.  Compares the given Decimal values and returns the string t or f depending on the result of the test.  To
    #      test two Decimal values for equality, test if neither is greater than the other.
    #
    # ---
    # <em>I/O Commands</em>
    #
    # [on :ps do |str = ''|]
    #      Print String.  Prints to the console the first argument.
    # [on :rc]
    #      Read Character.  Reads a single character from the keyboard.  This will read control
    #      characters as well as printable characters.
    # [on :rs]
    #      Read String.  Reads characters until the meta character is typed.  Primitive editing 
    #      characters are available:
    #      [/] Erases the previous character
    #      [@] Erases the entire input string
    #      The editing characters don't change the appearance of input, they just change what the 
    #      processor eventually sees.  So for example, the following:
    #
    #      <tt>#(DD@#(PS,Hellp\o World!)'</tt>
    #
    #      will cause TRAC to print Hello World!
    # [on :cm do |str|]
    #      Change Meta.  Changes the meta character to the first character of the given string.
    #
    # ---
    # <em>Block Commands</em>
    #
    # [on :dd do |*names|]
    #      Delete Definitions.  Deletes Form definitions that are bound to the given names.  Names that are
    #      not bound will be ignored.  
    # [on :da]
    #      Delete all definitions.  A synonym for +#(DD,#(LN,(,)))+.
    # [on :ln do |delimiter = ''|]
    #      List Names.  Lists names defined in the current binding using the given delimiter. The delimiter defaults 
    #      to the empty string, which means the names will all run together.
    # [on :sb do |name, *fnames|]
    #      Store Block.  Creates a new block with the given name and stores the given forms in it. This will 
    #      create a file in the savedir with the name given and an extension of .trl.  The file itself will contain 
    #      the TRAC commands necessary to recreate the forms given and position their form pointers to the correct place.
    # [on :fb do |name = ''|]
    #      Fetch Block.  Fetches the block with the given name and adds its forms to this environment.  This will read the 
    #      file given by the form value and execute each line of it as series of TRAC commands.  The contents of the block 
    #      Form given by the name does not have to use the same directory as the +savedir+, so you can load files from other 
    #      directories if you want. However, the Executor that is executing the TRAC commands in the file is using the +savedir+
    #      option, so if the file in question has a #(SB) command, it will use the +savedir+ in the Executor.
    # [on :eb do |name = ''|]
    #      Erase Block.  Deletes block and its corresponding file.
    #
    # ---
    # <em>Math Commands</em>
    #
    # [on :bc do |str = ''|]
    #      Bit Complement.  Maps the mnemonic <tt>:bc</tt> to Octal.~.
    #
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
    
    # Initializes environment for TRAC with a set of options.
    # Options are:
    # [bindings] Bindings to use
    # [trace] Turn trace on or off
    # [savedir] Directory that blocks are written to and read from.
    def initialize(**options)
      @root = options[:bindings] || Bindings.new
      @trace = options[:trace] || false
      @savedir = options[:savedir] || './'
      @meta = "'"
    end

    # Halt command.
    on :hl do
      throw :done
    end

    # Trace on command.  
    on :tn do
      @trace = true
      return_empty
    end
    
    # Trace off command.  
    on :tf do
      @trace = false
      return_empty
    end

    # Equal command.
    on :eq do |str1 = '', str2 = '', t = '', f = ''|
      return_force(str1 == str2 ? t : f)
    end
    
    # Print string command.  
    on :ps do |str = ''|
      print str
      return_empty
    end
      
    # Read character command.
    on :rc do
      return_value(ImmediateRead.new.getch)
    end

    # Read string command.  
    on :rs do
      str = ''
      loop do
        c = ImmediateRead.new.getch
        case c
        when @meta then break
        when '/'   then str.slice!(-1)
        when '@'   then str = ''
        else
          str << c
        end
      end
      return_value(str)
    end

    # Change meta command.  
    on :cm do |str|
      @meta = str[0] if str
      return_empty
    end

    # Define string command.  
    on :ds do |name = '', value = ''|
      @root.add([name, Form.new(value)])
      return_empty
    end
    
    # Defines mapping from dispatch command to Form method.  The parameters are:
    # [sym]
    #     Method name in Form to map to.
    # [type]
    #     One of
    #     * :returning_empty
    #       To return an empty string.
    #     * :returning_value
    #       To return the value returned from the Form method.
    #     * :rescuing_eos
    #       To rescue in case EndOfStringError is raised.
    # [pos]
    #     Used when type is +:rescuing_eos+.  Index of argument
    #     that is returned in case EndOfStringError is raised.
    #
    # The following mnemonics are mapped to Form methods:
    # [:ss]
    #      Segment String.  Mapped to Form.segment_string.
    # [:cr]
    #      Call Return.  Mapped to Form.call_return.
    # [:cl]
    #      Call Lookup.  Mapped to Form.call_lookup.
    # [:cc]
    #      Call Character.  Mapped to Form.call_character.
    # [:cs]
    #      Call Segment.  Mapped to Form.call_segment.
    # [:cn]
    #      Call N Characters.  Mapped to Form.call_n.
    # [:in]
    #      In String.  Mapped to Form.in_neutral.
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
    
    # Print form command.  
    on :pf do |name = ''|
      f = @root.fetch(name)
      puts f if f
      return_empty
    end
    
    # Delete definitions command.
    on :dd do |*names|
      names.each { |name| @root.delete(name) }
      return_empty
    end
    
    # Delete all command.
    on :da do 
      @root.clear
      return_empty
    end
    
    # List names command.
    on :ln do |delimiter = ''|
      return_value(@root.map { |n, v| n }.join(delimiter))
    end
  
    # Store block command.
    on :sb do |name, *fnames|
      if name
        to_save = fnames.map { |n| @root.fetch_binding(n) }.compact
        b = Bindings.new(*to_save)
        filename = @savedir + name + '.trl'
        Block.write(filename, b)
        fnames.each { |n| @root.delete(n) }
        @root.add([name, Form.new(filename)])
      end
      return_empty
    end
  
    # Fetch block command.
    on :fb do |name = ''|
      f = @root.fetch(name)
      Block.read(f.value, bindings: @root, savedir: @savedir, trace: @trace) if f
      return_empty
    end

    # Erase block command.
    on :eb do |name = ''|
      f = @root.fetch(name)
      Block.delete(f.value) if f
      @root.delete(name)
      return_empty
    end

    # Greater command.
    on :gr do |num1 = '', num2 = '', t = '', f = ''|
      unless num1 && num2
        return_empty
      else
        n1 = Decimal.new(num1)
        n2 = Decimal.new(num2)
        return_force(n1.value > n2.value ? t : f)
      end
    end

    # Maps a mnemonic to a Decimal operation.  The following are mapped:
    # [:ad] Add.  Maps to Decimal.+.
    # [:su] Subtract.  Maps to Decimal.-.
    # [:ml] Maps to Decimal.*.
    # [:dv] Maps to Decimal./.  If a ZeroDivisionError is detected, the overflow string is forced to output.
    def self.dispatch_to_decimal(symbol)
      Proc.new do |s1 = '', s2 = '', overflow = ''|
        d1 = Decimal.new(s1)
        d2 = Decimal.new(s2)
        begin
          return_value(d1.send(symbol, d2).to_s)
        rescue ZeroDivisionError
          return_force(overflow)
        end
      end
    end
  
    on :ad, &dispatch_to_decimal(:+)
    on :su, &dispatch_to_decimal(:-)
    on :ml, &dispatch_to_decimal(:*)
    on :dv, &dispatch_to_decimal(:/)

    # Maps a mnemonic to a Octal operation.  The following are mapped:
    # [:bu] Bit Union.  Mapped to Octal.|.
    # [:bi] Bit Intersection.  Mapped to Octal.&.
    def self.dispatch_to_octal(symbol)
      Proc.new do |s1 = '', s2 = ''|
        o1 = Octal.new(s1)
        o2 = Octal.new(s2)
        return_value(o1.send(symbol, o2).to_s)
      end
    end
  
    on :bu, &dispatch_to_octal(:|)
    on :bi, &dispatch_to_octal(:&)

    # Bit complement command.
    on :bc do |str = ''|
      return_value(Octal.new(str).send(:~).to_s)
    end

    # Maps a mnemonic to a mixed Octal and Decimal operation.  The following are mapped:
    # [:bs] Bit Shift.  Mapped to Octal.shift.
    # [:br] Bit Rotate.  Mapped to Octal.rotate.
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