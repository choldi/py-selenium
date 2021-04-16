FROM arm64v8/python:3-alpine

ENV HOME=/root \
        DEBIAN_FRONTEND=noninteractive \
        LANG=en_US.UTF-8 \
        LANGUAGE=en_US.UTF-8 \
        LC_ALL=C.UTF-8 \
        DISPLAY=:0.0 \
        DISPLAY_WIDTH=1280 \
        DISPLAY_HEIGHT=1024

RUN apk update && apk add --no-cache \
        bash \
        fluxbox \
        git \
        net-tools \
        openssh-client \
        socat \
        supervisor \
        x11vnc \
        xterm \
        xvfb \
        chromium \
        chromium-chromedriver \
        wget \
        sed

RUN mkdir -p /etc/supervisor/conf.d \
        && wget https://raw.githubusercontent.com/psharkey/docker/master/rpi-novnc/supervisord.conf \
                -O /etc/supervisor/conf.d/supervisord.conf \
        && sed -i '/program\:novnc/,+3 d' /etc/supervisor/conf.d/supervisord.conf

RUN git clone https://github.com/kanaka/noVNC.git /root/noVNC \
        && git clone https://github.com/kanaka/websockify /root/noVNC/utils/websockify \
        && rm -rf /root/noVNC/.git \
        && rm -rf /root/noVNC/utils/websockify/.git \
        && apk del git wget sed

RUN pip install -U pip && pip install requests selenium && rm -rf $(pip cache dir)

RUN mkdir /start \
    && echo "xterm" >/start/init.sh
RUN chmod 0775 /start/init.sh

RUN mkdir -p /etc/supervisor/conf.d \
    &&  printf "%s\n%s\n\n%s\n%s\n%s\n\n" \
         "[supervisord]" \
         "nodaemon=true" \
         "[program:X11]" \
         "command=Xvfb :0 -screen 0 \"%(ENV_DISPLAY_WIDTH)s\"x\"%(ENV_DISPLAY_HEIGHT)s\"x24" \
         "autorestart=true" >/start/supervisord.conf \
    &&  printf "%s\n%s/n%s\n\n%s\n%s\n%s\n\n%s\n%s\n%s\n\n" \
         "[program:x11vnc]" \
         "command=/usr/bin/x11vnc" \
         "autorestart=true" \
         "[program:socat]" \
         "command=socat tcp-listen:6000,reuseaddr,fork unix:/tmp/.X11-unix/X0" \
         "autorestart=true" \
         "[program:fluxbox]" \
         "command=fluxbox" \
         "autorestart=true" >> /start/supervisord.conf


EXPOSE 8080 5900

CMD ["/usr/bin/supervisord", "-c", "/start/supervisord.conf"]

