# Working CI

If you are using `Gtk` in your code and want to test it on Linux with Travis for example, you'll need to use `xvfb-run`. In your `.travis.yml`, add the following:

```yml
addons:
    apt:
        packages:
            - xvfb
            - xauth
            - libgtk-3-0
script:
    - if [[ -a .git/shallow ]]; then git fetch --unshallow; fi
    - if [[ `uname` = "Linux" ]]; then TESTCMD="xvfb-run julia"; else TESTCMD="julia"; fi
    - $TESTCMD -e 'Pkg.clone(pwd());
        Pkg.build("<yourPackage>");
        Pkg.test("<yourPackage>"; coverage=true)'
```

Where `<yourPackage>` is the name of the package that uses `Gtk`.
