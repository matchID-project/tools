############################
# Artillery.io load tester #
############################
FROM artilleryio/artillery:2.0.21
ARG http_proxy
ARG https_proxy
ARG no_proxy
ARG npm_registry

# Base dir /app

WORKDIR /artillery

VOLUME /artillery/reports/

ENV PERF_MAX_USERS=40
CMD ["run -e development", "-o reports/report.json", "scenario.yml"]
