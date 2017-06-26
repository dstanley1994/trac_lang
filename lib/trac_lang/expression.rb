
module TracLang

  # Model of TRAC neutral string expression.  An expression is an array of strings,
  # corresponding to the arguments of a TRAC expression.  Expressions are active
  # if they were called by #(...) and not active (neutral) if they were
  # called by ##(...).  
  class Expression

    # Flag to tell if this expression is active or neutral.  The result of 
    # active expressions are copied to the active string, while the result of
    # neutral expressions are copied to the enclosing expression.
    attr_accessor :active

    # List of arguments for this expression.
    attr_accessor :args

    alias_method :active?, :active

    # Creates new active expression.
    def initialize
      @args = ['']
      @active = true
    end

    # Command for TRAC processor.
    def command
      @args[0].downcase.to_sym
    end
    
    # Arguments for TRAC command.
    def trac_args
      @args[1..-1]
    end
    
    # Adds a string to current argument of the expression.
    def concat(str)
      @args.last.concat str
    end

    # Signals a new argument is starting.  
    def newarg
      @args.push ''
    end

    # Returns current number of arguments in expression.
    def size
      @args.size
    end

    # String version of expression, used when trace is on
    def to_s
      (@active ? '#/' : '##/') + @args.join('*') + '/'
    end

  end

end
