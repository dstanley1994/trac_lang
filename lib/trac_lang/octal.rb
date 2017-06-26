
module TracLang

# TRAC octal number.  Unlike the TracLang::Decimal, any
# string prefix is discarded.  Bit size is saved so that 
# operations can retain the size.
class Octal

  # Number of octal digits in this number.
  attr_accessor :size

  # Numeric value of this number.
  attr_accessor :value

  # Creates a TRAC octal. Any leading non-numeric characters are ignored.  
  # If there are no octal characters, zero is assumed.
  def initialize(str = '')
    raise ArgumentError unless str.is_a? String
    b = str.partition(/[0-7]*$/)
    @value = b[1].to_i(8)
    @size = b[1].length 
  end

  # Tests for equality.  This is different from numeric equality,
  # because size is also tested.
  def ==(o)
    return super unless o.is_a? TracLang::Octal
    o.value == @value && o.size == @size
  end

  # Converts octal number to string.  Returns a string <size> digits long.
  def to_s
    if value < 0
      sprintf("%0*.*o", size + 2, size + 2, value).slice(2..-1)
    else
      sprintf("%0*.*o", size, size, value)
    end
  end

  # Bit or.  Result bit size is maximum of bit size of parameters.
  define_method(:|) do |other|
    result = Octal.new
    result.size = [self.size, other.size].max
    result.value = self.value | other.value
    result
  end

  # Bitwise and.  Result bit size is minimum of bit size of parameters.
  define_method(:&) do |other|
    result = Octal.new
    result.size = [self.size, other.size].min
    result.value = self.value & other.value
    result
  end
  
  # Bit complement.
  def ~
    result = Octal.new
    result.size = size
    result.value = ~value
  end
  
  # Shifts octal bits by the given amount.
  def shift(n)
    result = Octal.new
    result.size = size
    result.value = n.value < 0 ? value >> -n.value : value << n.value
    result
  end

  # Rotates octal bits by the given amount.  
  def rotate(n)
    result = Octal.new
    result.size = size
    bits = 3 * o.bit_size
    bit_mask = 2 ** bits - 1
    if n.value < 0
      result.value = ((value >> -n.value) | (value << (bits + n.value))) & bit_mask
    else
      result.value = ((value << n.value) | (value >> (bits - n.value))) & bit_mask
    end
    result
  end
  
end

end
