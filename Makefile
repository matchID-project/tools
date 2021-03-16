##############################################
# WARNING : THIS FILE SHOULDN'T BE TOUCHED   #
#    FOR ENVIRONNEMENT CONFIGURATION         #
# CONFIGURABLE VARIABLES SHOULD BE OVERRIDED #
# IN THE 'artifacts' FILE, AS NOT COMMITTED  #
##############################################

SHELL=/bin/bash
include /etc/os-release

USE_TTY := $(shell test -t 1 && USE_TTY="-t")

OS_TYPE := $(shell cat /etc/os-release | grep -E '^NAME=' | sed 's/^.*debian.*$$/DEB/I;s/^.*ubuntu.*$$/DEB/I;s/^.*fedora.*$$/RPM/I;s/.*centos.*$$/RPM/I;')

#base paths
APP_GROUP=matchID
APP_GROUP_MAIL=matchid.project@gmail.com
APP_GROUP_DOMAIN=matchid.io
TOOLS = tools
TOOLS_PATH := $(shell pwd)
export CLOUD_CLI=aws
export STORAGE_CLI=rclone
APP_GROUP_PATH := $(shell dirname ${TOOLS_PATH})
export APP = ${CLOUD_CLI}
export APP_PATH = ${TOOLS_PATH}

GIT_ROOT=https://github.com/matchid-project
GIT_BRANCH := $(shell [ -f "/usr/bin/git" ] && git branch | grep '*' | awk '{print $$2}')
GIT_BRANCH_MASTER=master

export DOCKER_USERNAME=$(shell echo ${APP_GROUP} | tr '[:upper:]' '[:lower:]')
export DC_DIR=${APP_PATH}
export DC_FILE=${DC_DIR}/docker-compose
export DC_PREFIX := $(shell echo ${APP} | tr '[:upper:]' '[:lower:]')
export DC_NETWORK := $(shell echo ${APP} | tr '[:upper:]' '[:lower:]')
export DC_IMAGE_NAME = ${DC_PREFIX}
export DC_BUILD_ARGS = --pull --no-cache
export DC := docker-compose

# performance test confs
export PERF=${APP_PATH}/performance
export PERF_REPORTS=${PERF}/reports/
export PERF_NAMES=${PERF}/ids.csv

AWS=${TOOLS_PATH}/aws
SWIFT=${TOOLS_PATH}/swift
RCLONE=/usr/bin/rclone

DATAGOUV_API = https://www.data.gouv.fr/api/1/datasets
DATAGOUV_DATASET=service-public-fr-annuaire-de-l-administration-base-de-donnees-locales
DATAGOUV_CATALOG = ${DATA_DIR}/${DATAGOUV_DATASET}.datagouv.list
FILES_PATTERN=.*

DATA_DIR = ${PWD}/data
export FILE=${DATA_DIR}/test.bin

include ./artifacts.EC2.outscale
include ./artifacts.OS.ovh
include ./artifacts.SCW

STORAGE_BUCKET = $(shell echo ${APP_GROUP} | tr '[:upper:]' '[:lower:]')
#nb of chunk is limited to 1000 on SCW, so STORAGE_CHUNK_SIZE for > 500G should be larger
STORAGE_CHUNK_SIZE=50M
CATALOG = ${DATA_DIR}/${STORAGE_BUCKET}.${STORAGE_CLI}.list
CATALOG_TAG = ${DATA_DIR}/${STORAGE_BUCKET}.tag
S3_CONFIG = ${TOOLS_PATH}/.aws/config
export RCLONE_PROVIDER = s3
export RCLONE_CONFIG_S3_ACCESS_KEY_ID=${STORAGE_ACCESS_KEY}
export RCLONE_CONFIG_S3_SECRET_ACCESS_KEY=${STORAGE_SECRET_KEY}

SSHID=${APP_GROUP_MAIL}
SSHKEY_PRIVATE = ${HOME}/.ssh/id_rsa_${APP_GROUP}
SSHKEY = ${SSHKEY_PRIVATE}.pub
SSHKEYNAME = ${TOOLS}
SSH_TIMEOUT = 90

EC2=ec2 ${EC2_ENDPOINT_OPTION} --profile ${EC2_PROFILE}

START_TIMEOUT = 120
CLOUD_DIR=${TOOLS_PATH}/cloud
CLOUD=SCW

NGINX_DIR=${TOOLS_PATH}/nginx
NGINX_UPSTREAM_REMOTE_PATH=/etc/nginx/conf.d
CONFIG_DIR=${TOOLS_PATH}/configured
CONFIG_INIT_FILE=${CONFIG_DIR}/init
CONFIG_NEXT_FILE=${CONFIG_DIR}/next
CONFIG_FILE=${CONFIG_DIR}/conf
CONFIG_REMOTE_FILE=${CONFIG_DIR}/remote
CONFIG_REMOTE_PROXY_FILE=${CONFIG_DIR}/remote.proxy
CONFIG_TOOLS_FILE=${CONFIG_DIR}/${TOOLS}.deployed
CONFIG_APP_FILE=${CONFIG_DIR}/${APP}.deployed
CONFIG_DOCKER_FILE=${CONFIG_DIR}/docker
CONFIG_AWS_FILE=${CONFIG_DIR}/aws
CONFIG_SWIFT_FILE=${CONFIG_DIR}/swift
CONFIG_RCLONE_FILE=${CONFIG_DIR}/rclone

dummy		    := $(shell touch artifacts)
include ./artifacts

SSHOPTS=-o "StrictHostKeyChecking no" -i ${SSHKEY} ${CLOUD_SSHOPTS}

tag                 := $(shell [ -f "/usr/bin/git" ] && git describe --tags | sed 's/-.*//')
VERSION 		:= $(shell cat tagfiles.${CLOUD_CLI}.version | xargs -I '{}' find {} -type f -not -name '*.tar.gz'  | sort | xargs cat | sha1sum - | sed 's/\(......\).*/\1/')
export APP_VERSION =  ${tag}-${VERSION}

CLOUD_GROUP=$(shell echo ${APP_GROUP} | tr '[:upper:]' '[:lower:]')
CLOUD_APP=$(shell echo ${APP} | tr '[:upper:]' '[:lower:]')
CLOUD_SSHKEY_FILE=${CLOUD_DIR}/${CLOUD}.sshkey
CLOUD_SERVER_ID_FILE=${CLOUD_DIR}/${CLOUD}.id
CLOUD_HOST_FILE=${CLOUD_DIR}/${CLOUD}.host
CLOUD_FIRST_USER_FILE=${CLOUD_DIR}/${CLOUD}.user.first
CLOUD_USER_FILE=${CLOUD_DIR}/${CLOUD}.user
CLOUD_UP_FILE=${CLOUD_DIR}/${CLOUD}.up
CLOUD_HOSTNAME=${CLOUD_GROUP}-${CLOUD_APP}
CLOUD_TAGGED_IDS_FILE=${CLOUD_DIR}/${CLOUD}.tag.ids
CLOUD_TAGGED_HOSTS_FILE=${CLOUD_DIR}/${CLOUD}.tag.hosts
CLOUD_TAGGED_IDS_INVALID_FILE=${CLOUD_DIR}/${CLOUD}.tag.ids.ko
CLOUD_TAGGED_HOSTS_INVALID_FILE=${CLOUD_DIR}/${CLOUD}.tag.hosts.ko
CLOUD_TAG=${APP_VERSION}
SCW_SERVER_CONF={"name": "${CLOUD_HOSTNAME}", "tags": ["${GIT_BRANCH}","${CLOUD_TAG}"],\
"image": "${SCW_IMAGE_ID}", "commercial_type": "${SCW_FLAVOR}", "organization": "${SCW_ORGANIZATION_ID}"}

