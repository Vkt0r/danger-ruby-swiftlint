# frozen_string_literal: true

# A wrapper to use SwiftLint via a Ruby API.
class Swiftlint

  # The list of config files availables in the source
  attr_reader :config_files

  def initialize(swiftlint_path = nil)
    @swiftlint_path = swiftlint_path
    @config_files = Dir.glob('./**/.swiftlint.yml')
                       .reject { |filepath| filepath.include?('Carthage' || 'Pods') }
                       .map { |filepath| File.dirname(filepath) }
                       .map { |filepath| filepath[1..-1] }
                       .reject(&:empty?)
                       .sort_by(&:length)
                       .reverse
  end

  # Runs swiftlint
  def run(cmd = 'lint', additional_swiftlint_args = '', options = {})
    # change pwd before run swiftlint
    Dir.chdir options.delete(:pwd) if options.key? :pwd

    # format the path to compare it
    file_path = File.dirname(options[:path]).delete('\\', '')
    # find the deepest dir with a config file contained in the filepath
    config_file = @config_files.find { |path| file_path.include? path }
    # replace the default config file if there is one deepest in the path
    options[:config] = (config_file[1..-1].gsub(' ', '\\ ') + '/.swiftlint.yml') unless config_file.nil?

    # run swiftlint with provided options
    `#{swiftlint_path} #{cmd} #{swiftlint_arguments(options, additional_swiftlint_args)}`
  end

  # Shortcut for running the lint command
  def lint(options, additional_swiftlint_args)
    run('lint', additional_swiftlint_args, options)
  end

  # Return true if swiftlint is installed or false otherwise
  def installed?
    File.exist?(swiftlint_path)
  end

  # Return swiftlint execution path
  def swiftlint_path
    @swiftlint_path || default_swiftlint_path
  end

  private

  # Parse options into shell arguments how swift expect it to be
  # more information: https://github.com/Carthage/Commandant
  # @param options (Hash) hash containing swiftlint options
  def swiftlint_arguments(options, additional_swiftlint_args)
    (options.
      # filter not null
      reject { |_key, value| value.nil? }.
      # map booleans arguments equal true
      map { |key, value| value.is_a?(TrueClass) ? [key, ''] : [key, value] }.
      # map booleans arguments equal false
      map { |key, value| value.is_a?(FalseClass) ? ["no-#{key}", ''] : [key, value] }.
      # replace underscore by hyphen
      map { |key, value| [key.to_s.tr('_', '-'), value] }.
      # prepend '--' into the argument
      map { |key, value| ["--#{key}", value] }.
      # reduce everything into a single string
      reduce('') { |args, option| "#{args} #{option[0]} #{option[1]}" } +
      " #{additional_swiftlint_args}").
      # strip leading spaces
      strip
  end

  # Path where swiftlint should be found
  def default_swiftlint_path
    File.expand_path(File.join(File.dirname(__FILE__), 'bin', 'swiftlint'))
  end
end
