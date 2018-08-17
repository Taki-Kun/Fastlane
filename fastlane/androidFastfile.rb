# Uncomment the line if you want fastlane to automatically update itself
# update_fastlane

default_platform(:android)

platform :android do
  before_all do |lane, options|
    # git_pull
    ENV['SLACK_URL'] = 'https://hooks.slack.com/services/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'
    # ENV['SLACK_URL'] = 'https://hooks.slack.com/services/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'
    ENV['FL_SLACK_CHANNEL'] = '#devops'
    ENV['FIR_APP_TOKEN'] = '9611b6a99d280463039cbb64b7eb24ca'
    ENV["GIT_BRANCH"] = git_branch
    ENV['GETVERSIONNAME_GRADLE_FILE_PATH'] = 'HelloTalk/build.gradle'
    ENV['GETVERSIONCODE_GRADLE_FILE_PATH'] = 'HelloTalk/build.gradle'
    ENV['GETVERSIONNAME_EXT_CONSTANT_NAME'] = 'versionName'
    ENV['GETVERSIONCODE_EXT_CONSTANT_NAME'] = 'versionCode'
    ENV['VERSIONNAME'] ||= get_version_name
    ENV['VERSIONCODE'] ||= get_version_code
    slack(
      message: "@issenn Start a new build",
      default_payloads: [:git_branch, :lane, :git_author]
    )
    gradle(
      task: "-v"
    )
    gradle(
      task: "clean"
    )
  end

  before_each do |lane, options|
    # ...
  end

  desc "Submit a new Beta Build to Beta"
  lane :do_publish_beta do |options|
    gradle(
      task: "assemble",
      flavor: options[:app],
      build_type: "Release",
      # print_command: false,
      print_command_output: false
    )
    puts lane_context[SharedValues::GRADLE_APK_OUTPUT_PATH]
    puts lane_context[SharedValues::GRADLE_ALL_APK_OUTPUT_PATHS]
    puts lane_context[SharedValues::GRADLE_FLAVOR]
    puts lane_context[SharedValues::GRADLE_BUILD_TYPE]
    begin
      changelog = read_changelog(
        changelog_path: './CHANGELOG.md', # Specify path to CHANGELOG.md
        section_identifier: '[Unreleased]', # Specify what section to read
        excluded_markdown_elements: ['-', '###']  # Specify which markdown elements should be excluded
      )
      upload_apk_to_fir(change_log:changelog)
    rescue => ex
      puts ex
    end

  end

  after_each do |lane, options|
    # ...
  end

  after_all do |lane, options|
    # ...
  end

  error do |lane, exception, options|
    if options[:debug]
      puts "Hi :)"
    end
    UI.message(exception.message)
  end

end