NGINX_UPSTREAM_FILE=${NGINX_DIR}/${GIT_BRANCH}.${CLOUD_HOSTNAME}-upstream.conf
NGINX_UPSTREAM_BACKUP=${NGINX_DIR}/${GIT_BRANCH}.${CLOUD_HOSTNAME}-upstream.bak
NGINX_UPSTREAM_REMOTE_FILE=${NGINX_UPSTREAM_REMOTE_PATH}/${GIT_BRANCH}.${CLOUD_HOSTNAME}-upstream.conf
NGINX_UPSTREAM_REMOTE_BACKUP=${NGINX_UPSTREAM_REMOTE_PATH}/${GIT_BRANCH}.${CLOUD_HOSTNAME}-upstream.bak
NGINX_UPSTREAM_APPLIED_FILE=${NGINX_DIR}/${GIT_BRANCH}.${CLOUD_HOSTNAME}-upstream.ok

version:
	@echo ${APP_GROUP} ${APP} ${APP_VERSION}

os-type:
	@echo ${OS_TYPE}

${DATA_DIR}:
	@if [ ! -d "${DATA_DIR}" ]; then mkdir -p ${DATA_DIR};fi

${CONFIG_DIR}:
	@mkdir -p ${CONFIG_DIR}

${CONFIG_INIT_FILE}: ${CONFIG_DIR} config-proxy tools-install docker-install
	@touch ${CONFIG_INIT_FILE}

${CONFIG_NEXT_FILE}: ${CONFIG_DIR} config-${STORAGE_CLI}
	@touch ${CONFIG_NEXT_FILE}

config-init: ${CONFIG_INIT_FILE}

config-next: ${CONFIG_NEXT_FILE}

${CONFIG_FILE}: ${CONFIG_INIT_FILE} ${CONFIG_NEXT_FILE}
	@touch ${CONFIG_FILE}

config: ${CONFIG_FILE}

config-proxy:
	@if [ ! -z "${http_proxy}" ];then\
		if [ -z "$(grep http_proxy /etc/environment)"]; then\
			(echo "http_proxy=${http_proxy}" | sudo tee -a /etc/environment);\
		fi;\
	fi;
	@if [ ! -z "${https_proxy}" ];then\
		if [ -z "$(grep https_proxy /etc/environment)"]; then\
			(echo "https_proxy=${https_proxy}" | sudo tee -a /etc/environment);\
		fi;\
	fi;
	@if [ ! -z "${no_proxy}" ];then\
		if [ -z "$(grep no_proxy /etc/environment)"]; then\
			(echo "no_proxy=${no_proxy}" | sudo tee -a /etc/environment);\
		fi;\
	fi;

# system tools, widely used in matchID projects

tools-install:
	@if [ ! -f "/usr/bin/envsubst" ] || [ ! -f "/usr/bin/curl" ] ||\
	   [ ! -f "/usr/bin/gawk" ] || [ ! -f "/usr/bin/gawk" ] || [ ! -f "/usr/bin/jq" ] || [ ! -f "/usr/bin/recode" ] ; then\
		if [ "${OS_TYPE}" = "DEB" ]; then\
			sudo apt-get install -yqq gettext curl recode gawk jq; true;\
		fi;\
		if [ "${OS_TYPE}" = "RPM" ]; then\
			sudo yum install -y gettext curl recode gawk jq; true;\
		fi;\
	fi
	@if [ -z "$(wildcard /usr/lib/*/perl*/*/Date/Pcalc)" ] || \
		[ -z "$(wildcard /usr/lib/*/perl*/*/JSON/XS)" ] || \
		[ -z "$(wildcard /usr/lib/*/perl*/*/Geo/IP)" ]; then\
		if [ "${OS_TYPE}" = "DEB" ]; then\
			sudo apt-get install -yqq libdate-calc-perl libjson-xs-perl libgeo-ip-perl; true;\
		fi;\
		if [ "${OS_TYPE}" = "RPM" ]; then\
			sudo yum install -y perl-Date-Calc perl-Geo-IP perl-JSON-XS perl-Digest-SHA; true;\
		fi;\
	fi

#docker section
docker-install: ${CONFIG_DOCKER_FILE} docker-config-proxy

docker-config-proxy:
	@if [ ! -z "${http_proxy}" ];then\
		if [ ! -f "/etc/systemd/system/docker.service.d/http-proxy.conf" ]; then\
			sudo mkdir -p /etc/systemd/system/docker.service.d/;\
			(echo '[Service]' | sudo tee -a /etc/systemd/system/docker.service.d/http-proxy.conf);\
			(echo 'Environment="HTTPS_PROXY=${http_proxy}" "HTTP_PROXY=${https_proxy}"' | sudo tee -a /etc/systemd/system/docker.service.d/http-proxy.conf);\
			sudo systemctl daemon-reload;\
			sudo systemctl restart docker;\
		fi;\
	fi

${CONFIG_DOCKER_FILE}: ${CONFIG_DIR}
ifeq ("$(wildcard /usr/bin/docker /usr/local/bin/docker)","")
	echo install docker-ce
	@if [ "${OS_TYPE}" = "DEB" ]; then\
		(sudo echo '* libraries/restart-without-asking boolean true' | sudo debconf-set-selections);\
		sudo apt-get update -yqq;\
		sudo apt-get install -yqq \
			apt-transport-https \
			ca-certificates \
			curl \
			software-properties-common;\
		curl -fsSL https://download.docker.com/linux/${ID}/gpg | sudo apt-key add -;\
		sudo add-apt-repository \
			"deb https://download.docker.com/linux/ubuntu \
			`lsb_release -cs` \
			stable";\
		sudo apt-get update -yqq;\
		sudo apt-get install -yqq docker-ce;\
	fi;
	@if [ "${OS_TYPE}" = "RPM" ]; then\
		sudo yum install -y yum-utils;\
		RPM_FLAVOR=`grep -Ei '^ID=' /etc/os-release | sed 's/.*=//;s/"//g'`;\
		sudo yum-config-manager \
			--add-repo \
			https://download.docker.com/linux/$$RPM_FLAVOR/docker-ce.repo;\
		sudo yum install -y iptables docker-ce docker-ce-cli containerd.io;\
		sudo gpasswd -a $$USER docker;\
		sudo systemctl start docker;\
	fi;
endif
	@(if (id -Gn ${USER} | grep -vc docker); then sudo usermod -aG docker ${USER} ;fi) > /dev/null
ifeq ("$(wildcard /usr/bin/docker-compose ${HOME}/.local/bin/docker-compose /usr/local/bin/docker-compose)","")
	@echo installing docker-compose
	@mkdir -p ${HOME}/.local/bin && curl -s -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$$(uname -s)-$$(uname -m)" -o ${HOME}/.local/bin/docker-compose
	@chmod +x ${HOME}/.local/bin/docker-compose
	@sudo cp ${HOME}/.local/bin/docker-compose /usr/local/bin
endif
	@touch ${CONFIG_DOCKER_FILE}

