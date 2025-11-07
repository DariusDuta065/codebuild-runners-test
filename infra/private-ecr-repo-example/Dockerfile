FROM amazoncorretto:21-alpine3.22

ENV JAVA_VERSION=21 \
    JAVA_DISTRIBUTION="corretto" \
    JAVA_HOME="/usr/lib/jvm/java-21-amazon-corretto/" \
    LANG=C.UTF-8

RUN apk update && \
    apk add --no-cache ca-certificates unzip && \
    echo 'public class Main { public static void main(String[] args) { System.out.println("Java code is running fine!"); } }' > Main.java && \
    javac Main.java && \
    java Main && \
    rm -rf Main.java Main.class && \
    rm -rf /var/cache/apk/* && \
    rm -rf /tmp/*

RUN addgroup -g 1000 appuser && \
    adduser -D -u 1000 -G appuser appuser

USER appuser

WORKDIR /home/appuser
