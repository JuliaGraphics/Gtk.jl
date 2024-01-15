# This script was how the new adwaita_icon_theme artifact was generated.
using Tar: Tar
using Pkg.Artifacts: bind_artifact!, create_artifact, archive_artifact, artifact_path
using Pkg: Pkg, PlatformEngines
using Base.BinaryPlatforms: Platform
using Random: seed!
using CodecZlib: GzipCompressor
using SHA: sha256

seed!(1234)

windows_platforms = [
    # Windows
    Platform("i686", "windows"),
    Platform("x86_64", "windows"),
]

other_platforms = [
    # glibc Linuces
    Platform("i686", "linux"),
    Platform("x86_64", "linux"),
    Platform("aarch64", "linux"),
    Platform("armv6l", "linux"),
    Platform("armv7l", "linux"),
    Platform("powerpc64le", "linux"),

    # musl Linuces
    Platform("i686", "linux"; libc="musl"),
    Platform("x86_64", "linux"; libc="musl"),
    Platform("aarch64", "linux"; libc="musl"),
    Platform("armv6l", "linux"; libc="musl"),
    Platform("armv7l", "linux"; libc="musl"),

    # BSDs
    Platform("x86_64", "macos"),
    Platform("aarch64", "macos"),
    Platform("x86_64", "freebsd"),
]

# This is the url that the new windows artifact will be available from:
url_to_upload_to = "https://github.com/medyan-dev/SmallZarrGroups.jl/releases/download/v0.6.6/copy_symlinks_adwaita_icon_theme.v3.33.92.any.tar.gz"
windows_tarball = joinpath(@__DIR__, "copy_symlinks_adwaita_icon_theme.v3.33.92.any.tar.gz")

# This is the url of the source artifact:
url_src = "https://github.com/JuliaBinaryWrappers/adwaita_icon_theme_jll.jl/releases/download/adwaita_icon_theme-v3.33.92+4/adwaita_icon_theme.v3.33.92.any.tar.gz"
tree_hash_src = Base.SHA1("65eca7c48dea1e32203b205613441ce9506045b4")
tar_sha256_src = "f50f3c85710f7dfbd6959bfaa6cc3a940195cd09dadddefb3b5ae9a2f97adad3"

# This is the path to the Artifacts.toml we will manipulate
artifact_toml = joinpath(@__DIR__, "../Artifacts.toml")

for p in other_platforms
    bind_artifact!(artifact_toml, "adwaita_icon_theme", tree_hash_src;
        platform=p,
        force=true,
        download_info=[(url_src, tar_sha256_src)],
    )
end

# Now copy symlinks to allow the artifact to be installed on windows
tree_hash_windows = create_artifact() do dir
    Tar.extract(`$(PlatformEngines.exe7z()) x $(download(url_src)) -so`, dir;
        copy_symlinks=true,
    )
end
tar_tempfile = Tar.create(artifact_path(tree_hash_windows); portable=true)
tarball_data = transcode(GzipCompressor, read(tar_tempfile))
tar_sha256_windows = bytes2hex(sha256(tarball_data))
write(windows_tarball, tarball_data)

for p in windows_platforms
    bind_artifact!(artifact_toml, "adwaita_icon_theme", tree_hash_windows;
        platform=p,
        force=true,
        download_info=[(url_to_upload_to, tar_sha256_windows)],
    )
end