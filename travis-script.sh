#!/bin/bash

set -ex

if [[ "$DOCKER_BUILD" = true ]]; then 
	docker build -t gtkjl .
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