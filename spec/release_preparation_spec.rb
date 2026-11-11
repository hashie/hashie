# frozen_string_literal: true

require 'spec_helper'

if RUBY_ENGINE == 'ruby' && Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3.3')
  require_relative '../script/release_preparation'
  require 'ruby-gem-release/rspec'

  describe HashieReleasePreparation do
    include RubyGemRelease::RSpec

    def with_hashie_project
      with_release_project do |project|
        project.copy_files(path: File.expand_path('..', __dir__), files: %w[
                             script/release_preparation.rb hashie.gemspec lib/hashie/version.rb
                             README.md CHANGELOG.md .yardopts CONTRIBUTING.md LICENSE UPGRADING.md
                           ])
        project.configure_workflow(require: 'script/release_preparation', builder: 'HashieReleasePreparation.workflow')
        yield project
      end
    end

    it 'publishes README and changelog edits in the correct release and development commits' do
      with_hashie_project do |project|
        path = File.join(project.checkout, 'CHANGELOG.md')
        history = File.read(path).split('## [6.0.0]', 2).last
        project.write('CHANGELOG.md', File.read(path).sub('### Changed', "### Changed\n\n* **Breaking:** Changed hash behavior."))
        project.commit!

        project.release!(version: '7.0.0')

        released = project.remote_file('v7.0.0', 'CHANGELOG.md')
        pending = project.remote_file('master', 'CHANGELOG.md').split('## [7.0.0]').first
        expect(released).to end_with(history.strip)
        notes = released.split('## [6.0.0]').first
        expect(notes).to include('**Breaking:** Changed hash behavior.')
        expect(notes).not_to include('Your contribution here.', '### Added', '### Security')
        expect(pending.scan(/^### (.+)$/).flatten).to eq(described_class::CATEGORIES)
        expect(pending.scan('* Your contribution here.').size).to eq(6)
        expect(project.remote_file('master', 'CHANGELOG.md')).to include('[Unreleased]: https://github.com/hashie/hashie/compare/v7.0.0...master')
        expect(project.remote_file('v7.0.0', 'README.md')).to include('stable release of Hashie, 7.0.0.')
        expect(project.remote_file('master', 'README.md')).to include('which should be 7.0.1.', 'stable release is [7.0.0]')
        expect(project.git('status', '--porcelain')).to be_empty
      end
    end

    it 'rejects placeholder-only notes before changing release files or remote refs' do
      with_hashie_project do |project|
        project.commit!
        original = project.git('rev-parse', 'origin/master')
        project.run_task('release:workflow:capture')

        expect { project.run_task('release:validate') }.to raise_error(RuntimeError, /no pending changelog notes/)
        expect(project.git('status', '--porcelain')).to be_empty
        expect(project.git('rev-parse', 'origin/master')).to eq(original)
      end
    end

    it 'rejects missing or duplicate README release paragraphs without changing files' do
      with_hashie_project do |project|
        ['# Hashie', "## Stable Release\n\nFirst.\n\n## Stable Release\n\nSecond.\n"].each do |readme|
          project.write('README.md', readme)
          project.commit!
          project.run_task('release:workflow:capture')

          expect { project.run_task('release:validate') }.to raise_error(RuntimeError, /exactly one matching heading/)
          expect(project.git('status', '--porcelain')).to be_empty
        end
      end
    end
  end
end
