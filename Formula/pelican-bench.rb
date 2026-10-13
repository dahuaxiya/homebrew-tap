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

    assert_equal version.to_s, shell_output("#{bin}/pelican-bench --version").strip
    data = testpath/"bench-data"
    info = JSON.parse(shell_output("#{bin}/pelican-bench doctor --json --data-dir #{data}"))
    assert_match "3.13.", info.fetch("python")
    assert_equal (testpath.realpath/"bench-data").to_s, info.fetch("data_directory")
    refute_predicate data, :exist?

    # Only loopback health/static requests: never use personal accounts or paid models.
    port = free_port
    pid = fork do
      exec bin/"pelican-bench", "--data-dir", data.to_s, "--port", port.to_s, "--no-browser",
           [:out, :err] => testpath/"server.log"
    end
    begin
      response = nil
      40.times do
        sleep 0.25
        response = Utils.safe_popen_read("curl", "--silent", "--fail", "--max-time", "1",
                                        "http://127.0.0.1:#{port}/api/runtime")
        break if response.include?("pelican-bench")
      rescue ErrorDuringExecution
        # Python may still be importing modules when the first request arrives.
        next
      end
      assert_equal "pelican-bench", JSON.parse(response).fetch("application")
      assert_match "<html", shell_output("curl --silent --fail http://127.0.0.1:#{port}/")
    ensure
      Process.kill("TERM", pid)
      Process.wait(pid)
    end
  end
end
