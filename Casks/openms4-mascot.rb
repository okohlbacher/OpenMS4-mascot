cask "openms4-mascot" do
  arch arm: "arm64", intel: "x64"

  version "1.0.0-ci.7,f2e3db39e7fd"
  sha256 arm:   "4893d412461d1e4b6cc134f8d64e9bc10f0a9d6bb99471a9a4c1f6e59e4b4f97",
         intel: "c2efa2384f9a9cd7c9d65c24cbf1216376da109155c7b18e0cc71bf78de9663e"

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
    next if core == "83ce20da78337b0b329f5c634e52226585e4788d"

    raise Cask::CaskError, "openms4-mascot #{version.csv.first} was built against openms4-core 83ce20da7833, " \
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
