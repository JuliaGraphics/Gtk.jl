#!/bin/bash

set -ex

if [[ -a .git/shallow ]]; then 
	git fetch --unshallow
fi
if [[ "$DOCKER_BUILD" = true ]]; then 
	docker build -t gtkjl . && docker run gtkjl
else
	if [[ `uname` = "Linux" ]]; then 
		TESTCMD="xvfb-run julia"
	else 
		TESTCMD="julia"
	fi
	$TESTCMD -e 'Pkg.clone(pwd()); using BinDeps;
	      println(BinDeps.debug("Gtk"));
	      Pkg.build("Gtk");
	      Pkg.test("Gtk"; coverage=true)'
fi