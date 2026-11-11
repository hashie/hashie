# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'fileutils'
require 'open3'

if RUBY_ENGINE == 'ruby' && Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3.3')
  require_relative '../script/release_preparation'
  require 'ruby-gem-release/release'
  require 'ruby-gem-release/workflow/state'

  describe HashieReleasePreparation do
    let(:release) do
      RubyGemRelease::Release.new(version: '6.0.0', gemspec_version: '6.0.0', date: Date.new(2026, 11, 10))
    end
    let(:directory) { Dir.mktmpdir('hashie-release') }
    let(:changelog_path) { File.join(directory, 'CHANGELOG.md') }
    let(:readme_path) { File.join(directory, 'README.md') }
    let(:preparation) { described_class.new(path: changelog_path, readme_path: readme_path) }

    def changelog
      RubyGemRelease::Changelog::KeepAChangelog.new(path: changelog_path)
    end

    def run_command(*command)
      stdout, stderr, status = Open3.capture3(*command, chdir: directory)
      expect(status.success?).to be(true), "#{stdout}\n#{stderr}"
      stdout
    end

    def with_release_repository
      root = File.expand_path('..', __dir__)
      FileUtils.mkdir_p(File.join(directory, 'lib/hashie'))
      File.write(File.join(directory, 'lib/hashie/version.rb'), "module Hashie\n  VERSION = '6.0.0'\nend\n")
      File.write(File.join(directory, 'hashie.gemspec'), <<~RUBY)
        Gem::Specification.new do |gem|
          gem.name = 'hashie'
          gem.version = File.read('lib/hashie/version.rb')[/VERSION = '([^']+)'/, 1]
          gem.summary = 'Release fixture'
          gem.authors = ['Hashie']
        end
      RUBY
      run_command('git', 'init', '--quiet', '-b', 'master')
      run_command('git', 'config', 'user.name', 'Hashie')
      run_command('git', 'config', 'user.email', 'hashie@example.com')
      run_command('git', 'add', '.')
      run_command('git', 'commit', '--quiet', '--message', 'Initial fixture')

      Dir.mktmpdir('hashie-release-support') do |support|
        remote = File.join(support, 'remote.git')
        run_command('git', 'init', '--bare', '--quiet', '-b', 'master', remote)
        run_command('git', 'remote', 'add', 'origin', remote)
        environment = {
          'BUNDLE_GEMFILE' => File.join(root, 'Gemfile'),
          'DEFAULT_BRANCH' => 'master',
          'GEMSPEC_VERSION' => '6.0.0',
          'INPUT_VERSION' => '7.0.0',
          'RELEASE_VERSION' => '7.0.0',
          'RELEASE_DATE' => '2026-11-10',
          'RELEASE_DATA_DIR' => File.join(support, 'state'),
          'RELEASE_STATE_FILE' => RubyGemRelease::Workflow::State.create!(directory: support)
        }
        yield environment, ['bundle', 'exec', 'rake', '--rakefile', File.join(root, 'Rakefile')]
      end
    end

    before do
      File.write(changelog_path, <<~MARKDOWN)
        # Changelog

        ## [Unreleased]

        [Unreleased]: https://github.com/hashie/hashie/compare/v5.2.0...master

        ### Added

        * Your contribution here.

        ### Changed

        * **Breaking:** Changed hash behavior.
        * Your contribution here.

        ### Security

        * Your contribution here.

        ## [5.2.0] - 2026-10-23

        [5.2.0]: https://github.com/hashie/hashie/compare/v5.1.0...v5.2.0

        ### Added

        * Previous release notes.
      MARKDOWN
      File.write(readme_path, "# Hashie\n\n## Stable Release\n\nDevelopment documentation.\n\n## Usage\n\nUse Hashie.\n")
    end

    after do
      FileUtils.remove_entry(directory)
    end

    it 'cleans release placeholders and empty categories without changing history' do
      original = File.read(changelog_path)
      history = original[original.index('## [5.2.0]')..]
      preparation.prepare!(release, changelog: changelog)
      changelog.release!(release)
      content = File.read(changelog_path)

      expect(content).to end_with(history)
      expect(content[...content.index('## [5.2.0]')]).not_to include('Your contribution here.', '### Added', '### Security')
      expect(content).to include('### Changed', '**Breaking:**')
      expect(File.read(readme_path)).to include('documentation for the stable release of Hashie, 6.0.0.')

      preparation.prepare!(release, changelog: changelog)
      expect(File.read(changelog_path)).to eq(content)
    end

    it 'restores the contribution template and README for the next development version' do
      preparation.prepare!(release, changelog: changelog)
      changelog.release!(release)
      next_release = release.with_next_version('6.0.1')
      changelog.prepare_next!(next_release)
      preparation.prepare_next!(next_release)
      content = File.read(changelog_path)
      pending = content[content.index('## [Unreleased]')...content.index('## [6.0.0]')]

      expect(pending).to include('[Unreleased]: https://github.com/hashie/hashie/compare/v6.0.0...master')
      expect(pending.scan('* Your contribution here.').size).to eq(6)
      expect(pending.scan(/^### (.+)$/).flatten).to eq(%w[Added Changed Deprecated Removed Fixed Security])
      expect { preparation.validate!(next_release.with_version('6.0.1'), changelog: changelog) }.to raise_error(ArgumentError, /no pending changelog notes/)
      expect(File.read(readme_path)).to include('which should be 6.0.1.', 'stable release is [6.0.0]')

      preparation.prepare_next!(next_release)
      expect(File.read(changelog_path)).to eq(content)
    end

    it 'rejects contribution placeholders as release notes without modifying files' do
      File.write(changelog_path, "# Changelog\n\n## [Unreleased]\n\n### Added\n\n* Your contribution here.\n")
      original = File.read(changelog_path)
      readme = File.read(readme_path)

      expect { preparation.validate!(release, changelog: changelog) }.to raise_error(ArgumentError, /no pending changelog notes/)
      expect { preparation.prepare!(release, changelog: changelog) }.to raise_error(ArgumentError, /no pending changelog notes/)
      expect(File.read(changelog_path)).to eq(original)
      expect(File.read(readme_path)).to eq(readme)
    end

    it 'rejects missing or duplicate README release paragraphs before changing the changelog' do
      original = File.read(changelog_path)
      ['# Hashie', "## Stable Release\n\nFirst.\n\n## Stable Release\n\nSecond.\n"].each do |readme|
        File.write(readme_path, readme)

        expect { preparation.prepare!(release, changelog: changelog) }.to raise_error(ArgumentError, /exactly one stable release paragraph/)
        expect(File.read(changelog_path)).to eq(original)
      end
    end

    it 'includes project metadata in the standard release and next-development commits' do
      with_release_repository do |environment, rake|
        run_command(environment, *rake, 'release:validate', 'release:prepare')

        expect(run_command('git', 'diff', '--cached', '--name-only').lines.map(&:chomp)).to eq(%w[CHANGELOG.md README.md lib/hashie/version.rb])
        expect(File.read(readme_path)).to include('stable release of Hashie, 7.0.0.')
        expect(File.read(changelog_path).split('## [5.2.0]').first).not_to include('Your contribution here.')
        run_command('git', 'commit', '--quiet', '--message', 'Prepared release fixture')
        run_command('git', 'tag', 'v7.0.0')
        run_command('git', 'push', '-q', 'origin', 'master', '--tags')

        run_command(environment, *rake, 'release:bump')

        expect(run_command('git', 'diff-tree', '--no-commit-id', '--name-only', '-r', 'HEAD').lines.map(&:chomp)).to eq(%w[CHANGELOG.md README.md lib/hashie/version.rb])
        expect(File.read(readme_path)).to include('which should be 7.0.1.', 'stable release is [7.0.0]')
        expect(File.read(changelog_path).scan('* Your contribution here.').size).to eq(6)
        expect(run_command('git', 'status', '--porcelain')).to be_empty
        expect(run_command('git', 'rev-parse', 'origin/master')).to eq(run_command('git', 'rev-parse', 'HEAD'))
      end
    end
  end
end
