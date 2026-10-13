class PelicanBench < Formula
  desc "Benchmark model endpoints locally with a web UI"
  homepage "https://github.com/dahuaxiya/pelican-bench"
  url "https://github.com/dahuaxiya/pelican-bench/releases/download/v0.2.0/pelican-bench-0.2.0.tgz"
  sha256 "c3e42686072a75de87e6a8e56ba038a40b108ebc98e844e6ecaf7fce9622b24a"
  license "MIT"

  depends_on "python@3.13"

  # Brew invokes Python directly; npm keeps its own Node entry point in the same bundle.
  # Both select the same per-user storage before importing the backend, keeping the Cellar immutable.
  def install
    libexec.install Dir["*"]
    (bin/"pelican-bench").write_env_script Formula["python@3.13"].opt_bin/"python3.13",
                                          ["-B", "-u", libexec/"bin/pelican.py"],
                                          PYTHONDONTWRITEBYTECODE: "1", PYTHONUTF8: "1"
  end

  # Optional dependencies and paid requests require a separate user action after installation.
  def caveats
    <<~EOS
      Run pelican-bench to open the local web UI (default port: 8780).
      Configure your own model endpoint and API key in Settings.
      Model requests are sent from your computer; results are stored locally.
      Homebrew uses Python directly; Node.js is only needed for npm installations.

      IQ datasets: pelican-bench setup-iq bbeh  (or arc)
      Engineering: install Docker, then run pelican-bench setup-engineering.
      Official account channels require their corresponding CLI and your own login.
    EOS
  end

  test do
    require "json"
    require "net/http"
    require "timeout"

    assert_equal version.to_s, shell_output("#{bin}/pelican-bench --version").strip
    data = testpath/"bench-data"
    info = JSON.parse(shell_output("#{bin}/pelican-bench doctor --json --data-dir #{data}"))
    assert_match "3.13.", info.fetch("python")
    assert_equal (testpath.realpath/"bench-data").to_s, info.fetch("data_directory")
    refute_predicate data, :exist?
    refute_predicate bin/"pelican", :exist?

    # Spawn accepts string redirection paths, not Pathname. Port 0 avoids a free-port race.
    pid = spawn((bin/"pelican-bench").to_s, "--data-dir", data.to_s, "--port", "0", "--no-browser",
                out: (testpath/"server.log").to_s, err: [:child, :out])
    begin
      state = nil
      http = nil
      Timeout.timeout(60) do
        loop do
          begin
            state = JSON.parse((data/"runtime.json").read)
            # Disable proxies explicitly: these checks must only contact this test's local child.
            http = Net::HTTP.new("127.0.0.1", state.fetch("port"), nil)
            http.open_timeout = 2
            http.read_timeout = 2
            runtime = JSON.parse(http.get("/api/runtime").body)
            break if runtime["instance"] == state["instance"]
          rescue Errno::ENOENT, Errno::ECONNREFUSED, JSON::ParserError, KeyError
            # Lock creation, readiness metadata and HTTP serving have a normal startup window.
          end
          sleep 0.1
        end
      end
      assert_match "<html", http.get("/").body
      assert_equal "200", http.get("/static/capacity.js").code
      assert_match "Already running:", shell_output("#{bin}/pelican-bench --no-browser --data-dir #{data}")
    rescue StandardError
      warn (testpath/"server.log").read
      raise
    ensure
      # Reap only the process owned by this test, including failed startup and assertion paths.
      begin
        Process.kill("TERM", pid)
      rescue Errno::ESRCH
        # An already-exited child still needs wait() below to release its process entry.
      end
      Process.wait(pid)
    end
  end
end
