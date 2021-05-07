local Pipeline(os, arch, version) = {
    kind: "pipeline",
    name: os+" - "+arch+" - Julia "+version,
    platform: {
	os: os,
	arch: arch
    },
    steps: [
	{
	    name: "build",
	    image: "julia:"+version,
	    commands: [
	        "apt-get update",
	        "apt-get install -y xvfb xauth",
		"xvfb-run julia --project=. --check-bounds=yes --color=yes -e 'using InteractiveUtils; versioninfo(verbose=true); using Pkg; Pkg.build(); Pkg.test(coverage=true)'"
	    ]
	}
    ],
    trigger: {
        branch: ["master"]
    }
};

[
    # Pipeline("linux", "arm",   "1.3"),
    Pipeline("linux", "arm64", "1.3"),
    Pipeline("linux", "arm64", "1.6"),
]