docker-build:
	@if [ ! -z "${VERBOSE}" ];then\
		${DC} config;\
	fi;
	@${DC} build $(DC_BUILD_ARGS)

docker-tag:
	@if [ "${GIT_BRANCH}" == "${GIT_BRANCH_MASTER}" ];then\
		docker tag ${DOCKER_USERNAME}/${DC_IMAGE_NAME}:${APP_VERSION} ${DOCKER_USERNAME}/${DC_IMAGE_NAME}:latest;\
	else\
		docker tag ${DOCKER_USERNAME}/${DC_IMAGE_NAME}:${APP_VERSION} ${DOCKER_USERNAME}/${DC_IMAGE_NAME}:${GIT_BRANCH};\
	fi

docker-check:
	@if [ ! -f ".${DOCKER_USERNAME}-${DC_IMAGE_NAME}:${APP_VERSION}" ]; then\
		(\
			(docker image inspect ${DOCKER_USERNAME}/${DC_IMAGE_NAME}:${APP_VERSION} > /dev/null 2>&1)\
			&& touch .${DOCKER_USERNAME}-${DC_IMAGE_NAME}:${APP_VERSION}\
		)\
		||\
		(\
			(docker pull ${DOCKER_USERNAME}/${DC_IMAGE_NAME}:${APP_VERSION} 2> /dev/null)\
			&& touch .${DOCKER_USERNAME}-${DC_IMAGE_NAME}:${APP_VERSION}\
		)\
		|| (echo no previous build found for ${DOCKER_USERNAME}/${DC_IMAGE_NAME}:${APP_VERSION} && exit 1);\
	fi;

docker-push: docker-login docker-tag
	@docker push ${DOCKER_USERNAME}/${DC_IMAGE_NAME}:${APP_VERSION}
	@if [ "${GIT_BRANCH}" == "${GIT_BRANCH_MASTER}" ];then\
		docker push ${DOCKER_USERNAME}/${DC_IMAGE_NAME}:latest;\
	else\
		docker push ${DOCKER_USERNAME}/${DC_IMAGE_NAME}:${GIT_BRANCH};\
	fi

docker-login:
	@echo docker login for ${DOCKER_USERNAME}
	@echo "${DOCKER_PASSWORD}" | docker login -u "${DOCKER_USERNAME}" --password-stdin

docker-pull:
	@docker pull ${DOCKER_USERNAME}/${DC_IMAGE_NAME}:${APP_VERSION}
	@echo docker pulled ${DOCKER_USERNAME}/${DC_IMAGE_NAME}:${APP_VERSION}

docker-logs-to-API:
	@(${TOOLS_PATH}/docker-logs > /dev/null 2>&1 &)

generate-test-file: ${DATA_DIR}
	dd if=/dev/urandom bs=16M count=16 > ${FILE}

#cloud section
${SSHKEY}:
	@echo ssh keygen
	@ssh-keygen -t rsa -b 4096 -C "${SSHID}" -f ${SSHKEY_PRIVATE} -q -N "${SSH_PASSPHRASE}"

${CLOUD_DIR}:
	@mkdir -p ${CLOUD_DIR};\
	echo creating ${CLOUD_DIR} for cloud ids

cloud-dir-delete:
	@rm -rf ${CLOUD_DIR} > /dev/null 2>&1

${CLOUD_FIRST_USER_FILE}: ${CLOUD_DIR}
	@if [ "${CLOUD}" == "SCW" ];then\
		echo "root" > ${CLOUD_FIRST_USER_FILE};\
	elif [ "${CLOUD}" == "OS" ];then\
		echo ${OS_SSHUSER} > ${CLOUD_FIRST_USER_FILE};\
	elif [ "${CLOUD}" == "EC2" ];then\
		echo ${EC2_SSHUSER} > ${CLOUD_FIRST_USER_FILE};\
	else\
		echo ${SSHUSER} > ${CLOUD_FIRST_USER_FILE};\
	fi;\
	echo using $$(cat ${CLOUD_FIRST_USER_FILE}) for first ssh connexion

${CLOUD_USER_FILE}: ${CLOUD_DIR}
	@if [ "${CLOUD}" == "SCW" ];then\
		echo ${SCW_SSHUSER} > ${CLOUD_USER_FILE};\
	elif [ "${CLOUD}" == "OS" ];then\
		echo ${OS_SSHUSER} > ${CLOUD_USER_FILE};\
	elif [ "${CLOUD}" == "EC2" ];then\
		echo ${EC2_SSHUSER} > ${CLOUD_USER_FILE};\
	else\
		echo ${SSHUSER} > ${CLOUD_USER_FILE};\
	fi;\
	echo using $$(cat ${CLOUD_USER_FILE}) for next ssh connexions

${CLOUD_SERVER_ID_FILE}: ${CLOUD_DIR} ${CLOUD}-instance-order
	@echo ${CLOUD} id: $$(cat ${CLOUD_SERVER_ID_FILE})

${CLOUD_HOST_FILE}: ${CLOUD_DIR} ${CLOUD}-instance-get-host
	@echo ${CLOUD} ip: $$(cat ${CLOUD_HOST_FILE})

${CLOUD}-instance-wait-ssh: ${CLOUD_FIRST_USER_FILE} ${CLOUD_HOST_FILE}
	@if [ ! -f "${CLOUD_UP_FILE}" ];then\
		HOST=$$(cat ${CLOUD_HOST_FILE});\
		SSHUSER=$$(cat ${CLOUD_FIRST_USER_FILE});\
		(ssh-keygen -R $$HOST > /dev/null 2>&1) || true;\
		timeout=${SSH_TIMEOUT} ; ret=1 ;\
		until [ "$$timeout" -le 0 -o "$$ret" -eq "0"  ] ; do\
			((ssh ${SSHOPTS} $$SSHUSER@$$HOST sleep 1) );\
			ret=$$? ; \
			if [ "$$ret" -ne "0" ] ; then\
				echo -en "\rwaiting for ssh service on ${CLOUD} instance - $$timeout" ; \
				if [ ! -z "${VERBOSE}" ];then\
					echo 'cmd: ssh ${SSHOPTS} -o ConnectTimeout=1 '"$$SSHUSER@$$HOST"; \
				fi;\
			fi ;\
			((timeout--)); sleep 1 ; \
		done ; echo ;\
		exit $$ret;\
	fi

${CLOUD_UP_FILE}: ${CLOUD}-instance-wait-ssh ${CLOUD_USER_FILE}
	@touch ${CLOUD_UP_FILE}

cloud-instance-up: ${CLOUD_UP_FILE}

cloud-instance-down: ${CLOUD}-instance-delete
	@(rm ${CLOUD_UP_FILE} ${CLOUD_HOST_FILE} ${CLOUD_SERVER_ID_FILE} \
		${CLOUD_FIRST_USER_FILE} ${CLOUD_USER_FILE} ${CLOUD_SSHKEY_FILE} > /dev/null 2>&1) || true

cloud-instance-down-invalid: ${CLOUD}-instance-delete-invalid

nginx-dir:
	@if [ ! -d ${NGINX_DIR} ]; then mkdir -p ${NGINX_DIR};fi

nginx-dir-clean:
	@if [ -d ${NGINX_DIR} ]; then (rm -rf ${NGINX_DIR} > /dev/null 2>&1);fi

