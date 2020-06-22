FROM debian:buster-slim AS builder

RUN apt-get -y update \
		&& apt-get install -y \
		libmicrohttpd-dev \
		libjansson-dev \
		libssl-dev \
		libsofia-sip-ua-dev \
		libglib2.0-dev \
		libopus-dev \
		libogg-dev \
		libavutil-dev \
		libavcodec-dev \
		libavformat-dev \
		libini-config-dev \
		libcollection-dev \
		pkg-config \
		libconfig-dev \
		gengetopt \
		libtool \
		automake \
		wget \
		sudo \
		make \
		git \
		cmake \
		graphviz \
		build-essential \
		flex \
		bison
		#&& rm -rf /var/lib/apt/lists/*

ARG DOXYGEN_V=1.8.18
RUN cd /tmp \
		&& git clone https://github.com/doxygen/doxygen.git \
    && cd doxygen \
    && mkdir build \
    && cd build \
    && cmake -G "Unix Makefiles" .. \
    && make \
    && make install

RUN cd /tmp && \
	wget https://github.com/cisco/libsrtp/archive/v2.3.0.tar.gz && \
	tar xfv v2.3.0.tar.gz && \
	cd libsrtp-2.3.0 && \
	./configure --prefix=/usr --enable-openssl && \
	make shared_library && \
	make install


ARG LIBNICE_V=0.1.17
RUN cd /tmp \
  && wget --no-check-certificate https://libnice.freedesktop.org/releases/libnice-${LIBNICE_V}.tar.gz \
  && tar xvf libnice-${LIBNICE_V}.tar.gz \
  && cd libnice-${LIBNICE_V} \
  && ./configure --prefix=/usr && make && sudo make install \
  && cd .. \
  && rm -rf libnice-${LIBNICE_V}


ARG JANUS_VERSION=0.10.3
RUN wget -O janus-gateway.tar.gz https://github.com/meetecho/janus-gateway/archive/v${JANUS_VERSION}.tar.gz \
  && mkdir janus-gateway \
  && tar xvf janus-gateway.tar.gz -C janus-gateway --strip-components 1 \
	&& cd janus-gateway \
  && sh autogen.sh \
  && ./configure --prefix=/usr/local --enable-post-processing \
  && make \
  && make install \
  && make configs \
  && cd ../ \
  && rm -rf janus-gateway.tar.gz

FROM debian:buster-slim

ARG BUILD_DATE="undefined"
ARG GIT_BRANCH="undefined"
ARG GIT_COMMIT="undefined"
ARG VERSION="undefined"

LABEL build_date=${BUILD_DATE}
LABEL git_branch=${GIT_BRANCH}
LABEL git_commit=${GIT_COMMIT}
LABEL version=${VERSION}

RUN apt-get -y update && \
	apt-get install -y \
		libmicrohttpd12 \
		libjansson4 \
		libssl1.1 \
		libsofia-sip-ua0 \
		libglib2.0-0 \
		libopus0 \
		libogg0 \
		libcurl4 \
		liblua5.3-0 \
		libconfig9 \
		libusrsctp1 \
		libwebsockets8 \
		libnanomsg5 \
		librabbitmq4 && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/lib/libsrtp2.so.1 /usr/lib/libsrtp2.so.1
RUN ln -s /usr/lib/libsrtp2.so.1 /usr/lib/libsrtp2.so

COPY --from=builder /usr/lib/libnice.la /usr/lib/libnice.la
COPY --from=builder /usr/lib/libnice.so.10.10.0 /usr/lib/libnice.so.10.10.0
RUN ln -s /usr/lib/libnice.so.10.10.0 /usr/lib/libnice.so.10
RUN ln -s /usr/lib/libnice.so.10.10.0 /usr/lib/libnice.so

COPY --from=builder /usr/local/bin/janus /usr/local/bin/janus
COPY --from=builder /usr/local/bin/janus-cfgconv /usr/local/bin/janus-cfgconv
COPY --from=builder /usr/local/etc/janus /usr/local/etc/janus
COPY --from=builder /usr/local/lib/janus /usr/local/lib/janus/
COPY --from=builder /usr/local/share/janus /usr/local/share/janus
COPY --from=builder /janus-gateway/html  /opt/janus/src/janus-gateway/html

ENTRYPOINT ["/usr/local/bin/janus"]
CMD ["--stun-server=stun.l.google.com:19302"]
