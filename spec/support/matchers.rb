RSpec::Matchers.define :parse_as_valid_ruby do
  require 'ripper'

  match do |actual|
    parsed = Ripper.sexp(actual)

    !parsed.nil?
  end

  failure_message do |actual|
    "expected that #{actual} would parse as valid Ruby"
  end
end
