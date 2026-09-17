cask "openms4-mascot" do
  arch arm: "arm64", intel: "x64"

  version "1.0.0-ci.4,384ee0c61fc3"
  sha256 arm:   "61822bb018ed67b2afbc33d6e278867b4eb5a832f0f97c798485ba0fac368c2d",
         intel: "1c9982f4a8809cdd703aad282b725a9661b6597ebd08d50280b0b2e47022d528"

  url "https://github.com/okohlbacher/OpenMS4-mascot/releases/download/" \
      "mascot-v#{version.csv.first}/OpenMS4-mascot-macos-#{arch}-Homebrew-#{version.csv.second}.tar.gz"
  name "OpenMS 4 mascot tools"
  desc "Command-line mass-spectrometry tools built against the OpenMS Core SDK"
  homepage "https://github.com/okohlbacher/OpenMS4-mascot"

  depends_on formula: "okohlbacher/openms4-core/openms4-core"
  depends_on macos: :sequoia

  payload = "OpenMS4-mascot-macos-#{arch}-Homebrew-#{version.csv.second}"
  binary "#{payload}/bin/MascotAdapterOnline"

  # libOpenMS has no versioned name, so a payload only runs with the Core it was built against.
  preflight do
    config = "#{HOMEBREW_PREFIX}/opt/openms4-core/lib/cmake/OpenMS/OpenMSConfig.cmake"
    core = File.exist?(config) ? File.read(config)[/set\(OpenMS_SOURCE_REVISION "([0-9a-f]{40})"\)/, 1] : nil
    next if core == "84847138c0de67149601aaa860af7ac8e2e64534"

    raise Cask::CaskError, "openms4-mascot #{version.csv.first} was built against openms4-core 84847138c0de, " \
                           "but the installed openms4-core is #{core&.slice(0, 12) || "unknown"}. " \
                           "Install the openms4-mascot release built for the installed Core."
  end

  postflight_steps do
    run "/usr/bin/xattr",
        args:           ["-dr", "com.apple.quarantine", "."],
        chdir:          ".",
        writable_paths: ["."]
  end
end
