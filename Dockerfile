FROM maven:3-jdk-8

# This will supress any download for dependencies and plugins or upload messages which would clutter the console log.
# `showDateTime` will show the passed time in milliseconds. You need to specify `--batch-mode` to make this work.
ENV MAVEN_OPTS="-Dmaven.repo.local=.m2/repository -Dorg.slf4j.simpleLogger.log.org.apache.maven.cli.transfer.Slf4jMavenTransferListener=WARN -Dorg.slf4j.simpleLogger.showDateTime=true -Djava.awt.headless=true"
# As of Maven 3.3.0 instead of this you may define these options in `.mvn/maven.config` so the same config is used
# when running from the command line.
# `installAtEnd` and `deployAtEnd`are only effective with recent version of the corresponding plugins.
ENV MAVEN_CLI_OPTS="--batch-mode --errors --fail-at-end --show-version -DinstallAtEnd=true -DdeployAtEnd=true"
ARG APP_CONFIG=docker/conf/app.config.sample

RUN mkdir -p /ors-core/build

COPY .git /ors-core/.git
COPY openrouteservice /ors-core/openrouteservice
COPY $APP_CONFIG /ors-core/openrouteservice/WebContent/WEB-INF/app.config

WORKDIR /ors-core

# Build and install openrouteservice
RUN mvn -f ./openrouteservice/pom.xml package -DskipTests 

ARG ORS_VER="$(mvn -f ./openrouteservice/pom.xml -q -Dexec.executable="echo" -Dexec.args='${project.version}' --non-recursive exec:exec)"

# TOMCAT

RUN apt-get update && apt-get -y install openjdk-8-jdk wget nano maven

RUN mkdir /usr/local/tomcat

RUN wget https://archive.apache.org/dist/tomcat/tomcat-8/v8.0.32/bin/apache-tomcat-8.0.32.tar.gz -O /tmp/tomcat.tar.gz

RUN cd /tmp && tar xvfz tomcat.tar.gz
RUN cp -R /tmp/apache-tomcat-8.0.32/* /usr/local/tomcat/

#RUN touch /usr/local/tomcat/bin/setenv.sh
#RUN echo "CATALINA_OPTS=\"$CATALINA_OPTS\"" >> /usr/local/tomcat/bin/setenv.sh
#RUN echo "JAVA_OPTS=\"$JAVA_OPTS\"" >> /usr/local/tomcat/bin/setenv.sh

RUN cp /ors-core/openrouteservice/target/openrouteservice-$ORS_VER.war /usr/local/tomcat/webapps/ors.war

EXPOSE 8080
CMD /usr/local/tomcat/bin/catalina.sh run
