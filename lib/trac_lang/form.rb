
require_relative "decimal"

# A form is a defined string in TRAC, along with spaces in it for the
# insertion of parameters.
class TracLang::Form

  # Error when trying to read form off the end of its string.
  class EndOfStringError < StandardError; end

  # Segment positions of form.  This is stored as an array of arrays.
  # Each position in the array corresponds to a character in the form
  # string, with an additional entry at the end.  If the entry is non-empty
  # it will have a list of the segment numbers at that location.
  attr_reader :segments

  # String value of form.
  attr_reader :value

  # Creates a new form with the given value.
  def initialize(value)
    @value = value
    @segments = Array.new(@value.length + 1) { [] }
    # character pointer is the index into the segments array
    @cp = 0
    # segment pointer is the index into @segments[@cp]
    # if @sp == @segments[@cp].lenth then it is pointing to @value[@cp]
    @sp = 0
  end

  # Finds the given search string in the string portion of the form, starting 
  # at the given space.  A successful match cannot span segment gaps.
  def find(search, start = 0)
    loop do
      i = @value.index(search, start)
      return nil unless i
      # don't find over segment boundaries
      boundary = @segments.slice(i + 1, search.length - 1)
      unless boundary.all? { |v| v.empty? }
        start = i + 1
        next
      end
      return i
    end
  end

  # Adds segement gaps for one punch.  
  def punch(punch_in, n)
    return if punch_in.empty?
    start = 0
    punch = punch_in.dup
    len = punch.length
    loop do
      found = find(punch)
      break unless found
      if @segments[found].empty?
        @segments.slice!(found, len)
        @segments[found].unshift(n)
      else
        @segments[found].push(n)
        @segments[found] += @segments[found + len]
        @segments.slice!(found + 1, len)
      end
      @value.slice!(found, len)
    end
  end

  # Add segment gaps for multiple punches.
  def segment_string(*punches)
    punches.each.with_index { |p, n| punch(p, n + 1) }
  end
  
  # Increments the character pointer by the given amount.
  def increment(n = 1)
    @cp += n
    @cp = @value.length if @cp > @value.length
    @cp = 0 if @cp < 0
    @sp = n > 0 ? 0 : @segments[@cp].length
  end

  # Returns the pointers to the start of the form.  
  def call_return(*)
    @sp = 0
    @cp = 0
  end

  # Returns the character being pointed to and moves the pointer
  # one unit to the right.  Raises a EndOfStringError if the pointer
  # is already at the end of the form.
  def call_character(*)
    raise EndOfStringError if @cp == @value.length
    result = @value[@cp, 1]
    increment
    result
  end

  # Returns the given number of characters starting at the current 
  # pointer.  If the number is negative, returns characters before
  # the current pointer, but in the same order the characters are in
  # the form.  Raises an EndOfStringError if a negative number is given
  # and you are at the start of the form, or if a positive number is
  # given and you are at the end of the form.  A value of zero can be 
  # given to test where the pointer is without changing it.
  def call_n(nstr, *)
    tn = TracLang::Decimal.new(nstr)
    n = tn.value
    if tn.negative?
      raise EndOfStringError if @cp == 0 && @sp == 0
      # move left of seg gaps
      @sp = 0
      return '' if n == 0
      raise EndOfStringError if @cp == 0
      n = -@cp if n < -@cp
      result = @value.slice(@cp + n, -n)
      increment(n)
    else
      raise EndOfStringError if @value.length - @cp == 0 && @sp == @segments[@cp].length
      # move right of seg gaps
      @sp = @segments[@cp].length
      return '' if n == 0
      raise EndOfStringError if @value.length - @cp == 0
      n = @value.length - @cp if n > @value.length - @cp
      result = @value.slice(@cp, n)
      increment(n)
    end
    result
  end

  # Searches for the given string in the form.  If found, returns all
  # characters between the current pointer and the start of the match, 
  # while moving the character pointer past the match.  Raises an 
  # EndOfStringError if you are at the end of the form or no match is
  # found.  An empty search string counts as always not matching.
  def in_neutral(search, *)
    raise EndOfStringError if @cp == @value.length || search.empty?
    found = find(search, @cp)
    if found
      result = @value[@cp...found]
      increment(found - @cp + search.length)
      return result
    else
      # form pointer is not moved if not found
      raise EndOfStringError
    end
  end

  # Returns characters from the given position to the next segment gap.
  def find_chars(start)
      # don't test start position because you might be at the end of the segment list
      len = 1 + @segments[(start + 1)..-2].take_while { |s| s.empty? }.count
      @value.slice(start, len)
  end

  # Returns characters between the current pointer and the 
  # next segment gap.  
  def call_segment(*)
    raise EndOfStringError if @cp == @value.length + 1 # would this ever be true?
    # on a character
    if @sp == @segments[@cp].length # may be zero
      raise EndOfStringError if @cp == @value.length
      result = find_chars(@cp)
      @cp += result.length
      # need check if you're at end of string
      @sp = @segments[@cp].empty? ? 0 : 1
    # else within segment list
    else
      result = ''
      @sp += 1
    end
    result
  end

  # Returns form string with segment gaps filled with the given arguments.
  def call_lookup(*args)
    trimmed = @segments.dup
    # trim off everything before current pointer
    trimmed.slice!(0...@cp) unless @cp == 0
    trimmed[0].slice!(0...@sp) unless trimmed[0].empty? || @sp == 0
    trimmed.map.with_index do |a, i| 
      a.map { |v| args[v - 1] || '' }.join + (@value[@cp + i] || '')
    end.join
  end

  # Checks if any punches have been done on this form.
  def punched
    @segments.any? { |s| !s.empty? }
  end

  # Finds the biggest punch index.  
  def max_punch
    @segments.map { |s| s.max }.compact.max
  end

  # Tests if matched pair of symbols is used anywhere in this form.  Used to
  # find an unused pair for writing this form to a file.
  def matched_pair_used?(open, close)
    max_punch.times.map { |i| "#{open}#{i + 1}#{close}" }.any? { |s| @value.include?(s) }
  end
  
  # Test if given special character is used anywhere in this form.  Used
  # to find an unused special character for writing this form to a file.
  def special_used?(char)
    max_punch.times.map { |i| "#{char}#{i + 1}" }.any? { |s| @value.include?(s) }
  end
  
  # Find format of args that works
  def format
    pair = [['<','>'],['[',']'],['{','}']].find { |p| !matched_pair_used?(*p) }
    return pair if pair
    special = (126..255).find { |n| !special_used?(n.chr) }
    return [special.chr, special.chr] if special
    # what to do if nothing works?
  end
  
  # Converts current state of this form into TRAC commands.
  def to_trac(name)
    cp, sp = @cp, @sp
    @cp, @sp = 0, 0
    if punched
      pair = format
      args = max_punch.times.map { |i| "#{pair[0]}#{i + 1}#{pair[1]}"}
      trac = "#(DS,#{name},#{call_lookup(*args)})\n"
      trac += "#(SS,#{name},#{args.join(',')})\n" unless args.empty?
    else 
      trac = "#(DS,#{name},#{@value})\n"
    end
    trac += "#(CN,#{name},#{cp})\n" unless cp == 0
    trac += "#(CS,#{name})" * sp + "\n" unless sp == 0
    trac += "\n"
    @cp, @sp = cp, sp
    trac
  end
  
  # Converts this form into a string for display.  Follows format of TRAC
  # display defined in language definition.
  def to_s
    str = ''
    @segments.each.with_index do |s, cp|
      s.each.with_index do |n, sp|
        str += '<^>' if @cp == cp && @sp == sp
        str += "<#{n}>"
      end
      str += '<^>' if @cp == cp && @sp == s.length
      if cp < @value.length
        c = @value[cp]
        # escape non-printable characters
        str << (c =~ /[[:print:]]/ ? c : sprintf("\\x%02.2x", c.ord))
      end
    end
    str
  end
  
end
