## Requirements

```bash
nix shell nixpkgs#just github:pinpox/pgp2ssh github:serokell/deploy-rs
```

## Common

```bash
just dev
```

## Update sing-box's config

```bash
just update-configs
```

## Rebuild System Configuration

```bash
just rebuild-sys
```

## NixOS Server

```bash
just deploy-server
```

## References

- [dev_flake](https://github.com/magic0whi/dev_flake)
- [sing-box-subscribe](https://github.com/Toperlock/sing-box-subscribe)
- [nix-darwin](https://github.com/nix-darwin/nix-darwin)
- [just](https://github.com/casey/just)
- [deploy-rs](https://github.com/serokell/deploy-rs)

## Acknowledgements

I gratefully acknowledge chezmoi's powerful templating and field-level encryption capabilities, which make it possible to securely manage and publicize these configurations.

- [KeePassXC](https://keepassxc.org/)
- [chezmoi](https://www.chezmoi.io/)
