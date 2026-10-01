class Margin < Formula
  desc "Review AI-written markdown like a Google Doc"
  homepage "https://github.com/ariboren/margin"
  url "https://registry.npmjs.org/margin-md/-/margin-md-0.2.1.tgz"
  sha256 "bdf805ca9c187877519e4ea51c8825d028a15f13813f4ad9bfdf9e2e46184ad4"
  license "MIT"

  depends_on "bun"

  # The npm tarball has no lockfile; the tagged one pins the dependency install.
  resource "bun.lock" do
    url "https://raw.githubusercontent.com/ariboren/margin/v0.2.1/bun.lock"
    sha256 "d03265545ae9294161c9606302a8f48e93a5a9a4566f8275c7ee58fa667ad58a"
  end

  def install
    libexec.install Dir["*"]
    resource("bun.lock").stage { libexec.install "bun.lock" }

    ENV["BUN_INSTALL_CACHE_DIR"] = buildpath/"bun-cache"
    cd libexec do
      system formula_opt_bin("bun")/"bun", "install", "--production", "--frozen-lockfile",
             "--ignore-scripts", "--no-progress"
    end

    # margin re-executes its own runtime for the daemon, so bun must come from PATH.
    (bin/"margin").write_env_script libexec/"src/cli/main.ts",
                                    PATH: "#{formula_opt_bin("bun")}:$PATH"
  end

  test do
    help = shell_output("#{bin}/margin agent-help")
    assert_operator help.bytesize, :>, 1000
    assert_match "margin watch", help

    ENV["MARGIN_STATE_DIR"] = testpath.to_s
    assert_equal "not running", shell_output("#{bin}/margin status").strip
  end
end
