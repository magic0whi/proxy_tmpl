os_name := os()

repo_home := justfile_directory()
sub_home := `zoxide query sing-box-subscribe || echo "~/sync_work/sing-box-subscribe"`

nixos_configs_home := `zoxide query nixos_configs_flake || echo "~/nixos_configs_flake"`
nixos_configs_secrets := nixos_configs_home + "/secrets"
pgp_key_id := "30973F79B17F9ED3!"

# List all the just commands
default:
  @just --list

# Enter the common development shell
dev:
  nix develop github:magic0whi/dev_flake#python -c zsh

# Helper: Generate SSH key from PGP secret subkey
[private]
get-ssh-key key_id=pgp_key_id:
  #!/usr/bin/env bash
  set -eufo pipefail

  TMP_KEY=$(mktemp)
  # Ensure the temp file is securely deleted when the script finishes or crashes
  trap 'rm -f "$TMP_KEY"' EXIT

  # Export the key directly to the temp file
  gpg --quiet --batch --yes -ao "$TMP_KEY" --export-secret-subkeys "{{key_id}}"

  # Pass the file path, a newline, and the index '1' into pgp2ssh
  printf "%s\n1\n" "$TMP_KEY" \
    | pgp2ssh 2>&1 \
    | awk 'BEGIN { A=0; } /BEGIN OPENSSH PRIVATE KEY/ { A=1; } { if (A==1) { print; } }'

# Update sing-box configurations
update-configs:
  #!/usr/bin/env bash
  set -eufo pipefail

  # If not in a Nix shell, restart this recipe inside the Nix shell
  if [ -z "${IN_NIX_SHELL:-}" ]; then
    echo "Not in Nix shell. Restarting inside Nix shell..."
    exec nix develop github:magic0whi/dev_flake#python -c just update-configs
  fi

  REPO="{{repo_home}}"
  SUB="{{sub_home}}"

  echo "Updating sing-box configs..."
  pushd "$REPO" > /dev/null

  PROXY_TMP=$(mktemp --directory)
  # SECURITY: Ensure temp dir is deleted on exit, even if the script fails
  trap 'rm -rf "$PROXY_TMP"' EXIT

  gpg --quiet --batch --yes --output "$PROXY_TMP/tmp.key" --decrypt proxy_kdbx.key.asc
  sed -r "s,REPLACE,$PROXY_TMP/tmp.key," chezmoi.toml > "$PROXY_TMP/chezmoi.toml"

  chezmoi -c "$PROXY_TMP/chezmoi.toml" execute-template < providers.json.tmpl > "$SUB/providers.json"
  chezmoi --override-data '{"isMobile": true}' -c "$PROXY_TMP/chezmoi.toml" execute-template < sb_client.json.tmpl > "$SUB/config_template/0mobile.json"
  chezmoi --override-data '{"isDarwin": true}' -c "$PROXY_TMP/chezmoi.toml" execute-template < sb_client.json.tmpl > "$SUB/config_template/1darwin.json"
  chezmoi --override-data '{"isLinux": true}' -c "$PROXY_TMP/chezmoi.toml" execute-template < sb_client.json.tmpl > "$SUB/config_template/2linux.json"
  chezmoi --override-data '{"isLinux": true, "isMobile": true}' -c "$PROXY_TMP/chezmoi.toml" execute-template < sb_client.json.tmpl > "$SUB/config_template/2rooted.json"
  chezmoi -c "$PROXY_TMP/chezmoi.toml" execute-template < clash.yaml.tmpl > "$SUB/clash.yaml"

  popd > /dev/null
  pushd "$SUB" > /dev/null

  python main.py --template_index 0 && mv config.json mobile.json
  python main.py --template_index 1 && mv config.json darwin.json
  python main.py --template_index 2 && mv config.json linux.json
  python main.py --template_index 3 && mv config.json rooted.json

  popd > /dev/null
  echo "Configurations successfully updated."

# Rebuild System Configuration based on current OS (Proteus-MBP14M4P/Proteus-NUC)
rebuild-sys nixos_recipe="proteus-nuc":
  #!/usr/bin/env bash
  set -eufo pipefail

  SUB="{{sub_home}}"
  SECRETS="{{nixos_configs_secrets}}"
  NIXOS_HOME="{{nixos_configs_home}}"
  SSH_KEY=$(just get-ssh-key)

  echo "Rebuilding system configuration..."
  pushd "$SECRETS" > /dev/null

  rm -f sb_client_darwin.json.age
  cat "$SUB/darwin.json" | agenix -e sb_client_darwin.json.age -i <(printf "%s\n" "$SSH_KEY")

  rm -f sb_client_linux.json.age
  cat "$SUB/linux.json" | agenix -e sb_client_linux.json.age -i <(printf "%s\n" "$SSH_KEY")

  pushd "$NIXOS_HOME" > /dev/null
  if [ "{{os_name}}" = "macos" ]; then
    just proteus-mbp
    sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder
    sudo launchctl stop io.nekohasekai.sing-box && sleep 2
    sudo launchctl start io.nekohasekai.sing-box
  else
    just {{nixos_recipe}}
    sudo systemctl restart sing-box.service
  fi
  popd > /dev/null
  popd > /dev/null

# Rebuild and deploy the NixOS Server
deploy-server:
  #!/usr/bin/env bash
  set -eufo pipefail

  if [ "{{os_name}}" = "macos" ]; then
    echo "Warning: You are running deploy on MacOS. It is recommended to run this on a Linux shell since it doesn't build non-darwin binaries."
  fi

  REPO="{{repo_home}}"
  NIXOS_HOME="{{nixos_configs_home}}"
  SECRETS="{{nixos_configs_secrets}}"
  SSH_KEY=$(just get-ssh-key)

  echo "Deploying to NixOS Server..."
  pushd "$REPO" > /dev/null

  PROXY_TMP=$(mktemp --directory)
  trap 'rm -rf "$PROXY_TMP"' EXIT

  gpg --quiet --batch --yes --output "$PROXY_TMP/tmp.key" --decrypt proxy_kdbx.key.asc
  sed -r "s,REPLACE,$PROXY_TMP/tmp.key," chezmoi.toml > "$PROXY_TMP/chezmoi.toml"
  chezmoi -c "$PROXY_TMP/chezmoi.toml" execute-template < sb_Proteus-NixOS-1.json.tmpl > "$PROXY_TMP/sb_Proteus-NixOS-1.json"

  popd > /dev/null
  pushd "$SECRETS" > /dev/null

  rm -f sb_Proteus-NixOS-1.json.age
  cat "$PROXY_TMP/sb_Proteus-NixOS-1.json" | agenix -e sb_Proteus-NixOS-1.json.age -i <(printf "%s\n" "$SSH_KEY")

  # Run the deployment target
  deploy --skip-checks --targets "$NIXOS_HOME#Proteus-NixOS-"{0..5} -- --show-trace --verbose

  popd > /dev/null
