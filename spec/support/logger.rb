# A shared context that allows you to check the output of Hashie's logger.
#
# @example
#   shared_context 'with a logger' do
#     Hashie.logger.info 'What is happening in here?!'
#
#     expect(logger_output).to match('What is happening in here?!')
#   end
RSpec.shared_context 'with a logger' do
  # @private
  let(:log) { StringIO.new }

  # The output string from the logger
  let(:logger_output) { log.rewind && log.string }

  around(:each) do |example|
    original_logger = Hashie.logger
    Hashie.logger = Logger.new(log)
    example.run
    Hashie.logger = original_logger
  end
end
