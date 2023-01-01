# avalanche

Expose [boulder](https://github.com/serpent-os/boulder/) as a service for the build infrastructure of Serpent OS. This software makes use of `vibe.d` to provide a sane RPC API for build management.

## Design Notes

An Avalanche instance is never directly interacted with. It is instead integrated into the infrastructure via [summit](https://github.com/serpent-os/summit/).

Build artefacts are **never** uploaded into a privileged location. Instead `summit` will instruct the repository controller, [vessel](https://github.com/serpent-os/vessel/) to fetch and integrate the assets securely.

## How to build

Depends on libsodium-devel and clones of avalanche (this repo), [moss-service](https://github.com/serpent-os/moss-service/) and [onboarding](https://github.com/serpent-os/onboarding/) living next to each other under a shared root (e.g. `~/repos/serpent-os`).

Run `dub build --parallel` to build.

## How to run

`dub run`

## License

Copyright &copy; 2020-2023 Serpent OS Developers

Available under the terms of the [Zlib](https://spdx.org/licenses/Zlib.html) license.
