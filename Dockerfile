FROM alpine:3.20.1

MAINTAINER devops@hmsk.com.cn

ENV ALPINE_VERSION=3.20 \
    JAVA_PACKAGE=server-jre \
    JAVA_VERSION_MAJOR=8 \
    JAVA_VERSION_MINOR=411 \
    GLIBC_VERSION=2.34-r0 \
    JAVA_PACKAGE_VARIANT=nashorn \
    JAVA_JCE=unlimited \
    JAVA_HOME=/usr/local/jdk/ \
    PATH=/usr/local/jdk/bin:/usr/local/jdk/jre/bin:${PATH} \
    GLIBC_REPO=https://github.com/sgerrand/alpine-pkg-glibc \
    TZ=Asia/Shanghai \
    LANG=en_US.UTF-8

ADD ${JAVA_PACKAGE}-${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-linux-x64.tar.gz /usr/local/

RUN set -ex && \
    sed -i "s/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g" /etc/apk/repositories && \
    echo "https://mirrors.aliyun.com/alpine/v${ALPINE_VERSION}/main" >> /etc/apk/repositories && \
    cat /etc/apk/repositories &&\
    apk -U upgrade && \
    apk add --no-cache tzdata libstdc++ curl ca-certificates bash java-cacerts openssh-client lsof vim tree busybox-extras && \
    ln -sTf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/shanghai" >> /etc/timezone && \
    wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub && \
    for pkg in glibc-${GLIBC_VERSION} glibc-bin-${GLIBC_VERSION} glibc-i18n-${GLIBC_VERSION}; do curl -sSL ${GLIBC_REPO}/releases/download/${GLIBC_VERSION}/${pkg}.apk -o /tmp/${pkg}.apk; done && \
    apk add --allow-untrusted --force-overwrite /tmp/*.apk && \
    rm -v /tmp/*.apk && \
    ( /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 ${LANG} || true ) && \
    echo "export LANG=${LANG}" > /etc/profile.d/locale.sh && \
    /usr/glibc-compat/sbin/ldconfig /lib /usr/glibc-compat/lib && \
    ln -s /usr/local/jdk1.${JAVA_VERSION_MAJOR}.0_${JAVA_VERSION_MINOR} /usr/local/jdk && \
    if [ "${JAVA_JCE}" == "unlimited" ]; then echo "Installing Unlimited JCE policy" && \
      curl -L -C - -b "oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jce/${JAVA_VERSION_MAJOR}/jce_policy-${JAVA_VERSION_MAJOR}.zip -o /tmp/jce_policy-${JAVA_VERSION_MAJOR}.zip && \
      cd /tmp && unzip /tmp/jce_policy-${JAVA_VERSION_MAJOR}.zip && \
      cp -v /tmp/UnlimitedJCEPolicyJDK8/*.jar ${JAVA_HOME}/jre/lib/security/; \
    fi && \
    sed -i s/#networkaddress.cache.ttl=-1/networkaddress.cache.ttl=10/ ${JAVA_HOME}/jre/lib/security/java.security && \
    rm -rf /tmp/* /var/cache/apk/*  && \
    ln -sf /etc/ssl/certs/java/cacerts ${JAVA_HOME}/jre/lib/security/cacerts && \
    echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf

CMD ["/bin/bash"]
