FROM alpine:latest
ARG http_proxy
ARG https_proxy
ARG no_proxy
ARG app_path
ARG app_name
ARG app_ver
ENV APP ${APP}
ENV APP_VERSION ${app_ver}

VOLUME /root/.aws
VOLUME /$app_path/data

WORKDIR /$app_path

RUN apk -v --no-cache add curl jq gawk gettext
RUN apk add --no-cache \
    bash \
    rsync \
    openssh-client \
    python \
    py-pip && \
    pip install awscli awscli_plugin_endpoint --upgrade --user && \
    mv /root/.local/bin/* /usr/local/bin && \
    apk -v --purge del py-pip

CMD ["sleep","600"]
