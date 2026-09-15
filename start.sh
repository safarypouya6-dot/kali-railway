#!/bin/bash
set -e

: "${USERNAME:=kali}"
: "${TCP_PORT:=2222}"

if [ -z "${PASSWORD:-}" ]; then
  echo "ERROR: PASSWORD environment variable is required."
  exit 1
fi

if ! id "$USERNAME" >/dev/null 2>&1; then
  useradd -m -s /bin/bash "$USERNAME"
fi

echo "${USERNAME}:${PASSWORD}" | chpasswd

mkdir -p /run/sshd
ssh-keygen -A

# Remove all existing Port/ListenAddress directives
sed -i -E '/^[[:space:]]*#?[[:space:]]*Port[[:space:]]+/d' /etc/ssh/sshd_config
sed -i -E '/^[[:space:]]*#?[[:space:]]*ListenAddress[[:space:]]+/d' /etc/ssh/sshd_config
printf '\nPort %s\nListenAddress 0.0.0.0\n' "$TCP_PORT" >> /etc/ssh/sshd_config

if grep -qE '^[[:space:]]*#?[[:space:]]*PasswordAuthentication[[:space:]]+' /etc/ssh/sshd_config; then
  sed -i -E 's/^[[:space:]]*#?[[:space:]]*PasswordAuthentication[[:space:]].*/PasswordAuthentication yes/' /etc/ssh/sshd_config
else
  echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
fi

if grep -qE '^[[:space:]]*#?[[:space:]]*PermitRootLogin[[:space:]]+' /etc/ssh/sshd_config; then
  sed -i -E 's/^[[:space:]]*#?[[:space:]]*PermitRootLogin[[:space:]].*/PermitRootLogin no/' /etc/ssh/sshd_config
else
  echo "PermitRootLogin no" >> /etc/ssh/sshd_config
fi

cat >> /etc/ssh/sshd_config <<'EOF'
TCPKeepAlive yes
ClientAliveInterval 60
ClientAliveCountMax 3
MaxSessions 100
MaxStartups 100:30:200
EOF

/usr/sbin/sshd -t
printf 'SSH ready on 0.0.0.0:%s\n' "$TCP_PORT"
exec /usr/sbin/sshd -D -e
