# Like array equality, but accepts anything within a certain delta.
# Used to diff the arrays of floating-point values that come up a lot in our tests.

RSpec::Matchers.define :eq_array_with_delta do |delta, expected| 
  match do |actual|

    @actual = @actual.zip(expected).map do |actual_element, expected_element|

      # If the element's close enough, treat it as identical.
      if (actual_element - expected_element).abs < delta
        expected_element
      else
        actual_element
      end
    end

    # Redefine +expected+ too since we don't want the delta in the diff.
    @expected = expected

    values_match? @expected, @actual
  end

  diffable
end
