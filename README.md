## Common

```bash
nix develop github:magic0whi/dev_flake#python -c zsh
```

## Update sing-box's config

MacOS env:
```bash
export REPO_HOME=~/sync_work/proxy_tmpl
export SUB_HOME=~/sync_work/sing-box-subscribe
```

NixOS env:
```bash
export REPO_HOME=/srv/sync_work/proxy_tmpl
export SUB_HOME=/srv/sync_work/sing-box-subscribe
```

```bash
pushd $REPO_HOME && unset REPO_HOME \
  && export PROXY_TMP=$(mktemp --directory) \
  && gpg --quiet --batch --yes --output $PROXY_TMP/tmp.key --decrypt proxy_kdbx.key.asc \
  && sed -r "s,REPLACE,$PROXY_TMP/tmp.key," chezmoi.toml > $PROXY_TMP/chezmoi.toml \
  && chezmoi -c $PROXY_TMP/chezmoi.toml execute-template < providers.json.tmpl > $SUB_HOME/providers.json \
  && chezmoi --override-data '{"isMobile": true}' -c $PROXY_TMP/chezmoi.toml execute-template < sb_client.json.tmpl > $SUB_HOME/config_template/0mobile.json \
  && chezmoi --override-data '{"isDarwin": true}' -c $PROXY_TMP/chezmoi.toml execute-template < sb_client.json.tmpl > $SUB_HOME/config_template/1darwin.json \
  && chezmoi --override-data '{"isLinux": true}' -c $PROXY_TMP/chezmoi.toml execute-template < sb_client.json.tmpl > $SUB_HOME/config_template/2linux.json \
  && chezmoi --override-data '{"isLinux": true, "isMobile": true}' -c $PROXY_TMP/chezmoi.toml execute-template < sb_client.json.tmpl > $SUB_HOME/config_template/2rooted.json \
  && chezmoi -c $PROXY_TMP/chezmoi.toml execute-template < clash.yaml.tmpl > $SUB_HOME/clash.yaml \
  && rm -r $PROXY_TMP && unset PROXY_TMP \
&& popd \
&& pushd $SUB_HOME && unset SUB_HOME \
  && python main.py --template_index 0 && mv config.json mobile.json \
  && python main.py --template_index 1 && mv config.json darwin.json \
  && python main.py --template_index 2 && mv config.json linux.json \
  && python main.py --template_index 3 && mv config.json rooted.json \
&& popd
```

## Rebuild System Configuration

MacOS env:
```bash
export SUB_HOME=~/sync_work/sing-box-subscribe
export NIXOS_CONFIGS_SECRETS=~/nixos_configs_flake/secrets
```

NixOS env:
```bash
export SUB_HOME=/srv/sync_work/sing-box-subscribe
export NIXOS_CONFIGS_SECRETS=~/nixos_configs_flake/secrets
```

```bash
pushd $NIXOS_CONFIGS_SECRETS && unset NIXOS_CONFIGS_SECRETS \
  && (rm sb_client_darwin.json.age || true) \
  && cat $SUB_HOME/darwin.json \
    | agenix -e sb_client_darwin.json.age -i <(pgp2ssh \
        <<< <(gpg -ao - --export-secret-subkeys 30973F79B17F9ED3\!) \
        <<< 1 2>&1 \
      | awk 'BEGIN { A=0; S=0; } \
        /BEGIN OPENSSH PRIVATE KEY/ { A=1; } \
        { if (A==1) { print; } }' \
    ) \
  && (rm sb_client_linux.json.age || true) \
  && cat $SUB_HOME/linux.json \
    | agenix -e sb_client_linux.json.age -i <(pgp2ssh \
        <<< <(gpg -ao - --export-secret-subkeys 30973F79B17F9ED3\!) \
        <<< 1 2>&1 \
      | awk 'BEGIN { A=0; S=0; } \
        /BEGIN OPENSSH PRIVATE KEY/ { A=1; } \
        { if (A==1) { print; } }' \
    ) \
  && unset SUB_HOME \
  && if [ "$(uname)" = "Darwin" ]; then \
    just proteus-mbp \
    && sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder \
    && sudo launchctl stop io.nekohasekai.sing-box && sleep 2 \
    && sudo launchctl start io.nekohasekai.sing-box; \
  else \
    just proteus-nuc \
    && sudo systemctl restart sing-box.service; \
  fi \
&& popd
```

## NixOS Server

Run `deploy` on a Linux shell since it doesn't build non-darwin binaries on MacOS

NixOS env:
```bash
export REPO_HOME=/srv/sync_work/proxy_tmpl
export NIXOS_CONFIGS_HOME=~/nixos_configs_flake
```

```bash
pushd $REPO_HOME && unset REPO_HOME \
  && export PROXY_TMP=$(mktemp --directory) \
  && gpg --quiet --batch --yes --output $PROXY_TMP/tmp.key --decrypt proxy_kdbx.key.asc \
  && sed -r "s,REPLACE,$PROXY_TMP/tmp.key," chezmoi.toml > $PROXY_TMP/chezmoi.toml \
  && chezmoi -c $PROXY_TMP/chezmoi.toml execute-template < sb_Proteus-NixOS-1.json.tmpl > $PROXY_TMP/sb_Proteus-NixOS-1.json \
&& popd \
&& pushd ~/nixos_configs_flake/secrets \
  && (rm sb_Proteus-NixOS-1.json.age || true) \
  && cat $PROXY_TMP/sb_Proteus-NixOS-1.json \
    | agenix -e sb_Proteus-NixOS-1.json.age -i <(pgp2ssh \
      <<< <(gpg -ao - --export-secret-subkeys 30973F79B17F9ED3\!) \
      <<< 1 2>&1 | awk 'BEGIN { A=0; S=0; } \
        /BEGIN OPENSSH PRIVATE KEY/ { A=1; } \
        { if (A==1) { print; } }' \
    ) \
  && rm -r $PROXY_TMP && unset PROXY_TMP \
  && deploy -s --targets \
    $NIXOS_CONFIGS_HOME#Proteus-NixOS-{1..6} \
  -- --show-trace --verbose \
  && unset NIXOS_CONFIGS_HOME \
&& popd
```

## References

- [dev_flake](https://github.com/magic0whi/dev_flake)
- [sing-box-subscribe](https://github.com/Toperlock/sing-box-subscribe)
- [nix-darwin](https://github.com/nix-darwin/nix-darwin)

## Acknowledgements

I gratefully acknowledge chezmoi's powerful templating and field-level encryption capabilities, which make it possible to securely manage and publicize these configurations.

- [KeePassXC](https://keepassxc.org/)
- [chezmoi](https://www.chezmoi.io/)
