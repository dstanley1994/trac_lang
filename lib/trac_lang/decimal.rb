
module TracLang

# Integer for TRAC Language.  Consists of
# * string prefix
# * sign
# * numeric value
# The string prefix can be used to label the
# number and is carried over by operations.
# The sign is separate from the numeric value
# so that -0 can be distinguished from +0.
# This is needed when testing for Form pointers
# for EndOfString.
class Decimal

  # String prefix of this number.  Used to label the number,
  # such as +Apples5+ or +Balance-100+.
  attr_accessor :prefix

  # Flag for negativity.  Needed to distinguish between -0 and +0.
  attr_accessor :negative

  # Numeric value of this number.
  attr_accessor :value

  alias_method :negative?, :negative

  # Create a TRAC decimal from a string.  Any leading characters are
  # saved as a prefix.  The last sign character before the numeric 
  # portion is sign.  If there are no numeric characters in the given
  # string, zero is assumed.
  def initialize(str = '')
    raise ArgumentError unless str.is_a? String
    n = str.partition(/[+-]?[0-9]*$/)
    @prefix = n[0]
    @value = n[1].to_i
    @negative = n[1][0] == '-'
  end

  # Tests for equality.  This is different from numeric equality
  # because prefixes are tested as well as the numeric value.
  def ==(d)
    return super unless d.is_a? TracLang::Decimal
    d.prefix == @prefix && d.value == @value && d.negative == @negative
  end
  
  # Returns string value of decimal.  A sign is added to negative zeros.
  def to_s
    prefix + (negative? && value == 0 ? '-' : '') + value.to_s
  end

  # Defines method for given arithmetical operation.  Result has string
  # prefix of self.  The operations defined are:
  # [+]
  #    Sum of two decimals.
  # [-]
  #    Difference.
  # [*]
  #    Product.
  # [/]
  #    Quotient.
  def self.define_operation(symbol)
    define_method(symbol) do |other| 
      result = Decimal.new
      result.prefix = prefix
      result.value = value.send(symbol, other.value)
      result.negative = result.value < 0
      result
    end
  end

  define_operation :+
  define_operation :-
  define_operation :*
  define_operation :/

end

end
