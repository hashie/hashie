require 'fileutils'
require 'yaml'

module Hashie
  # This is a savable hash, it can be configured and used to store whatever the# contents of the hash are for loading later.  Will serialize in yaml to keep all
  # the dependencies in ruby stdlib.
  class Sash < Hash
    attr_accessor :file
    attr_accessor :backup
    attr_accessor :mode
    attr_accessor :auto_load
    attr_accessor :auto_save

    # overrides:{Hash.new}
    # options: Sash options.
    def initialize(params = {})
      # Throw an exception if we get anything more then the two named hash keys.
      # This is to prevent usage errors (you can't initialize a sash quite like
      # a hash since it takes options or overrides.)
      p = params.select { |k, _| k != :options && k != :overrides }
      fail ArgumentError, "Extra values passed in: #{p}." if p.count > 0

      # set our options to our attributes.
      params[:options].each { |k, v| instance_variable_set '@' + k.to_s, v } if params[:options]

      # should we load our data?
      load if @auto_load

      # did we get any overrides?
      self.merge! params[:overrides] if params[:overrides]

      self
    end

    # The base directory of the save file.
    def basedir
      return nil unless file
      File.dirname File.absolute_path @file
    end

    # The save file plus an extension.
    def backup_file
      "#{@file}.bak"
    end

    # Save the hash to the file, check for backup and set_mode.
    def save
      if any?
        FileUtils.mkdir_p basedir unless Dir.exist? basedir
        backup if @backup

        # I do this the long way because I want an immediate sync.
        f = open(@file, 'w')
        f.write YAML.dump self
        f.sync
        f.close

        set_mode if @mode
      end
      true
    end
    # Store a value in the Hash.  Can autosave.
    def []=(key, value)
      store key, value
      save! if @auto_save == true
    end
    # Save the hash to a file, overwriting if necessary.
    def save!
      delete_file
      save
    end

    # Load the save file into self.
    def load
      clear
      if @file && File.exist?(@file) && File.stat(@file).size > 0
        h = YAML.load open(@file, 'r').read
        h.each { |k, v| self[k] = v }
      end
      self
    end

    # Generate a backup file real quick.
    def backup
      FileUtils.cp @file, backup_file if File.file? @file
    end

    # Set the mode of both the save file and backup file.
    def set_mode
      # Why are we trying to set_mode when we don't even have a file?
      return false unless @file
      File.chmod @mode, @file if File.exist? @file

      # the backup file may not exist for whatever reason, lets not shit if it doesn't.
      return true unless backup_file
      File.chmod @mode, backup_file if File.exist? backup_file
      true
    end

    private

    # Delete the save file.
    def delete_file
      return false unless @file
      FileUtils.rm @file if File.file? @file
      true
    end
  end
end