nginx-conf-create: ${CLOUD}-instance-get-tagged-hosts nginx-dir
	@if [ ! -f "${NGINX_UPSTREAM_FILE}" ];then\
		if [ ! -z "$$(cat ${CLOUD_TAGGED_HOSTS_FILE})" ]; then\
			cat ${CLOUD_TAGGED_HOSTS_FILE} \
				| awk 'BEGIN{print "upstream ${CLOUD_HOSTNAME}-${GIT_BRANCH} {"}{print "      server " $$1 ":${PORT};"}END{print "}"}'\
				> ${NGINX_UPSTREAM_FILE};\
		fi;\
	fi;

nginx-conf-backup:
	@if [ ! -z "${NGINX_HOST}" ];then\
		if [ -f "${NGINX_UPSTREAM_FILE}" ];then\
			((ssh ${SSHOPTS} ${NGINX_USER}@${NGINX_HOST} cat ${NGINX_UPSTREAM_REMOTE_FILE}) > ${NGINX_UPSTREAM_BACKUP});\
			(ssh ${SSHOPTS} ${NGINX_USER}@${NGINX_HOST} sudo cp ${NGINX_UPSTREAM_REMOTE_FILE} ${NGINX_UPSTREAM_REMOTE_BACKUP});\
		fi;\
	fi;

nginx-conf-apply: nginx-conf-create nginx-conf-backup
	@if [ ! -f "${NGINX_UPSTREAM_APPLIED_FILE}" ];then\
		if [ ! -z "${NGINX_HOST}" ];then\
			if [ -f "${NGINX_UPSTREAM_FILE}" ];then\
				(cat ${NGINX_UPSTREAM_FILE}\
					| ssh ${SSHOPTS} ${NGINX_USER}@${NGINX_HOST} "sudo tee ${NGINX_UPSTREAM_REMOTE_FILE}") &&\
				(ssh ${SSHOPTS} ${NGINX_USER}@${NGINX_HOST} sudo service nginx reload);\
			fi;\
		fi;\
		touch ${NGINX_UPSTREAM_APPLIED_FILE};\
	fi;


#Scaleway section
SCW-check-api:
	@if curl -s --fail --connect-timeout 5 ${SCW_API} | egrep -q '"api":\s*"api-compute"'; then\
		echo "SCW API: OK";\
	else\
		echo -e "\e[31mSCW API: KO!\e[0m";\
		echo -e "endpoint: ${SCW_API}";\
		ping -c 3 -W 5 `echo ${SCW_API} | sed 's|.*://||;s|/.*||'`;\
		curl -s --fail --connect-timeout 5 -vv ${SCW_API};\
		exit 1;\
	fi

SCW-instance-order: ${CLOUD_DIR} SCW-check-api
	@if [ ! -f ${CLOUD_SERVER_ID_FILE} ]; then\
		SCW_SERVER_OPTS=$$(echo '${SCW_SERVER_CONF}' '${SCW_SERVER_OPTS}' | jq -cs add);\
		if [ ! -z "${VERBOSE}" ]; then\
			echo "SCW server options $$SCW_SERVER_OPTS";\
		fi;\
		curl -s ${SCW_API}/servers -H "X-Auth-Token: ${SCW_SECRET_TOKEN}" \
			-H "Content-Type: application/json" \
			-d "$$SCW_SERVER_OPTS" \
		| jq -r '.server.id' > ${CLOUD_SERVER_ID_FILE};\
	fi

SCW-instance-start: ${CLOUD_SERVER_ID_FILE}
	@SCW_SERVER_ID=$$(cat ${CLOUD_SERVER_ID_FILE});\
		(curl -s ${SCW_API}/servers -H "X-Auth-Token: ${SCW_SECRET_TOKEN}" | jq -cr  ".servers[] | select (.id == \"$$SCW_SERVER_ID\") | .state" | (grep running > /dev/null) && \
		echo scaleway instance already running)\
		|| \
	 	(\
			(\
				(curl -s --fail ${SCW_API}/servers/$$SCW_SERVER_ID/action -H "X-Auth-Token: ${SCW_SECRET_TOKEN}" \
					-H "Content-Type: application/json" -d '{"action": "poweron"}' > /dev/null) &&\
				echo scaleway instance starting\
			) || echo scaleway instance still starting\
		)

SCW-instance-wait-running: SCW-instance-start
	@if [ ! -f "${CLOUD_UP_FILE}" ];then\
		SCW_SERVER_ID=$$(cat ${CLOUD_SERVER_ID_FILE});\
		timeout=${START_TIMEOUT} ; ret=1 ;\
		until [ "$$timeout" -le 0 -o "$$ret" -eq "0"  ] ; do\
			curl -s ${SCW_API}/servers -H "X-Auth-Token: ${SCW_SECRET_TOKEN}" | jq -cr  ".servers[] | select (.id == \"$$SCW_SERVER_ID\") | .state" | (grep running > /dev/null);\
			ret=$$? ; \
			if [ "$$ret" -ne "0" ] ; then echo -en "\rwaiting for scaleway instance $$SCW_SERVER_ID to start $$timeout" ; fi ;\
			((timeout--)); sleep 1 ; \
		done ; echo ;\
		exit $$ret;\
	fi

SCW-instance-get-host: SCW-instance-wait-running
	@if [ ! -f "${CLOUD_HOST_FILE}" ];then\
		SCW_SERVER_ID=$$(cat ${CLOUD_SERVER_ID_FILE});\
		curl -s ${SCW_API}/servers -H "X-Auth-Token: ${SCW_SECRET_TOKEN}" \
			| jq -cr  ".servers[] | select (.id == \"$$SCW_SERVER_ID\") | .${SCW_IP}" \
			> ${CLOUD_HOST_FILE};\
	fi


SCW-instance-delete:
	@if [ -f "${CLOUD_SERVER_ID_FILE}" ];then\
		SCW_SERVER_ID=$$(cat ${CLOUD_SERVER_ID_FILE});\
		(\
			(\
				curl -s --fail ${SCW_API}/servers/$$SCW_SERVER_ID/action -H "X-Auth-Token: ${SCW_SECRET_TOKEN}" \
					-H "Content-Type: application/json" -d '{"action": "terminate"}' > /dev/null \
			) \
		&& \
			(\
				echo scaleway server $$(cat ${CLOUD_SERVER_ID_FILE}) terminating\
			)\
		) || (echo scaleway error while terminating server && exit 1);\
	else\
		(echo no ${CLOUD_SERVER_ID_FILE} for deletion);\
	fi

SCW-instance-delete-invalid: SCW-instance-get-tagged-ids-invalid
	@if [ -f "${CLOUD_TAGGED_IDS_INVALID_FILE}" ];then\
		if [ -s "${CLOUD_TAGGED_IDS_INVALID_FILE}" ];then\
			for SCW_SERVER_ID in $$(cat ${CLOUD_TAGGED_IDS_INVALID_FILE}); do\
				(\
					(\
						curl -s --fail ${SCW_API}/servers/$$SCW_SERVER_ID/action -H "X-Auth-Token: ${SCW_SECRET_TOKEN}" \
							-H "Content-Type: application/json" -d '{"action": "terminate"}' > /dev/null \
					) \
				&& \
					(\
						echo scaleway server $$SCW_SERVER_ID terminating\
					)\
				) || (echo scaleway error while terminating server && exit 1);\
			done;\
		else\
			echo "no invalid server to delete";\
		fi;\
	else\
		(echo no ${CLOUD_TAGGED_IDS_INVALID_FILE} for deletion);\
	fi

