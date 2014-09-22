FROM ubuntu:14.04
ENV ARCH amd64
ENV DIST trusty
ENV MIRROR ftp://ftp.ubuntu.com

RUN apt-get -q update
RUN apt-get -qy install dnsmasq wget iptables nginx apt-cacher
ADD apt-cacher.conf /etc/apt-cacher/apt-cacher.conf
ADD apt-cacher /etc/default/apt-cacher 
#RUN wget --no-check-certificate https://raw.github.com/jpetazzo/pipework/master/pipework
ADD pipework /pipework
RUN chmod +x pipework
ADD logs.sh /logs.sh
RUN chmod +x /logs.sh
RUN mkdir /tftp
#WORKDIR /usr/share/nginx/html
#RUN wget --no-check-certificate https://raw.githubusercontent.com/realbazso/docker-ubuntu-pxe/master/ks.cfg
#ADD ks.cfg /usr/share/nginx/html/ks.cfg
WORKDIR /tftp

RUN wget $MIRROR/ubuntu/dists/$DIST/main/installer-$ARCH/current/images/netboot/ubuntu-installer/$ARCH/linux
RUN wget $MIRROR/ubuntu/dists/$DIST/main/installer-$ARCH/current/images/netboot/ubuntu-installer/$ARCH/initrd.gz
RUN wget $MIRROR/ubuntu/dists/$DIST/main/installer-$ARCH/current/images/netboot/ubuntu-installer/$ARCH/pxelinux.0

RUN mkdir pxelinux.cfg
RUN printf "DEFAULT linux\nKERNEL linux biosdevname=0\nAPPEND http_proxy="http://10.42.42.4:3142" initrd=initrd.gz ks=http://10.42.42.4/ks.cfg\n" >pxelinux.cfg/default
CMD \
    echo Setting up iptables... &&\
    iptables -t nat -A POSTROUTING -j MASQUERADE &&\
    echo Waiting for pipework to give us the eth1 interface... &&\
    /pipework --wait &&\
    /etc/init.d/nginx start &&\
    /etc/init.d/apt-cacher start &&\
    /logs.sh /var/log/apt-cacher &&\
    echo Starting DHCP+TFTP server...&&\
    dnsmasq --interface=eth1 \
    	    --dhcp-range=10.42.42.100,10.42.42.200,255.255.255.0,1h \
	    --dhcp-boot=pxelinux.0,pxeserver,10.42.42.4 \
	    --pxe-service=x86PC,"Install Linux",pxelinux \
	    --enable-tftp --tftp-root=/tftp/ --no-daemon
# Let's be honest: I don't know if the --pxe-service option is necessary.
# The iPXE loader in QEMU boots without it.  But I know how some PXE ROMs
# can be picky, so I decided to leave it, since it shouldn't hurt.
