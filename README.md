# kali-railway

Want to try out Kali Linux or have a mini version of Kali Linux available at all times? This project deploys a Kali Linux rolling container on Railway with SSH access.

[![Deploy on Railway](https://railway.app/button.svg)](https://railway.app/template/E7oTLJ?referralCode=8sCkKx)

## Description

This project uses the official [Kali Linux rolling](https://hub.docker.com/r/kalilinux/kali-rolling/) image and runs an OpenSSH server so you can access the Kali command line remotely.

## Environment Variables

- **PORT:** The TCP port on which SSH listens. Railway provides this automatically.
- **USERNAME:** The Linux/SSH username.
- **PASSWORD:** The password for the SSH username.

### Railway

Set `USERNAME` and `PASSWORD` to your own strong values before deploying. The container creates the user at startup, configures SSH to listen on Railway's `PORT`, validates the SSH configuration, and starts `sshd` in the foreground.

After Railway provides a public TCP endpoint for the service, connect with:

```bash
ssh USERNAME@HOST -p PORT
```

Replace `USERNAME`, `HOST`, and `PORT` with the values from your Railway service.

## Using locally

```bash
# Build the image
docker build -t kali-railway .

# Run SSH locally on port 8080
docker run --rm \
  -e USERNAME=admin \
  -e PASSWORD='change-this-password' \
  -e PORT=8080 \
  -p 8080:8080 \
  kali-railway

# Connect from another terminal
ssh admin@127.0.0.1 -p 8080
```

> **Security:** Password authentication is enabled to keep the existing Railway variable-based login simple. Use a strong, unique password and do not expose or commit credentials to the repository.
