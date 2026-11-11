# frozen_string_literal: true

require 'ruby-gem-release/changelog'
require 'ruby-gem-release/markdown/section'
require 'ruby-gem-release/workflow/ruby_gem'

class HashieReleasePreparation
  CATEGORIES = %w[Added Changed Deprecated Removed Fixed Security].freeze

  def self.workflow(**options)
    workflow = RubyGemRelease::Workflow::RubyGem.new(
      version: RubyGemRelease::Version::RubyConstant.new(path: 'lib/hashie/version.rb', constant: 'VERSION'),
      changelog: RubyGemRelease::Changelog::KeepAChangelog.new(placeholder: '* Your contribution here.', sections: CATEGORIES),
      **options
    )
    readme = RubyGemRelease::Markdown::Section.new(path: 'README.md', heading: '## Stable Release')
    workflow.before(:validate) { |_ctx| readme.validate! }
    workflow.after(:prepare_release) do |ctx|
      readme.replace!("You're reading the documentation for the stable release of Hashie, #{ctx.release.version}.")
    end
    workflow.after(:prepare_next) do |ctx|
      readme.replace!("You're reading the documentation for the next release of Hashie, which should be #{ctx.release.next_version}. " \
                      "The current stable release is [#{ctx.release.version}](https://github.com/hashie/hashie/blob/v#{ctx.release.version}/README.md).")
    end
    workflow
  end
end
