
module TracLang

  # Parser for TRAC input.  Given the input a character at a time, it
  # creates an active string and then executes it when the string is
  # completed.
  class Parser

    # Parses the given string and executes it, until the
    # active string is empty.
    def parse(str, &blk)
      @active = str
      @handler = :reading
      @expressions = []
      loop do
        if @active.empty?
          # if handler is parens, we've read a open paren w/o a matching closing one
          throw :reset if @handler == :parens
          # if handler if reading, and expressions is not empty
          # we've read #( without a matching end paren
          throw :reset if @handler == :reading && !@expressions.empty?
          # if hander is :start_proc, we've just read a bunch of #s
          # so we can ignore them without throwing an error
          return
        end
        self.send(@handler, @active.slice!(0), &blk)
      end
    end

    # Add character to current expression, ignore if no expression exists
    def concat(c)
      unless @expressions.empty?
        @expressions.last.concat(c)
      end
    end

    # Handler while actively reading the active string.  If you start an expression,
    # switch to the start_proc handler.  If you see an open parenthesis, switch
    # to the parens handler.  Comma marks a new argument in the current expression, and
    # end parenthesis marks the end of an expression.  When an expression is ended, execute it
    # and handle the results.
    def reading(c, &blk)
      case c
      when '#'
        @expressions.push Expression.new
        @handler = :start_proc
      when '('
        @nesting = 1
        @handler = :parens
      when ','
        unless @expressions.empty?
          @expressions.last.newarg
        end
      when ')'
        throw :reset if @expressions.empty?
        expression = @expressions.pop
        result = blk.call(expression)
        if result.nil?
          print expression
          throw :reset
        elsif result[:force] || expression.active?
          @active.prepend(result[:value])
        else
          concat(result[:value])
        end
      when "\n", "\r"
        # ignore cr and lf
      else
        concat(c)
      end
    end

    # Handler while reading inside protective parentheses.  Copies all
    # characters to current expression while keeping track of current parentheses
    # nesting.  When a matching parenthesis is found, go back to reading
    # handler.
    def parens(c)
      case c
      when '('
        @nesting += 1
      when ')'
        @nesting -= 1
        if @nesting == 0
          @handler = :reading
          return
        end
      end
      concat(c)
    end

    # Handler for the start of an expression.  Mark the expression as active or not,
    # depending on whether it starts with #(...) or ##(...).
    def start_proc(c, &blk)
      case c
      when '#'
        throw :reset if @expressions.empty?
        if @expressions.last.active?
          @expressions.last.active = false
        else
          unless @expressions.size == 1
            @expressions[-2].concat(c)
          end
        end
      when '('
        @handler = :reading
      else
        throw :reset if @expressions.empty?
        discard = @expressions.pop
        concat(discard.active? ? '#' : '##')
        @handler = :reading
        reading(c, &blk)
      end
    end

  end

end