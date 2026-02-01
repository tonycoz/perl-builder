## Perl build scripts

This repository is part of the [Compiler
Explorer](https://compiler-explorer/) project.

It builds the docker images used to build the various Perl
interpreters on the site.

## To Test

This assumes you have set up your user account to be able to run
`docker` [without being
root](https://docs.docker.com/engine/security/rootless/); if you
haven't done so, you'll need to prefix these commands with `sudo`.

- `docker build -t perlbuilder .`
- `docker run perlbuilder ./build.sh trunk /dist`

If you want to collect the generated archive:

- `docker run --rm -v/localpath:/dist perlbuilder ./build.sh 5.42.0 /dist`

For debugging:

- `docker run -t-i perlbuilder bash`
- `./build.sh trunk /dist`

The version parameter accepts:
- a released version of perl like `5.8.9` or `5.42.0`,
- one of the development branch names, like `blead`, the perl trunk, or like `maint-5.42`, the working branch for the next 5.42.x.

This uses
[Devel::PatchPerl](https://metacpan.org/dist/Devel-PatchPerl) to patch
old releases to build on modern system, it does not try to patch blead
or maint branches.