SCW-instance-get-tagged-ids: ${CLOUD_DIR}
	@if [ ! -f "${CLOUD_TAGGED_IDS_FILE}" ];then\
		curl -s ${SCW_API}/servers -H "X-Auth-Token: ${SCW_SECRET_TOKEN}" -H "Content-Type: application/json"  \
			| jq -cr '.servers[] | select(.name=="${CLOUD_HOSTNAME}" and (.tags[0] | contains("${GIT_BRANCH}")) and (.tags[1] | contains("${CLOUD_TAG}"))) | .id'\
			> ${CLOUD_TAGGED_IDS_FILE};\
	fi

SCW-instance-get-tagged-ids-invalid: ${CLOUD_DIR}
	@if [ ! -f "${CLOUD_TAGGED_IDS_INVALID_FILE}" ];then\
		curl -s ${SCW_API}/servers -H "X-Auth-Token: ${SCW_SECRET_TOKEN}" -H "Content-Type: application/json"  \
			| jq -cr '.servers[] | select(.name=="${CLOUD_HOSTNAME}" and (.tags[0] | contains("${GIT_BRANCH}")) and (.tags[1] | contains("${CLOUD_TAG}") | not)) | .id'\
			> ${CLOUD_TAGGED_IDS_INVALID_FILE};\
	fi

SCW-instance-get-tagged-hosts: SCW-instance-get-tagged-ids
	@if [ ! -f "${CLOUD_TAGGED_HOSTS_FILE}" ];then\
		curl -s ${SCW_API}/servers -H "X-Auth-Token: ${SCW_SECRET_TOKEN}" -H "Content-Type: application/json"  \
			| jq -cr '.servers[] | select(.name=="${CLOUD_HOSTNAME}" and (.tags[0] | contains("${GIT_BRANCH}")) and (.tags[1] | contains("${CLOUD_TAG}"))) | .${SCW_IP}'\
			> ${CLOUD_TAGGED_HOSTS_FILE};\
	fi

SCW-instance-get-tagged-hosts-invalid: SCW-instance-get-tagged-ids-invalid
	@if [ ! -f "${CLOUD_TAGGED_HOSTS_INVALID_FILE}" ];then\
		curl -s ${SCW_API}/servers -H "X-Auth-Token: ${SCW_SECRET_TOKEN}" -H "Content-Type: application/json"  \
			| jq -cr '.servers[] | select(.name=="${CLOUD_HOSTNAME}" and (.tags[0] | contains("${GIT_BRANCH}")) and (.tags[1] | contains("${CLOUD_TAG}") | not)) | .${SCW_IP}'\
			> ${CLOUD_TAGGED_HOSTS_INVALID_FILE};\
	fi

#Openstack section
OS-add-sshkey: ${SSHKEY} ${CLOUD_DIR}
	@if [ ! -f "${CLOUD_SSHKEY_FILE}" ];then\
	(\
		(nova keypair-list | sed 's/|//g' | egrep -v '\-\-\-|Name' | (egrep '^\s*${SSHKEYNAME}\s' > /dev/null) &&\
		 echo "ssh key already deployed to openstack" &&\
		 touch ${CLOUD_SSHKEY_FILE}\
		 ) \
	  || \
		(nova keypair-add --pub-key ${SSHKEY} ${SSHKEYNAME} &&\
		 nova keypair-list | sed 's/|//g' | egrep -v '\-\-\-|Name' | (egrep '^\s*${SSHKEYNAME}\s' > /dev/null) &&\
		 echo "ssh key deployed with success to openstack" &&\
		 touch ${CLOUD_SSHKEY_FILE}\
		 ) \
	  );\
	fi;

OS-instance-order: ${CLOUD_DIR} OS-add-sshkey
	@if [ ! -f "${CLOUD_SERVER_ID_FILE}" ];then\
	(\
		(nova list | sed 's/|//g' | egrep -v '\-\-\-|Name' | (egrep '\s${CLOUD_HOSTNAME}\s' > /dev/null) && \
		echo "openstack instance already ordered")\
	 || \
		(nova boot --key-name ${SSHKEYNAME} --flavor ${OS_FLAVOR_ID} --image ${OS_IMAGE_ID} ${CLOUD_HOSTNAME} && \
	 		echo "openstack intance ordered with success" &&\
			(echo ${CLOUD_HOSTNAME} > ${CLOUD_SERVER_ID_FILE}) \
		) || echo "openstance instance order failed"\
	);\
	fi

OS-instance-wait-running: ${CLOUD_SERVER_ID_FILE}
	@if [ ! -f "${CLOUD_UP_FILE}" ];then\
		timeout=${START_TIMEOUT} ; ret=1 ;\
		until [ "$$timeout" -le 0 -o "$$ret" -eq "0"  ] ; do\
	  		nova list | sed 's/|//g' | egrep -v '\-\-\-|Name' | (egrep '\s${CLOUD_HOSTNAME}\s.*Running' > /dev/null) ;\
	  		ret=$$? ; \
			if [ "$$ret" -ne "0" ] ; then echo -en "\rwaiting for openstack instance to start $$timeout" ; fi ;\
	  		((timeout--)); sleep 1 ; \
		done ; echo ;\
		exit $$ret;\
	fi

OS-instance-get-host: OS-instance-wait-running
	@if [ ! -f "${CLOUD_HOST_FILE}" ];then\
		(nova list | sed 's/|//g' | egrep -v '\-\-\-|Name' | egrep '\s${CLOUD_HOSTNAME}\s.*Running' |\
			sed 's/.*Ext-Net=//;s/,.*//' > ${CLOUD_HOST_FILE});\
	fi

OS-instance-delete:
	@nova delete $$(cat ${CLOUD_SERVER_ID_FILE})

# rclone section
${CONFIG_RCLONE_FILE}: ${CONFIG_DIR}
	@if [ ! -f "${RCLONE}" ]; then\
		if [ "${OS_TYPE}" = "DEB" ]; then\
			curl -s -O https://downloads.rclone.org/rclone-current-linux-amd64.deb;\
			sudo dpkg -i rclone-current-linux-amd64.deb; \
			rm rclone-*-linux-amd64*;\
			touch ${CONFIG_RCLONE_FILE};\
		fi;\
		if [ "${OS_TYPE}" = "RPM" ]; then\
			curl -s -O https://downloads.rclone.org/rclone-current-linux-amd64.rpm;\
			sudo yum localinstall -y rclone-current-linux-amd64.rpm; \
			rm rclone-*-linux-amd64*;\
			touch ${CONFIG_RCLONE_FILE};\
		fi;\
	else\
		touch ${CONFIG_RCLONE_FILE};\
	fi

config-rclone: ${CONFIG_RCLONE_FILE}


rclone-get-catalog: ${CONFIG_RCLONE_FILE} ${DATA_DIR}
	@echo getting ${STORAGE_BUCKET} catalog from ${RCLONE_PROVIDER} API
	@${RCLONE} -q ${RCLONE_OPTS} ls ${RCLONE_PROVIDER}:${STORAGE_BUCKET} | awk '{print $$NF}' | egrep '^${FILES_PATTERN}$$' | sort > ${CATALOG}

