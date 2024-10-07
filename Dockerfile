FROM opensuse/tumbleweed:latest AS app

RUN zypper update --no-confirm && \
    zypper install --no-confirm wget make autoconf gcc-c++ awk openssl-devel libicu-devel

WORKDIR /usr/src

ARG ERLANG_OTP_VERSION
RUN wget https://github.com/erlang/otp/releases/download/OTP-$ERLANG_OTP_VERSION/otp_src_$ERLANG_OTP_VERSION.tar.gz && \
    tar -xvf otp_src_$ERLANG_OTP_VERSION.tar.gz && \
    cd otp_src_$ERLANG_OTP_VERSION && \
    ./configure --without-termcap --without-wx --without-javac --without-odbc && \
    make && \
    make install

ARG COUCHDB_VERSION
ARG FAUXTON_VERSION
RUN wget https://dlcdn.apache.org/couchdb/source/$COUCHDB_VERSION/apache-couchdb-$COUCHDB_VERSION.tar.gz && \
    tar -xvf apache-couchdb-$COUCHDB_VERSION.tar.gz && \
    cd apache-couchdb-$COUCHDB_VERSION && \
    ./configure --js-engine=quickjs --disable-spidermonkey && \
    rm -Rf src/fauxton/* && \
    rm -Rf src/fauxton/.* && \
    curl -L https://github.com/apache/couchdb-fauxton/archive/refs/tags/v$FAUXTON_VERSION.tar.gz | tar --directory src/fauxton --strip-components 1 -zxvf - && \
    make && \
    make install && \
    tar --create --file=/tmp/couchdb.tar.xz --directory=/usr/src/apache-couchdb-$COUCHDB_VERSION/rel/couchdb --xz --verbose --utc .

ARG COUCHDB_VERSION
ARG RELEASE_VERSION
ARG MEND_EMAIL
ARG MEND_ORGANIZATION
ARG MEND_URL
ARG MEND_USER_KEY
RUN curl -L https://downloads.mend.io/cli/linux_amd64/mend -o /usr/bin/mend && chmod +x /usr/bin/mend && \
    /usr/bin/mend dep --dir /usr/src/apache-couchdb-$COUCHDB_VERSION --extended -s "OpenScape UC Portfolio//OSEM third party applications//couchdb-osem-sourcecode - $COUCHDB_VERSION-r$RELEASE_VERSION" -u

FROM opensuse/tumbleweed:latest AS base

COPY --from=app /tmp/couchdb.tar.xz /tmp/couchdb.tar.xz

RUN mkdir -p /opt/couchdb && \
    groupadd -g 5984 -r couchdb && useradd -u 5984 -d /opt/couchdb -g couchdb couchdb && \
    tar --directory /opt/couchdb -xvf /tmp/couchdb.tar.xz && \
    chown -R couchdb:couchdb /opt/couchdb && \
    zypper update --no-confirm && \
    rpm -e --allmatches $(rpm -qa --qf "%{NAME}\n" | grep -v -E "bash|coreutils|filesystem|glibc$|libacl1|libattr1|libcap2|libgcc_s1|libgmp|libncurses|libpcre1|libreadline|libselinux|libstdc\+\+|openSUSE-release|system-user-root|terminfo-base|libpcre2|sed|libz1|libjitterentropy3|libopenssl3|crypto-policies|libicu75|timezone") && \
    rm -Rf /etc/zypp && \
    rm -Rf /usr/lib/zypp* && \
    rm -Rf /var/{cache,log,run}/* && \
    rm -Rf /var/lib/zypp && \
    rm -Rf /usr/lib/rpm && \
    rm -Rf /usr/lib/sysimage/rpm && \
    rm -Rf /usr/share/man && \
    rm -Rf /usr/local && \
    rm -Rf /srv/www && \
    rm -Rf /tmp/*

COPY --chown=couchdb:couchdb --chmod=740 vm.args /opt/couchdb/etc/vm.args
COPY --chown=couchdb:couchdb --chmod=740 docker-entrypoint.sh /opt/couchdb
RUN chown -R couchdb:couchdb /opt/couchdb

FROM scratch

COPY --from=base / /

ENTRYPOINT ["/opt/couchdb/docker-entrypoint.sh"]

ENV COUCHDB_ARGS_FILE="/opt/couchdb/etc/vm.args"

EXPOSE 5984 4369 9100

VOLUME /opt/couchdb/data

USER 5984:5984

CMD ["/opt/couchdb/bin/couchdb"]
