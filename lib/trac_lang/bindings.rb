

module TracLang

  # Binding of name to Form represented by the name.
  class Bindings
    include Enumerable

    # Hash map of names to Forms.
    attr_reader :bindings
    
    # Creates bindings from list of names and Forms.
    def initialize(*bindings)
      @bindings = Hash[bindings]
    end

    # Clears all bindings.    
    def clear
      @bindings.clear
    end
    
    # Adds a binding to the map of bindings.  Will replace a binding with the same name.
    def add(*binding)
      if binding[0].is_a? Array
        @bindings.merge!(Hash[binding])
      else
        @bindings.merge!(Hash[[binding]])
      end
    end
    
    # Fetches the Form with the given name. Returns nil if no Form has the given name.
    def fetch(name)
      @bindings.fetch(name, nil)
    end
    
    # Fetches the binding for the given name, or nil if nothing has the given name.
    def fetch_binding(name)
      f = @bindings.fetch(name, nil)
      return f ? [name, f] : nil
    end
    
    # Unbinds any Form bound to the given name.
    def delete(name)
      @bindings.delete(name)
    end
    
    def each(&blk)
      @bindings.each(&blk)
    end
  end
  
end
