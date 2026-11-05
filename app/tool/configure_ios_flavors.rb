#!/usr/bin/env ruby

require 'fileutils'
require 'xcodeproj'

project_path = File.expand_path('../ios/Runner.xcodeproj', __dir__)
scheme_dir = File.join(project_path, 'xcshareddata', 'xcschemes')
project = Xcodeproj::Project.open(project_path)
flutter_group = project.main_group.find_subpath('Flutter', false)
raise 'Missing Flutter project group' unless flutter_group

environments = {
  'dev' => { suffix: '.dev', display_name: 'Named Dev' },
  'staging' => { suffix: '.staging', display_name: 'Named Staging' },
  'prod' => { suffix: '', display_name: 'Named' },
}
base_configurations = {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

profile_reference = flutter_group.files.find do |file|
  File.basename(file.path.to_s) == 'Profile.xcconfig'
end
profile_reference ||= flutter_group.new_file('Flutter/Profile.xcconfig')
profile_reference.name = 'Profile.xcconfig'
profile_reference.path = 'Flutter/Profile.xcconfig'
runner_target = project.targets.find { |target| target.name == 'Runner' }
runner_profile = runner_target&.build_configurations&.find do |configuration|
  configuration.name == 'Profile'
end
runner_profile.base_configuration_reference = profile_reference if runner_profile

def clone_configuration(owner, source, name, type)
  existing = owner.build_configurations.find { |configuration| configuration.name == name }
  destination = existing || owner.add_build_configuration(name, type)
  destination.build_settings = source.build_settings.dup
  destination.base_configuration_reference = source.base_configuration_reference
  destination
end

base_configurations.each do |base_name, type|
  project_source = project.build_configurations.find { |configuration| configuration.name == base_name }
  raise "Missing project configuration #{base_name}" unless project_source

  environments.each_key do |environment|
    clone_configuration(
      project,
      project_source,
      "#{base_name}-#{environment}",
      type,
    )
  end

  project.targets.each do |target|
    target_source = target.build_configurations.find { |configuration| configuration.name == base_name }
    raise "Missing #{target.name} configuration #{base_name}" unless target_source

    environments.each do |environment, values|
      configuration = clone_configuration(
        target,
        target_source,
        "#{base_name}-#{environment}",
        type,
      )

      if target.name == 'Runner'
        configuration.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] =
          "com.named.app#{values[:suffix]}"
        configuration.build_settings['APP_DISPLAY_NAME'] = values[:display_name]
        xcconfig_name = "#{base_name}-#{environment}.xcconfig"
        file_reference = flutter_group.files.find do |file|
          File.basename(file.path.to_s) == xcconfig_name
        end
        file_reference ||= flutter_group.new_file("Flutter/#{xcconfig_name}")
        file_reference.name = xcconfig_name
        file_reference.path = "Flutter/#{xcconfig_name}"
        configuration.base_configuration_reference = file_reference
      elsif target.name == 'RunnerTests'
        configuration.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] =
          "com.named.app#{values[:suffix]}.RunnerTests"
      end
    end
  end
end

project.save

runner_scheme_path = File.join(scheme_dir, 'Runner.xcscheme')
source_scheme_path = File.exist?(runner_scheme_path) ? runner_scheme_path : File.join(scheme_dir, 'dev.xcscheme')
runner_scheme = File.read(source_scheme_path).gsub(
  /buildConfiguration = "(Debug|Profile|Release)-(dev|staging|prod)"/,
  'buildConfiguration = "\\1"',
)
environments.each_key do |environment|
  scheme = runner_scheme
    .gsub('buildConfiguration = "Debug"', "buildConfiguration = \"Debug-#{environment}\"")
    .gsub('buildConfiguration = "Profile"', "buildConfiguration = \"Profile-#{environment}\"")
    .gsub('buildConfiguration = "Release"', "buildConfiguration = \"Release-#{environment}\"")
  File.write(File.join(scheme_dir, "#{environment}.xcscheme"), scheme)
end
FileUtils.rm_f(runner_scheme_path)

puts 'Configured iOS schemes: dev, staging, prod'
