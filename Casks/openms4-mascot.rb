cask "openms4-mascot" do
  arch arm: "arm64", intel: "x64"

  version "1.0.0-ci.2,fcbcc61346c3"
  sha256 arm:   "75004728d630032011c6fec9190211cd878b0422ffe36dc61218d91e520fffcd",
         intel: "4ae5ca5387bd52e95f4279e8e41b6ec015b25de28a788bbd2902eaba7b10dc27"

  url "https://github.com/okohlbacher/OpenMS4-mascot/releases/download/" \
      "mascot-v#{version.csv.first}/OpenMS4-mascot-macos-#{arch}-Homebrew-#{version.csv.second}.tar.gz"
  name "OpenMS 4 mascot tools"
  desc "Command-line mass-spectrometry tools built against the OpenMS Core SDK"
  homepage "https://github.com/okohlbacher/OpenMS4-mascot"

  depends_on formula: "okohlbacher/openms4-core/openms4-core"
  depends_on macos: :sequoia

  payload = "OpenMS4-mascot-macos-#{arch}-Homebrew-#{version.csv.second}"
  binary "#{payload}/bin/MascotAdapterOnline"

  postflight_steps do
    run "/usr/bin/xattr",
        args:           ["-dr", "com.apple.quarantine", "."],
        chdir:          ".",
        writable_paths: ["."]
  end
end
