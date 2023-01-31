# frozen_string_literal: true
module Twilio
  module Rails
    class ApplicationOperation < ActiveOperation::Base
      # Annotates the log output for every operation with the execution time.
      around do |instance, executable|
        @operation_runtime_start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        executable.call
        @operation_runtime_stop = Process.clock_gettime(Process::CLOCK_MONOTONIC)

        ::Twilio::Rails.config.logger.tagged(self.class) { |l| l.info("execution time #{ instance.operation_runtime_seconds } seconds")}
      end

      protected

      def operation_runtime_seconds
        (@operation_runtime_stop || Process.clock_gettime(Process::CLOCK_MONOTONIC)) - @operation_runtime_start
      end
    end
  end
end
