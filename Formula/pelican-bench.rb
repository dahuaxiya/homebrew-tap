class PelicanBench < Formula
  desc "Benchmark model endpoints locally with a web UI"
  homepage "https://github.com/dahuaxiya/homebrew-tap"
  url "https://github.com/dahuaxiya/homebrew-tap/releases/download/v0.1.0/pelican-bench-0.1.0.tgz"
  sha256 "3f6e7841207a2b05a69ca4138f4d0875478bcdf03982039ffc934c6f7f1c76cb"
  license :cannot_represent

  depends_on "node"
  depends_on "python@3.13"

  # The bundle has no npm runtime dependencies. Keep it read-only in the Cellar;
  # the CLI selects a separate per-user directory for credentials and results.
  def install
    libexec.install Dir["*"]
    (bin/"pelican-bench").write_env_script Formula["node"].opt_bin/"node",
                                          [libexec/"bin/pelican-bench.mjs"],
                                          PELICAN_BENCH_PYTHON: Formula["python@3.13"].opt_bin/"python3.13"
  end

  def caveats
    <<~EOS
      Run pelican-bench to open the local web UI (default port: 8780).
      Configure your own model endpoint and API key in Settings.
      Model requests are sent from your computer; results are stored locally.

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
