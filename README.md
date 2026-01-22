## MacOS

```bash
nix develop ~/sync_work/dev_flake#python
```

```bash
pushd ~/sync_work/proxy_tmpl \
  && export TMP=$(mktemp --directory) \
  && gpg --quiet --batch --yes --output $TMP/tmp.key --decrypt proxy_kdbx.key.asc \
  && sed -r "s,REPLACE,$TMP/tmp.key," chezmoi.toml > $TMP/chezmoi.toml \
  && nix run --offline nixpkgs#chezmoi -- -c $TMP/chezmoi.toml execute-template < providers.json.tmpl > ~/sync_work/sing-box-subscribe/providers.json \
  && nix run --offline nixpkgs#chezmoi -- -c $TMP/chezmoi.toml execute-template < config.json.tmpl > ~/sync_work/sing-box-subscribe/config_template/config.json \
  && rm -r $TMP && unset TMP \
&& popd \
&& pushd ~/sync_work/sing-box-subscribe \
  && python main.py --template_index 0 \
  && sudo cp config.json /run/agenix/sb_client.json \
&& popd \
&& sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder \
&& sudo launchctl stop io.nekohasekai.sing-box && sleep 2 \
&& sudo launchctl start io.nekohasekai.sing-box
```

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
&& just proteus-mbp && popd \
&& sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder \
&& sudo launchctl stop io.nekohasekai.sing-box && sleep 2 \
&& sudo launchctl start io.nekohasekai.sing-box
```
