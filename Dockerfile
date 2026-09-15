FROM kalilinux/kali-rolling

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y openssh-server && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /run/sshd

COPY start.sh /start.sh
RUN chmod +x /start.sh

# Railway supplies the actual public port through $PORT at runtime.
EXPOSE 22

CMD ["/start.sh"]
