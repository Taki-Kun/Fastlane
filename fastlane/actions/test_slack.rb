module Fastlane
  module Actions
    class TestSlackAction < Action
      def self.run(params)
          Actions.slack(
            message: "Hi!",
            success: true,
            default_payloads: [:git_branch, :lane, :git_author, :test_result]
          )
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "A short description with <= 80 characters of what this action does"
      end

      def self.details
        # Optional:
        # this is your chance to provide a more detailed description of this action
        "You can use this action to do cool things..."
      end

      def self.available_options
        # Define all options your action supports.

        # Below a few examples
      end

      def self.output
        # Define the shared values you are going to provide
        # Example
      end

      def self.return_value
        # If you method provides a return value, you can describe here what it does
      end

      def self.authors
        # So no one will ever forget your contribution to fastlane :) You are awesome btw!
        ["issenn"]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
