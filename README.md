## Common

```bash
nix develop ~/sync_work/dev_flake#python
```

## MacOS

Update sing-box's config

```bash
pushd ~/sync_work/proxy_tmpl \
  && export PROXY_TMP=$(mktemp --directory) \
  && gpg --quiet --batch --yes --output $PROXY_TMP/tmp.key --decrypt proxy_kdbx.key.asc \
  && sed -r "s,REPLACE,$PROXY_TMP/tmp.key," chezmoi.toml > $PROXY_TMP/chezmoi.toml \
  && chezmoi -c $PROXY_TMP/chezmoi.toml execute-template < providers.json.tmpl > ~/sync_work/sing-box-subscribe/providers.json \
  && chezmoi -c $PROXY_TMP/chezmoi.toml execute-template < sb_client.json.tmpl > ~/sync_work/sing-box-subscribe/config_template/1sb_client.json \
  && chezmoi -c $PROXY_TMP/chezmoi.toml execute-template < clash.yaml.tmpl > ~/sync_work/clash/clash.yaml \
  && rm -r $PROXY_TMP && unset PROXY_TMP \
&& popd \
&& pushd ~/sync_work/sing-box-subscribe \
  && python main.py --template_index 0 \
  && sudo cp config.json /run/agenix/sb_client.json \
&& popd \
&& sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder \
&& sudo launchctl stop io.nekohasekai.sing-box && sleep 2 \
&& sudo launchctl start io.nekohasekai.sing-box
```

Update nix-darwin's config

```bash
pushd ~/nixos_configs_flake/secrets \
  && (rm sb_client.json.age || true) \
  && cat ~/sync_work/sing-box-subscribe/config.json \
    | agenix -e sb_client.json.age -i <(pgp2ssh \
        <<< <(gpg -ao - --export-secret-subkeys 30973F79B17F9ED3\!) \
        <<< 1 2>&1 \
      | awk 'BEGIN { A=0; S=0; } \
        /BEGIN OPENSSH PRIVATE KEY/ { A=1; } \
        { if (A==1) { print; } }' \
    ) \
  && (rm sb_client_linux.json.age || true) \
  && cat ~/sync_work/sing-box-subscribe/config.json \
    | sed -r 's/("auto_redirect":\ )false(,?)/\1true\2/' \
    | agenix -e sb_client_linux.json.age -i <(pgp2ssh \
        <<< <(gpg -ao - --export-secret-subkeys 30973F79B17F9ED3\!) \
        <<< 1 2>&1 \
      | awk 'BEGIN { A=0; S=0; } \
        /BEGIN OPENSSH PRIVATE KEY/ { A=1; } \
        { if (A==1) { print; } }' \
    ) \
  && just proteus-mbp \
&& popd \
&& sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder \
&& sudo launchctl stop io.nekohasekai.sing-box && sleep 2 \
&& sudo launchctl start io.nekohasekai.sing-box
```

## NixOS

Update sing-box's config

```bash
pushd /srv/sync_work/proxy_tmpl \
  && export PROXY_TMP=$(mktemp --directory) \
  && gpg --quiet --batch --yes --output $PROXY_TMP/tmp.key --decrypt proxy_kdbx.key.asc \
  && sed -r "s,REPLACE,$PROXY_TMP/tmp.key," chezmoi.toml > $PROXY_TMP/chezmoi.toml \
  && chezmoi -c $PROXY_TMP/chezmoi.toml execute-template < providers.json.tmpl > /srv/sync_work/sing-box-subscribe/providers.json \
  && chezmoi -c $PROXY_TMP/chezmoi.toml execute-template < sb_client.json.tmpl > /srv/sync_work/sing-box-subscribe/config_template/1sb_client.json \
  && chezmoi -c $PROXY_TMP/chezmoi.toml execute-template < clash.yaml.tmpl > /srv/sync_work/clash/clash.yaml \
  && rm -r $PROXY_TMP && unset PROXY_TMP \
&& popd \
&& pushd /srv/sync_work/sing-box-subscribe \
  && python main.py --template_index 0 \
  && sudo cp config.json /run/agenix/sb_client.json \
&& popd \
&& sudo systemctl restart sing-box.service
```

Update NixOS config

```bash
pushd ~/nixos_configs_flake/secrets \
  && (rm sb_client.json.age || true) \
  && cat /srv/sync_work/sing-box-subscribe/config.json \
    | agenix -e sb_client.json.age -i <(pgp2ssh \
      <<< <(gpg -ao - --export-secret-subkeys 30973F79B17F9ED3\!) \
      <<< 1 2>&1 | awk 'BEGIN { A=0; S=0; } \
        /BEGIN OPENSSH PRIVATE KEY/ { A=1; } \
        { if (A==1) { print; } }' \
    ) \
  && (rm sb_client_linux.json.age || true) \
  && cat /srv/sync_work/sing-box-subscribe/config.json \
    | sed -r 's/("auto_redirect":\ )false(,?)/\1true\2/' \
    | agenix -e sb_client_linux.json.age -i <(pgp2ssh \
        <<< <(gpg -ao - --export-secret-subkeys 30973F79B17F9ED3\!) \
        <<< 1 2>&1 \
      | awk 'BEGIN { A=0; S=0; } \
        /BEGIN OPENSSH PRIVATE KEY/ { A=1; } \
        { if (A==1) { print; } }' \
    ) \
  && just proteus-nuc \
&& popd \
&& sudo systemctl restart sing-box.service
```

## NixOS Server

Run `deploy` on a Linux shell since it doesn't build non-darwin binaries on MacOS

```bash
pushd /srv/sync_work/proxy_tmpl \
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
    /home/proteus/nixos_configs_flake#Proteus-NUC \
    /home/proteus/nixos_configs_flake#Proteus-Desktop \
    /home/proteus/nixos_configs_flake#Proteus-NixOS-{1..6} \
  -- --show-trace --verbose \
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
