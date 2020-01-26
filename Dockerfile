FROM openjdk:11

ENV SONAR_VERSION=7.9 
ENV SONARQUBE_HOME=/opt/sonarqube
    # Database configuration
    # Defaults to using H2
    # DEPRECATED. Use -v sonar.jdbc.username=... instead
    # Drop these in the next release, also in the run script
ENV    SONARQUBE_JDBC_USERNAME=sonar
ENV    SONARQUBE_JDBC_PASSWORD=sonar
ENV    SONARQUBE_JDBC_URL=

# Http port
EXPOSE 9000

USER root

RUN groupadd -r sonarqube && useradd -r -g sonarqube sonarqube

# grab gosu for easy step-down from root
RUN set -x \
    && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/1.10/gosu-$(dpkg --print-architecture)" \
    && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/1.10/gosu-$(dpkg --print-architecture).asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && for server in $(shuf -e ha.pool.sks-keyservers.net \
                            hkp://p80.pool.sks-keyservers.net:80 \
                            keyserver.ubuntu.com \
                            hkp://keyserver.ubuntu.com:80 \
                            pgp.mit.edu) ; do \
        gpg --batch --keyserver "$server" --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 && break || : ; \
    done \
    && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
    && rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true

RUN set -x \
    # pub   2048R/D26468DE 2015-05-25
    #       Key fingerprint = F118 2E81 C792 9289 21DB  CAB4 CFCA 4A29 D264 68DE
    # uid                  sonarsource_deployer (Sonarsource Deployer) <infra@sonarsource.com>
    # sub   2048R/06855C1D 2015-05-25
    && for server in $(shuf -e ha.pool.sks-keyservers.net \
                            hkp://p80.pool.sks-keyservers.net:80 \
                            keyserver.ubuntu.com \
                            hkp://keyserver.ubuntu.com:80 \
                            pgp.mit.edu) ; do \
        gpg --batch --keyserver "$server" --recv-keys F1182E81C792928921DBCAB4CFCA4A29D26468DE && break || : ; \
    done \
    && cd /opt \
    && curl -o sonarqube.zip -fSL https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-$SONAR_VERSION.zip \
    && curl -o sonarqube.zip.asc -fSL https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-$SONAR_VERSION.zip.asc \
    && gpg --batch --verify sonarqube.zip.asc sonarqube.zip \
    && unzip sonarqube.zip \
    && mv sonarqube-$SONAR_VERSION sonarqube \
    && chown -R sonarqube:sonarqube sonarqube \
    && rm sonarqube.zip* \
    && rm -rf $SONARQUBE_HOME/bin/*

RUN set -x && mkdir -p "${SONARQUBE_HOME}/extensions/plugins"


VOLUME ["$SONARQUBE_HOME}/data", "${SONARQUBE_HOME}/temp", "${SONARQUBE_HOME}/logs", "${SONARQUBE_HOME}/extensions"]

RUN set -x && chown -R sonarqube:sonarqube "${SONARQUBE_HOME}/data"
RUN set -x && chown -R sonarqube:sonarqube "${SONARQUBE_HOME}/temp"
RUN set -x && chown -R sonarqube:sonarqube "${SONARQUBE_HOME}/logs"
RUN set -x && chown -R sonarqube:sonarqube "${SONARQUBE_HOME}/extensions"

WORKDIR $SONARQUBE_HOME
USER sonarqube
COPY README.txt ${SONARQUBE_HOME}/temp
COPY --chown=sonarqube:sonarqube com.checkmarx.sonar.cxplugin-8.90.0.jar ${SONARQUBE_HOME}/extensions/plugins
COPY run.sh $SONARQUBE_HOME/bin/
ENTRYPOINT ["./bin/run.sh"]