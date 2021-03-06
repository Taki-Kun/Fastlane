# Uncomment the line if you want fastlane to automatically update itself
# update_fastlane

default_platform(:android)

platform :android do
  before_all do |lane, options|
    # git_pull
    # ENV['SLACK_URL'] = 'https://hooks.slack.com/services/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'
    # ENV['SLACK_URL'] = 'https://hooks.slack.com/services/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'
    ENV['SLACK_URL'] = 'https://hooks.slack.com/services/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'
    ENV['FL_SLACK_CHANNEL'] = '#devops'
    ENV['FL_SLACK_LINK_NAMES'] = 'true'
    # ENV['MAILGUN_SANDBOX_POSTMASTER'] = 'issenn@sandboxc3b6b7d6022b484eabc7c39f728536a5.mailgun.org'
    # ENV['MAILGUN_APIKEY'] = '5d21a2e0cce1996b200d8f991d72856d-a4502f89-ce938adb'
    # ENV['FIR_APP_TOKEN'] = '9611b6a99d280463039cbb64b7eb24ca'
    ENV["GIT_BRANCH"] = git_branch
    ENV['GETVERSIONNAME_GRADLE_FILE_PATH'] = 'HelloTalk/build.gradle'
    ENV['GETVERSIONCODE_GRADLE_FILE_PATH'] = 'HelloTalk/build.gradle'
    ENV['GETVERSIONNAME_EXT_CONSTANT_NAME'] = 'versionName'
    ENV['GETVERSIONCODE_EXT_CONSTANT_NAME'] = 'versionCode'
    ENV['VERSIONNAME'] ||= get_version_name
    ENV['VERSIONCODE'] ||= get_version_code
    ENV['CHANGELOG'] = read_changelog(
      changelog_path: './CHANGELOG.md', # Specify path to CHANGELOG.md
      section_identifier: '[Unreleased]', # Specify what section to read
      excluded_markdown_elements: ['-', '###']  # Specify which markdown elements should be excluded
    )
    slack(
      message: "Hi! @channel \r\n A new build start",
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
    do_upload_firim_for_all
  end

  lane :do_upload_firim_for_all do
    all_apk_paths = lane_context[SharedValues::GRADLE_ALL_APK_OUTPUT_PATHS] || []
    apk_paths = [lane_context[SharedValues::GRADLE_APK_OUTPUT_PATH], all_apk_paths].flatten.compact
    apk_paths = [lane_context[SharedValues::GRADLE_APK_OUTPUT_PATH]] unless (apk_paths = all_apk_paths)
    apk_paths.each do | apk |
      flavor = lane_context[SharedValues::GRADLE_FLAVOR] || /([^\/-]*)(?=-[^\/-]*\.apk$)/.match(apk)
      change_log = "[#{flavor}]+[#{ENV['GIT_BRANCH']}]\r\n---\r\n" + ENV['CHANGELOG']
      puts "Uploading APK to fir: " + apk
      # sh "sudo /usr/local/bin/fir p '#{apk}' -T '#{params[:app_key]}' -c '#{change_log}'"
      firim(
        apk: apk,
        app_version: get_version_name,
        app_build_version: get_version_code
      )
    end
  end

  desc "Submit a new Release Build to all"
  lane :do_publish_all do |options|
    do_publish_china
    do_publish_google
  end

  desc "Submit a new Release Build to China"
  lane :do_publish_china do |options|
    gradle(
      task: "assemble",
      flavor: "China",
      build_type: "Release",
      print_command_output: false
    )
    do_upload_firim
  end

  desc "Submit a new Release Build to Google"
  lane :do_publish_google do |options|
    gradle(
      task: "assemble",
      flavor: "Google",
      build_type: "Release",
      print_command_output: false
    )
    do_upload_firim
  end

  $upload_retry=0

  lane :do_upload_firim do
    puts lane_context[SharedValues::GRADLE_APK_OUTPUT_PATH]
    puts lane_context[SharedValues::GRADLE_ALL_APK_OUTPUT_PATHS]
    puts lane_context[SharedValues::GRADLE_FLAVOR]
    puts lane_context[SharedValues::GRADLE_BUILD_TYPE]
    puts get_version_name
    puts get_version_code
    begin
      flavor = lane_context[SharedValues::GRADLE_FLAVOR] || /([^\/-]*)(?=-[^\/-]*\.apk$)/.match(apk)
      slack(
        message: "Hi! @issenn \r\n A new app uploading \r\nFlavor: #{flavor}",
        default_payloads: [:git_branch, :lane, :git_author]
      )
      change_log = "[#{flavor}]+[#{ENV['GIT_BRANCH']}]\r\n---\r\n" + ENV['CHANGELOG']
      firim(
        apk: lane_context[SharedValues::GRADLE_APK_OUTPUT_PATH],
        app_version: get_version_name,
        app_build_version: get_version_code,
        app_changelog: change_log
      )
      slack(
        message: "Hi! @issenn \r\n A new app upload success \r\nFlavor: #{flavor} \r\n#{ENV['CHANGELOG']}",
        success: true,
        default_payloads: [:git_branch, :lane, :git_author, :test_result]
      )
      send_e_mail(
        stmp_server: "smtp.exmail.qq.com",
        user_name: "update@hellotalk.com",
        password: "Hello123",
        subject: "default",
        message_body: "Hi! @issenn \r\n A new app upload success \r\nFlavor: #{flavor} \r\n#{ENV['CHANGELOG']}",
        recipients: ["issenn@hellotalk.com", "update@hellotalk.com"]
      )
      $upload_retry=0
    rescue => ex
      $upload_retry += 1
      if $upload_retry < 3
        do_upload_firim
      else
        slack(
          message: "Hi! @issenn \r\n A new app upload failed \r\nFlavor: #{flavor}",
          success: false,
          default_payloads: [:git_branch, :lane, :git_author, :test_result]
        )
        # raise ex
        puts ex
      end
    end
  end
=begin
  lane :do_upload do
    slack(
      message: "Hi! @issenn \r\n A new app uploading",
      default_payloads: [:git_branch, :lane, :git_author]
    )
    begin
      upload_apk_to_fir(change_log:ENV['CHANGELOG'])
      slack(
        message: "Hi! @issenn \r\n A new app upload success \r\n #{ENV['CHANGELOG']}",
        success: true,
        default_payloads: [:git_branch, :lane, :git_author, :test_result]
      )
      mailgun(
        to: "issenn@hellotalk.com",
        success: true,
        app_link: "https://fir.im/hellotalkandroid",
        message: "#{ENV['CHANGELOG']}"
      )
    rescue => ex
      $upload_retry += 1
      if $upload_retry < 3
        do_upload
      else
        slack(
          message: "Hi! @issenn \r\n A new app upload failed",
          success: false,
          default_payloads: [:git_branch, :lane, :git_author, :test_result]
        )
        send_e_mail(
          stmp_server: "smtp.exmail.qq.com",
          user_name: "issenn@hellotalk.com",
          password: "Mn20104125106",
          subject: "default",
          message_body: "content",
          recipients: "issenn@hellotalk.com"
        )
        # raise ex
        puts ex
      end
    end
  end
=end

  after_each do |lane, options|
    # ...
  end

  after_all do |lane, options|
    slack(
      message: "Hi! @channel \r\n A new build end",
      default_payloads: [:git_branch, :lane, :git_author]
    )
  end

  error do |lane, exception, options|
    if options[:debug]
      puts "Hi :)"
    end
    UI.message(exception.message)
  end

end