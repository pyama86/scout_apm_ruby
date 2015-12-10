module ScoutApm
  class Middleware
    MAX_ATTEMPTS = 5

    def initialize(app)
      @app = app
      @attempts = 0
      @started = ScoutApm::Agent.instance.started?
    end

    # If we get a web request in, then we know we're running in some sort of app server
    def call(env)
      if @started || @attempts > MAX_ATTEMPTS
        @app.call(env)
      else
        attempt_to_start_agent
        @app.call(env)
      end
    end

    def attempt_to_start_agent
      @attempts += 1
      ScoutApm::Agent.instance.start(:skip_app_server_check => true)
      @started = ScoutApm::Agent.instance.started?
    rescue => e
      # Can't be sure of any logging here, so fall back to ENV var and STDOUT
      if ENV["SCOUT_LOG_LEVEL"] == "debug"
        STDOUT.puts "Failed to start via Middleware: #{e.message}\n\t#{e.backtrace.join("\n\t")}"
      end
    end
  end
end