datagouv-to-rclone: rclone-get-catalog datagouv-get-files
	@for file in $$(ls ${DATA_DIR} | egrep '^${FILES_PATTERN}$$' | grep -v tmp.list);do\
		echo copy ${DATA_DIR}/$$file to ${RCLONE_PROVIDER}:${STORAGE_BUCKET};\
		(${RCLONE} -q copy ${DATA_DIR}/$$file ${RCLONE_PROVIDER}:${STORAGE_BUCKET} || (echo failed && exit 1));\
	done

rclone-push:
	@${RCLONE} ${RCLONE_OPTS} -q --progress ${STORAGE_OPTIONS} --s3-chunk-size ${STORAGE_CHUNK_SIZE} copy ${FILE} ${RCLONE_PROVIDER}:${STORAGE_BUCKET}

rclone-pull:
	@${RCLONE} ${RCLONE_OPTS} -q --progress copy ${RCLONE_PROVIDER}:${STORAGE_BUCKET}/${FILE} ${DATA_DIR}

rclone-sync-pull:
	@${RCLONE} -q sync ${RCLONE_PROVIDER}:${STORAGE_BUCKET}/ ${DATA_DIR}/

rclone-sync-push:
	@${RCLONE} -q sync ${STORAGE_OPTIONS} ${DATA_DIR}/ ${RCLONE_PROVIDER}:${STORAGE_BUCKET}/

# swift section
${CONFIG_SWIFT_FILE}: ${CONFIG_DIR} docker-check

config-swift: ${CONFIG_SWIFT_FILE}

swift-get-catalog: ${CONFIG_SWIFT_FILE} ${DATA_DIR}
	@echo getting ${SWIFT_STORAGE_BUCKET} catalog from ${CLOUD_CLI} API
	@unset OS_REGION_NAME;\
	${SWIFT} --os-auth-url ${OS_AUTH_URL} --auth-version ${OS_IDENTITY_API_VERSION}\
			  --os-tenant-name ${OS_TENANT_NAME}\
			  --os-storage-url ${OS_SWIFT_URL}${OS_SWIFT_ID}\
			  --os-username ${STORAGE_ACCESS_KEY}\
			  --os-password ${STORAGE_SECRET_KEY}\
			  list ${STORAGE_BUCKET}\
	| egrep '^${FILES_PATTERN}$$' | sort > ${CATALOG}

swift-push:
	${SWIFT} --os-auth-url ${OS_AUTH_URL} --auth-version ${OS_IDENTITY_API_VERSION}\
		--os-project-id ${OS_PROJECT_ID}\
		--os-project-name ${OS_PROJECT_NAME}\
		--os-user-domain-name ${OS_USER_DOMAIN_NAME}\
		--os-username ${OS_USERNAME}\
		--os-password ${OS_PASSWORD}\
		--os-region-name ${OS_REGION_NAME}\
		--insecure \
		upload ${STORAGE_BUCKET} ${FILE}\
		--object-name $$(basename ${FILE})

swift-pull:
	${SWIFT} --os-auth-url ${OS_AUTH_URL} --auth-version ${OS_IDENTITY_API_VERSION}\
		--os-project-id ${OS_PROJECT_ID}\
		--os-project-name ${OS_PROJECT_NAME}\
		--os-user-domain-name ${OS_USER_DOMAIN_NAME}\
		--os-username ${OS_USERNAME}\
		--os-password ${OS_PASSWORD}\
		--os-region-name ${OS_REGION_NAME}\
		--insecure \
		download ${STORAGE_BUCKET} $$(basename ${FILE}) -o ${PWD}/${FILE}

#EC2 section

${CONFIG_AWS_FILE}: ${CONFIG_DIR} docker-check
	@if [ ! -d "${HOME}/.aws" ];then\
		echo create aws configuration;\
		mkdir -p ${HOME}/.aws;\
		echo -e "[default]\naws_access_key_id=${STORAGE_ACCESS_KEY}\naws_secret_access_key=${STORAGE_SECRET_KEY}\n" \
		> ${HOME}/.aws/credentials;\
		cp .aws/config ${HOME}/.aws/;\
	fi;
	@touch ${CONFIG_AWS_FILE}

config-aws: ${CONFIG_AWS_FILE}

EC2-add-sshkey: config-aws
	@if [ ! -f "${CLOUD_SSHKEY_FILE}" ];then\
		(\
			(\
				(${AWS} ${EC2} describe-key-pairs --key-name ${SSHKEYNAME}  > /dev/null 2>&1) &&\
				(echo "ssh key already deployed to EC2";\
				touch ${CLOUD_SSHKEY_FILE})\
			) \
		|| \
			(\
				(${AWS} ${EC2} import-key-pair --key-name ${SSHKEYNAME} --public-key-material file://${SSHKEY} \
					> /dev/null 2>&1)\
				&&\
					(echo "ssh key deployed with success to EC2";\
					touch ${CLOUD_SSHKEY_FILE})\
			) \
		);\
	fi

EC2-instance-order: ${CLOUD_DIR} config-aws EC2-add-sshkey
	@if [ ! -f "${CLOUD_SERVER_ID_FILE}" ];then\
		(\
			(\
				${AWS} ${EC2} run-instances --key-name ${SSHKEYNAME} \
		 			--image-id ${EC2_IMAGE_ID} --instance-type ${EC2_FLAVOR_TYPE} \
				| jq -r '.Instances[0].InstanceId' > ${CLOUD_SERVER_ID_FILE} 2>&1 \
		 	) && echo "EC2 instance ordered with success"\
		) || echo "EC2 instance order failed";\
	fi

EC2-instance-get-host: EC2-instance-wait-running
	@if [ ! -f "${CLOUD_HOST_FILE}" ];then\
		EC2_SERVER_ID=$$(cat ${CLOUD_SERVER_ID_FILE});\
		(${AWS} ${EC2} describe-instances --instance-ids $$EC2_SERVER_ID \
			| jq -r ".Reservations[].Instances[].${EC2_IP}" > ${CLOUD_HOST_FILE});\
	fi

EC2-instance-wait-running: ${CLOUD_SERVER_ID_FILE}
	@if [ ! -f "${CLOUD_UP_FILE}" ];then\
		EC2_SERVER_ID=$$(cat ${CLOUD_SERVER_ID_FILE});\
		timeout=${START_TIMEOUT} ; ret=1 ;\
		until [ "$$timeout" -le 0 -o "$$ret" -eq "0"  ] ; do\
			${AWS} ${EC2} describe-instances --instance-ids $$EC2_SERVER_ID | jq -c '.Reservations[].Instances[].State.Name' | (grep running > /dev/null);\
			ret=$$? ; \
			if [ "$$ret" -ne "0" ] ; then echo -en "\rwaiting for EC2 instance $$EC2_SERVER_ID to start $$timeout" ; fi ;\
			((timeout--)); sleep 1 ; \
		done ; echo ;\
		exit $$ret;\
	fi

EC2-instance-delete:
	@if [ -f "${CLOUD_SERVER_ID_FILE}" ];then\
		EC2_SERVER_ID=$$(cat ${CLOUD_SERVER_ID_FILE});\
		${AWS} ${EC2} terminate-instances --instance-ids $$EC2_SERVER_ID |\
			jq -r '.TerminatingInstances[0].CurrentState.Name' | sed 's/$$/ EC2 instance/';\
	fi

