ARG BUILD_FROM
FROM $BUILD_FROM

ENV LANG C.UTF-8

RUN apk add --no-cache nginx python3 
RUN wget -qO- https://github.com/incub77/sevicontrol/archive/master.tar.gz | tar -xzf - \
	&& mv sevicontrol-master /home/sevicontrol \
    && mv /home/sevicontrol/provisioning/etc/nginx/nginx.conf /etc/nginx/ \
	&& sed -i 's/unix:\/run\/sevi-control\/socket/localhost:8080/' /etc/nginx/nginx.conf \
	&& python3 -m ensurepip \
    && pip3 install --no-cache --upgrade pip PySerial flask flask-cors pyyaml requests gunicorn paho-mqtt\
    && addgroup -S sevictl \
    && adduser -S -H -s /sbin/nologin -G sevictl sevictl \
    && printf "/home/sevicontrol true sevictl:sevictl - -" > /etc/fix-attrs.d/01-sevicontrol-dir \
    && printf "/dev/ttyUSB0 false root 0666 -" > /etc/fix-attrs.d/02-ttyusb0 \
    && printf "/dev/ttyUSB1 false root 0666 -" > /etc/fix-attrs.d/03-ttyusb1 \
    && printf "/dev/ttyUSB2 false root 0666 -" > /etc/fix-attrs.d/04-ttyusb2 \
    && printf "/dev/ttyUSB3 false root 0666 -" > /etc/fix-attrs.d/05-ttyusb3

VOLUME ["/run"]

WORKDIR /etc/services.d/nginx
RUN printf "#!/usr/bin/execlineb -P\nnginx -g \"daemon off;\"" > run

WORKDIR /etc/services.d/sevicontrol
#RUN printf "#!/usr/bin/execlineb -P\ncd /home/sevicontrol\ngunicorn -u sevictl -g sevictl --bind localhost:8080 SeviControl:app" > run
RUN printf "#!/usr/bin/execlineb -P\ncd /home/sevicontrol\ngunicorn --bind localhost:8080 SeviControl:app" > run

WORKDIR /home/sevicontrol

COPY json2yaml.py .
COPY 10-config_convert /etc/cont-init.d/

#ENTRYPOINT ["/init"]
