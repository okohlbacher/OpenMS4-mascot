cask "openms4-mascot" do
  arch arm: "arm64", intel: "x64"

  version "1.0.0-ci.6,de421c0216d5"
  sha256 arm:   "e9d971bf2eadd3327579a8c6c677caf7bca72e75d8e7ac7c3b4227860328e538",
         intel: "5349bffe84ac6763ed7b44ae32091706d7a2be7e8c03ed7356302916988385a8"

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
    next if core == "7d90cec8718d28518527acc10b495550f106de26"

    raise Cask::CaskError, "openms4-mascot #{version.csv.first} was built against openms4-core 7d90cec8718d, " \
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