#Storage section
${CATALOG}: ${STORAGE_CLI}-get-catalog

datagouv-to-storage: datagouv-to-${STORAGE_CLI}

get-catalog: ${CATALOG}

${CATALOG_TAG}: ${CATALOG}

catalog-tag: ${CATALOG_TAG}
	@cat ${CATALOG} | sort | sed 's/\s*$$//'| sha1sum | awk '{print $$1}' | cut -c-8 > ${CATALOG_TAG}

storage-push: ${STORAGE_CLI}-push

storage-sync-push: ${STORAGE_CLI}-sync-push

storage-pull: ${STORAGE_CLI}-pull

storage-sync-pull: ${STORAGE_CLI}-sync-pull

#aws S3 section

aws-get-catalog: ${CONFIG_AWS_FILE} ${DATA_DIR}
	@echo getting ${STORAGE_BUCKET} catalog from s3 API
	@${AWS} s3 ls ${STORAGE_BUCKET} | awk '{print $$NF}' | egrep '^${FILES_PATTERN}$$' | sort > ${CATALOG}

aws-push:
	${AWS} s3 cp ${FILE} s3://${STORAGE_BUCKET}/$$(basename ${FILE})

aws-pull:
	${AWS} s3 cp s3://${STORAGE_BUCKET}/${FILE} ${DATA_DIR}/${FILE}

datagouv-to-aws: aws-get-catalog datagouv-get-files
	@for file in $$(ls ${DATA_DIR} | egrep '^${FILES_PATTERN}$$' | grep -v tmp.list);do\
		${AWS} s3 cp ${DATA_DIR}/$$file s3://${STORAGE_BUCKET}/$$file;\
		${AWS} s3api put-object-acl --acl public-read --STORAGE_BUCKET ${STORAGE_BUCKET} --key $$file && echo $$file acl set to public;\
	done

#DATAGOUV section
${DATAGOUV_CATALOG}: config ${DATA_DIR}
	@echo getting ${DATAGOUV_DATASET} catalog from data.gouv API ${DATAGOUV_API}
	@curl -s --fail ${DATAGOUV_API}/${DATAGOUV_DATASET}/ | \
		jq  -cr '.resources[] | .title + " " +.checksum.value + " " + .url' | sort > ${DATAGOUV_CATALOG}

datagouv-get-catalog: ${DATAGOUV_CATALOG}

datagouv-get-files: ${DATAGOUV_CATALOG}
	@if [ -s "${CATALOG}" ]; then\
		(echo egrep -v $$(cat ${CATALOG} | tr '\n' '|' | sed 's/.gz//g;s/^/"(/;s/|$$/)"/') ${DATAGOUV_CATALOG} | sh > ${DATA_DIR}/tmp.list) || true;\
	else\
		cat ${DATAGOUV_CATALOG} | egrep '/${FILES_PATTERN}$$' > ${DATA_DIR}/tmp.list;\
	fi

	@if [ -s "${DATA_DIR}/tmp.list" ]; then\
		i=0;\
		for file in $$(awk '{print $$1}' ${DATA_DIR}/tmp.list); do\
			if [ ! -f ${DATA_DIR}/$$file.gz.sha1 ]; then\
				echo getting $$file ;\
				grep $$file ${DATA_DIR}/tmp.list | awk '{print $$3}' | xargs curl -s > ${DATA_DIR}/$$file; \
				grep $$file ${DATA_DIR}/tmp.list | awk '{print $$2}' > ${DATA_DIR}/$$file.sha1.src; \
				sha1sum < ${DATA_DIR}/$$file | awk '{print $$1}' > ${DATA_DIR}/$$file.sha1.dst; \
				((diff ${DATA_DIR}/$$file.sha1.src ${DATA_DIR}/$$file.sha1.dst > /dev/null) || echo error downloading $$file); \
				if [ "$$file" \> "deces-2010" ];then\
					recode utf8..latin1 ${DATA_DIR}/$$file;\
				fi;\
				gzip ${DATA_DIR}/$$file; \
				sha1sum ${DATA_DIR}/$$file.gz > ${DATA_DIR}/$$file.gz.sha1; \
				((i++));\
			fi;\
		done;\
		if [ "$$i" == "0" ]; then\
			echo no new file downloaded from datagouv;\
		else\
			echo "$$i file(s) downloaded from datagouv";\
		fi;\
	else\
		echo no new file downloaded from datagouv;\
	fi

remote-config-proxy: ${CONFIG_DIR} ${CLOUD_FIRST_USER_FILE}
	@if [ ! -f "${CONFIG_REMOTE_PROXY_FILE}" ]; then\
		if [ ! -z "${remote_http_proxy}" ]; then\
			H=$$(cat ${CLOUD_HOST_FILE});\
			U=$$(cat ${CLOUD_FIRST_USER_FILE});\
			if [ "${CLOUD}" == "SCW" ];then\
				sudo="";\
			else\
				sudo=sudo;\
			fi;\
			if [ ! -z "${remote_http_proxy}" ];then\
				(echo "http_proxy=${remote_http_proxy}" | ssh ${SSHOPTS} $$U@$$H $$sudo tee -a /etc/environment);\
			fi;\
			if [ ! -z "${remote_https_proxy}" ];then\
				(echo "https_proxy=${remote_https_proxy}" | ssh ${SSHOPTS} $$U@$$H $$sudo tee -a /etc/environment);\
			fi;\
			if [ ! -z "${remote_no_proxy}" ];then\
				(echo "no_proxy=${remote_no_proxy}" | ssh ${SSHOPTS} $$U@$$H $$sudo tee -a /etc/environment);\
			fi;\
		fi;\
		touch ${CONFIG_REMOTE_PROXY_FILE};\
	fi;

${CONFIG_REMOTE_FILE}: cloud-instance-up remote-config-proxy ${CONFIG_DIR}
		@\
		if [ ! -f "${CONFIG_REMOTE_FILE}" ];then\
			H=$$(cat ${CLOUD_HOST_FILE});\
			U=$$(cat ${CLOUD_USER_FILE});\
			if [ "${CLOUD}" == "SCW" ];then\
				ssh ${SSHOPTS} root@$$H apt-get install -o Dpkg::Options::="--force-confold" -yq sudo;\
			fi;\
			ssh ${SSHOPTS} $$U@$$H mkdir -p ${APP_GROUP};\
			ssh ${SSHOPTS} $$U@$$H sudo apt-get install -yq make;\
			ssh ${SSHOPTS} $$U@$$H git clone -q ${GIT_ROOT}/${TOOLS} ${APP_GROUP}/${TOOLS};\
			ssh ${SSHOPTS} $$U@$$H make -C ${APP_GROUP}/${TOOLS} config-init http_proxy=${remote_http_proxy} https_proxy=${remote_https_proxy};\
			ssh ${SSHOPTS} $$U@$$H make -C ${APP_GROUP}/${TOOLS} config-next STORAGE_ACCESS_KEY=${STORAGE_ACCESS_KEY} STORAGE_SECRET_KEY=${STORAGE_SECRET_KEY};\
			touch ${CONFIG_REMOTE_FILE};\
			touch ${CONFIG_TOOLS_FILE};\
		fi

remote-config: ${CONFIG_REMOTE_FILE}

remote-deploy: remote-config ${CONFIG_APP_FILE}

