cask "openms4-mascot" do
  arch arm: "arm64", intel: "x64"

  version "1.0.0-ci.8,b45722f915fa"
  sha256 arm:   "c3f4838472a4082e757483d17a34644726aa492f9197d18871bb267a28e926f2",
         intel: "38034bbefbaf092430cd2c323651b760a02c858b42b39a60ef4e3675c705050b"

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
    next if core == "0529ec8bfe0785d546dab56f58456525ef0fef02"

    raise Cask::CaskError, "openms4-mascot #{version.csv.first} was built against openms4-core 0529ec8bfe07, " \
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
