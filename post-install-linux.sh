#!/bin/sh
set -e

storedir=/nix/store
localstatedir=/nix/var/nix
nix=/opt/nix-multiuser/nix

# Setup build users
if ! getent group "nixbld" >/dev/null; then
  groupadd -r "nixbld"
fi

for i in $(seq 32); do
  if ! getent passwd "nixbld$i" >/dev/null; then
    useradd -r -g "nixbld" -G "nixbld" -d /var/empty \
      -s /sbin/nologin \
      -c "Nix build user $i" "nixbld$i"
  fi
done

# Copy over the Nix store from the bootstrap store
mkdir -p -m 1775 "$storedir"
chgrp "nixbld" "$storedir"
# FIXME: make this copy somehow 100% idempotent
cp -r /opt/nix-multiuser/bootstrap-store/* "$storedir"

# FIXME: fpm has a bug where it fails to package directories
# that lack write permission. So remove them here.
chmod -R a-w "$storedir"
# Restore modification timestamps for good measure, because Nix
# gets really unhappy if they're not canonical. FIXME: necessary?
find "$storedir" -exec touch -c -h -d @1 '{}' \;

# Create Nix state directories
mkdir -p -m 1777 "$localstatedir/profiles/per-user"
mkdir -p -m 1777 "$localstatedir/gcroots/per-user"
mkdir -p "$localstatedir/channel-cache"

# Initialize the store.
$nix/bin/nix-store --init
$nix/bin/nix-store --load-db < /opt/nix-multiuser/reginfo

# Make the Debian/RPM-installed Nix a gcroot.
ln -sfn /opt/nix-multiuser/nix "$localstatedir/gcroots/nix-multiuser"