remote-clean: cloud-instance-down
	@(rm ${CONFIG_REMOTE_FILE} ${CONFIG_REMOTE_PROXY_FILE} > /dev/null 2>&1) || true

${CONFIG_APP_FILE}: ${CONFIG_REMOTE_FILE}
		@\
		if [ ! -f "${CONFIG_APP_FILE}" ];then\
			H=$$(cat ${CLOUD_HOST_FILE});\
			U=$$(cat ${CLOUD_USER_FILE});\
			if [ "${APP}" != "${CLOUD_CLI}" ];then\
				ssh ${SSHOPTS} $$U@$$H git clone -q --branch ${GIT_BRANCH} ${GIT_ROOT}/${APP} ${APP_GROUP}/${APP};\
				ssh ${SSHOPTS} $$U@$$H make -C ${APP_GROUP}/${APP} config;\
			fi;\
			touch ${CONFIG_APP_FILE};\
		fi

remote-actions: remote-deploy
		@\
		H=$$(cat ${CLOUD_HOST_FILE});\
		U=$$(cat ${CLOUD_USER_FILE});\
		if [ "${ACTIONS}" != "" ];then\
			if [ "${APP}" != "${CLOUD_CLI}" ];then\
				MAKE_APP_PATH=${APP_GROUP}/${APP};\
			else\
				MAKE_APP_PATH=${APP_GROUP}/${TOOLS};\
			fi;\
			ssh ${SSHOPTS} $$U@$$H make -C $$MAKE_APP_PATH ${ACTIONS} STORAGE_ACCESS_KEY=${STORAGE_ACCESS_KEY} STORAGE_SECRET_KEY=${STORAGE_SECRET_KEY} ${MAKEOVERRIDES};\
		fi

remote-test-api-in-vpc: ${CLOUD}-instance-get-tagged-hosts
	@if [ -f "${CONFIG_APP_FILE}" ];then\
		U=$$(cat ${CLOUD_USER_FILE});\
		for H in $$(cat ${CLOUD_TAGGED_HOSTS_FILE});do\
			(\
				(\
					((\
						if [ -z "${API_TEST_DATA}" ];then\
							ssh ${SSHOPTS} $$U@$$H "curl --noproxy '*' -s --fail localhost:${PORT}/${API_TEST_PATH}";\
						else\
							echo '${API_TEST_DATA}' | ssh ${SSHOPTS} $$U@$$H "curl --noproxy '*' -s -XPOST --fail localhost:${PORT}/${API_TEST_PATH} -H 'Content-Type: application/json' -d @-";\
						fi;\
					) || (echo "api test on $$H (ssh) localhost:${PORT}/${API_TEST_PATH} : ko" && exit 1))\
					|\
					(\
						if [ ! -z "${API_TEST_JSON_PATH}" ];then\
							(cat | jq -e '.${API_TEST_JSON_PATH}' > /dev/null 2>&1);\
						else\
						(	cat | egrep -v '^api test on.*ko$$' > /dev/null 2>&1);\
						fi;\
					)\
				)\
				&& (echo "api test on $$H (ssh) localhost:${PORT}/${API_TEST_PATH} : ok")\
			) || (echo "api test on $$H (ssh) localhost:${PORT}/${API_TEST_PATH} : ko" && exit 1);\
		done;\
	fi;


local-test-api:
	@(\
		(\
			((\
				if [ -z "${API_TEST_DATA}" ];then\
					curl --noproxy '*' -s --fail localhost:${PORT}/${API_TEST_PATH};\
				else\
					echo '${API_TEST_DATA}' | curl --noproxy '*' -s -XPOST --fail localhost:${PORT}/${API_TEST_PATH} -H 'Content-Type: application/json' -d @-;\
				fi;\
			) || (echo "api test on localhost:${PORT}/${API_TEST_PATH} : ko" && exit 1))\
			|\
			(\
				if [ ! -z "${API_TEST_JSON_PATH}" ];then\
					(cat | jq -e '.${API_TEST_JSON_PATH}' > /dev/null 2>&1);\
				else\
					(cat | egrep -v '^api test on.*ko$$' > /dev/null 2>&1);\
				fi;\
			)\
		)\
		&& (echo "api test on localhost:${PORT}/${API_TEST_PATH} : ok")\
	) || (echo "api test on localhost:${PORT}/${API_TEST_PATH} : ko" && exit 1);

remote-test-api:
	@if [ ! -f "${NGINX_UPSTREAM_APPLIED_FILE}" ];then\
		echo "please make nginx-conf-apply first";\
	else\
		(\
			(\
				((\
					if [ -z "${API_TEST_DATA}" ];then\
						curl -s --fail https://${APP_DNS}/${API_TEST_PATH};\
					else\
						echo '${API_TEST_DATA}' | curl -s -XPOST --fail https://${APP_DNS}/${API_TEST_PATH} -H 'Content-Type: application/json' -d @-;\
					fi;\
				) || (echo "api test on https://${APP_DNS}/${API_TEST_PATH} : ko" && exit 1))\
				|\
				(\
					if [ ! -z "${API_TEST_JSON_PATH}" ];then\
						(cat | jq -e '.${API_TEST_JSON_PATH}' > /dev/null 2>&1);\
					else\
						(cat | egrep -v '^api test on.*ko$$' > /dev/null 2>&1);\
					fi;\
				)\
			)\
			&& (echo "api test on https://${APP_DNS}/${API_TEST_PATH} : ok")\
		) || (echo "api test on https://${APP_DNS}/${API_TEST_PATH} : ko" && exit 1);\
	fi;

remote-install-monitor-nq:
	@if [ ! -z "${NQ_TOKEN}" -a -f "${CONFIG_REMOTE_FILE}" ];then\
		H=$$(cat ${CLOUD_HOST_FILE});\
		U=$$(cat ${CLOUD_USER_FILE});\
		ssh ${SSHOPTS} $$U@$$H "curl -sL https://raw.github.com/nodequery/nq-agent/master/nq-install.sh -o ${APP_GROUP}/${TOOLS}/nq-install.sh";\
		ssh ${SSHOPTS} $$U@$$H "sudo bash ${APP_GROUP}/${TOOLS}/nq-install.sh ${NQ_TOKEN}";\
	fi

# test artillery
test-api-generic:
	export report=reports/`basename ${PERF_SCENARIO} .yml`-${PERF_TEST_ENV}.json ;\
		${DC} -f ${DC_FILE}-artillery.yml run artillery run -e ${PERF_TEST_ENV} -o $${report} scenario.yml; \
		${DC} -f ${DC_FILE}-artillery.yml run artillery report $${report}

#GIT matchid projects section
${GIT_BACKEND}:
	@echo configuring matchID
	@${GIT} clone -q ${GIT_ROOT}/${GIT_BACKEND}
	@cp artifacts ${GIT_BACKEND}/artifacts
	@cp docker-compose-local.yml ${GIT_BACKEND}/docker-compose-local.yml
	@echo "export ES_NODES=1" >> ${GIT_BACKEND}/artifacts
	@echo "export PROJECTS=${PWD}/projects" >> ${GIT_BACKEND}/artifacts
	@echo "export STORAGE_BUCKET=${STORAGE_BUCKET}" >> ${GIT_BACKEND}/artifacts

# tests for automation
remote-config-test:
	@/usr/bin/time -f %e make remote-actions ACTIONS="generate-test-file storage-push" remote-clean ${MAKEOVERRIDES}
