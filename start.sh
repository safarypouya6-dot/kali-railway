#!/bin/bash
set -e

: "${PORT:=22}"
: "${USERNAME:=kali}"

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

# Railway supplies the public service port through PORT.
if grep -qE '^[[:space:]]*#?[[:space:]]*Port[[:space:]]+' /etc/ssh/sshd_config; then
  sed -i -E "s/^[[:space:]]*#?[[:space:]]*Port[[:space:]].*/Port ${PORT}/" /etc/ssh/sshd_config
else
  echo "Port ${PORT}" >> /etc/ssh/sshd_config
fi

# Listen on all container interfaces so Railway's TCP proxy can reach SSH.
if grep -qE '^[[:space:]]*#?[[:space:]]*ListenAddress[[:space:]]+' /etc/ssh/sshd_config; then
  sed -i -E 's/^[[:space:]]*#?[[:space:]]*ListenAddress[[:space:]].*/ListenAddress 0.0.0.0/' /etc/ssh/sshd_config
else
  echo "ListenAddress 0.0.0.0" >> /etc/ssh/sshd_config
fi

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

# Keep normal SSH sessions reliable and allow many concurrent sessions.
cat >> /etc/ssh/sshd_config <<'EOF'
TCPKeepAlive yes
ClientAliveInterval 60
ClientAliveCountMax 3
MaxSessions 100
MaxStartups 100:30:200
EOF

# Validate configuration before starting the daemon.
/usr/sbin/sshd -t
exec /usr/sbin/sshd -D -e
