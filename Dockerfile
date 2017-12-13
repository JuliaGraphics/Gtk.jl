# Derived from https://github.com/docker-library/julia which is distributed
# under the terms of the MIT Expat license and is 
# Copyright (c) 2014-2015 Docker, Inc.


# FROM ubuntu:trusty-20171117
FROM ubuntu:xenial-20171114
# FROM ubuntu:zesty-20171114
# FROM ubuntu:artful-20171116
# FROM debian:jessie

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		ca-certificates \
		curl

ENV JULIA_PATH /usr/local/julia

# https://julialang.org/downloads/
ENV JULIA_VERSION 0.6.1

RUN set -ex; \
	\
# https://julialang.org/downloads/#julia-command-line-version
# https://julialang-s3.julialang.org/bin/checksums/julia-0.6.1.sha256
# this "case" statement is generated via "update.sh"
	dpkgArch="$(dpkg --print-architecture)"; \
	case "${dpkgArch##*-}" in \
		amd64) tarArch='x86_64'; dirArch='x64'; sha256='d73f988b4d5889b30063f40c2f9ad4a2487f0ea87d6aa0b8ed53e789782bb323' ;; \
		armhf) tarArch='armv7l'; dirArch='armv7l'; sha256='ee2cea5a6e5763fb2ef38b585560000c7fb2cee9a7e2330d4eae278beed4d7e6' ;; \
		arm64) tarArch='aarch64'; dirArch='aarch64'; sha256='945c1657ca4a8d76b7136829cf06dddbd5343dfdfa6b20d2308ae0dc08c5ca79' ;; \
		i386) tarArch='i686'; dirArch='x86'; sha256='88cf40e45558958f9a23540d52209fd050d82512bbbe8dec03db7d0976cc645a' ;; \
		*) echo >&2 "error: current architecture ($dpkgArch) does not have a corresponding Julia binary release"; exit 1 ;; \
	esac; \
	\
	curl -fL -o julia.tar.gz     "https://julialang-s3.julialang.org/bin/linux/${dirArch}/${JULIA_VERSION%[.-]*}/julia-${JULIA_VERSION}-linux-${tarArch}.tar.gz"; \
	curl -fL -o julia.tar.gz.asc "https://julialang-s3.julialang.org/bin/linux/${dirArch}/${JULIA_VERSION%[.-]*}/julia-${JULIA_VERSION}-linux-${tarArch}.tar.gz.asc"; \
	\
	mkdir "$JULIA_PATH"; \
	tar -xzf julia.tar.gz -C "$JULIA_PATH" --strip-components 1; \
	rm julia.tar.gz


ENV PATH $JULIA_PATH/bin:$PATH

# Copy the current directory contents into the container at /app
ADD . /Gtk

# Set the working directory to /app
WORKDIR /Gtk

RUN echo 'APT::Get::Assume-Yes "true";' | tee -a /etc/apt/apt.conf.d/00Do-not-ask

RUN julia -e "Pkg.init()"
RUN DEBIAN_FRONTEND=noninteractive julia -e "Pkg.clone(pwd()); Pkg.build(\"Gtk\")"

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		xvfb \
		xauth

RUN xvfb-run julia -e "Pkg.test(\"Gtk\")"
