# Results files
CSV_FILE_BMK1 ?= /tmp/npm_test_full.csv
CSV_FILE_BMK2 ?= /tmp/npm_test_loops.csv

# Loops control
BMK2_ITERATIONS ?= 20
PROXIES ?= envoy haproxy nginx traefik
NPM_TEST_DELAYS ?= 0 0.25 0.5 1
EXPECTED_RESULTS ?= 90 18 270 36 450 900 180 2700 360 4500             # 2 SLAs - 3 API keys per SLA - 3/3/30
#EXPECTED_RESULTS ?= 9 12 27 24 45 90 120 270 240 450				    # 2 SLAs - 3 API keys per SLA - 3/2/3
#EXPECTED_RESULTS ?= 120 24 360 48 600 1200 240 3600 480 6000           # 4 SLAs - 2 API keys per SLA - 3/3/30
#EXPECTED_RESULTS ?= 180 36 540 72 900 1800 360 5400 720 9000           # 6 SLAs - 2 API keys per SLA - 3/3/30
#EXPECTED_RESULTS ?= 270 54 810 108 1350 2700 540 8100 1080 13500       # 6 SLAs - 3 API keys per SLA - 3/3/30
#EXPECTED_RESULTS ?= 240 48 720 96 1200 2400 480 7200 960 12000         # 8 SLAs - 2 API keys per SLA - 3/3/30
#EXPECTED_RESULTS ?= 480 96 1440 192 2400 4800 960 14400 1920 24000     # 8 SLAs - 4 API keys per SLA - 3/3/30

# npm test configurations
NT_TEST_CONFIG ?= ../sla-gateway-benchmark/config/basicTestConfig.yaml
NT_OAS4TEST ?= ../sla-gateway-benchmark/specs/simple_api_oas.yaml
NT_SLAS_PATH ?= ../sla-gateway-benchmark/specs/slas/
AUTH_LOCATION ?= header

# Docker-compose files prr proxy (in case that you want to modify)
DOCKER_COMPOSE_ENVOY ?= proxies/envoy/docker-compose-envoy.yaml
DOCKER_COMPOSE_HAPROXY ?= proxies/haproxy/docker-compose-haproxy.yaml
DOCKER_COMPOSE_NGINX ?= proxies/nginx/docker-compose-nginx.yaml
DOCKER_COMPOSE_TRAEFIK ?= proxies/traefik/docker-compose-traefik.yaml


### DO NOT MODIFY BELOW HERE
BMK2_TEST_CFG ?= /tmp/basicTestConfig.yaml

benchmark_1:

	@ if [ "${SLA_WIZARD_PATH}" = "" ]; then \
		echo "SLA_WIZARD_PATH not set"; \
		exit 1; \
	fi

# 	@ echo "Proxy,[basic] GET /pets - 1/s,[basic] POST /pets - 2/m,[basic] GET /pets/id - 3/s,[basic] PUT /pets/id - 4/m,[basic] DELETE /pets/id - 5/s,\
# 	[pro] GET /pets - 10/s,[pro] POST /pets - 20/m,[pro] GET /pets/id - 30/s,[pro] PUT /pets/id - 40/m,[pro] DELETE /pets/id - 50/s" > ${CSV_FILE_BMK1}

	@ node ${SLA_WIZARD_PATH}/scripts/generate_csv_header.js \
		--sla ${NT_SLAS_PATH} \
		--test ${NT_TEST_CONFIG} \
		--out ${CSV_FILE_BMK1}


	@ for proxy in ${PROXIES}; do \
		if [ "$$proxy" = "envoy" ]; then \
			COMPOSE_FILE=${DOCKER_COMPOSE_ENVOY}; \
		elif [ "$$proxy" = "haproxy" ]; then \
			COMPOSE_FILE=${DOCKER_COMPOSE_HAPROXY}; \
		elif [ "$$proxy" = "nginx" ]; then \
			COMPOSE_FILE=${DOCKER_COMPOSE_NGINX}; \
		elif [ "$$proxy" = "traefik" ]; then \
			COMPOSE_FILE=${DOCKER_COMPOSE_TRAEFIK}; \
		fi; \
		echo "#########################################################################" ; \
		echo "# Creating proxy configuration file with sla-wizard for $$proxy" ; \
		node ${SLA_WIZARD_PATH}/src/index.js config --authLocation ${AUTH_LOCATION} $$proxy \
			--oas ${NT_OAS4TEST} \
			--sla ${NT_SLAS_PATH} \
			--outFile /tmp/proxy-configuration-file ; \
		echo "...DONE" ; \
		echo "# Starting containerized test bed based on Docker-Compose" ; \
		if [ "$$proxy" = "traefik" ]; then \
			D_CFG_PATH=/tmp/proxy-configuration-file CFG_PATH=./traefik.yaml docker-compose \
				--file $$COMPOSE_FILE up \
				--detach ; \
		else \
			CFG_PATH=/tmp/proxy-configuration-file docker-compose \
				--file $$COMPOSE_FILE up \
				--detach ; \
		fi > /dev/null 2>&1 ; \
		sleep 4 # Wait until containers are ready and launch test ; \
		echo "...DONE" ; \
		echo "# Running tests with sla-wizard's 'npm test'" ; \
		TEST_CONFIG=${NT_TEST_CONFIG} \
		OAS4TEST=${NT_OAS4TEST} \
		SLAS_PATH=${NT_SLAS_PATH} \
		npm --prefix ${SLA_WIZARD_PATH} test > /tmp/npm_test_logs ; \
		echo "...DONE" ; \
		echo "# Tearing down test bed" ; \
		CFG_PATH=/tmp/proxy-configuration-file docker-compose --file $$COMPOSE_FILE down > /dev/null 2>&1 ; \
		echo "...DONE" ; \
		echo -n $$proxy, >> ${CSV_FILE_BMK1} ; \
		for expected in ${EXPECTED_RESULTS}; do \
			cat /tmp/npm_test_logs | grep "to equal $$expected$$" | sed 's/to equal/instead of/g' | sed 's/AssertionError: expected/Got/g' > /tmp/auxFileBMK1 ; \
			result=$$(cat /tmp/auxFileBMK1); \
			echo -n $$result, >> ${CSV_FILE_BMK1} ; \
		done ; \
		echo >> ${CSV_FILE_BMK1} ; \
	done ; \


benchmark_2:

	@ if [ "${SLA_WIZARD_PATH}" = "" ]; then \
		echo "SLA_WIZARD_PATH not set"; \
		exit 1; \
	fi

	@ echo "authLocation: ${AUTH_LOCATION}" > ${BMK2_TEST_CFG} ; \
	echo "extraRequests: 2" >> ${BMK2_TEST_CFG} ; \
	echo "secondsToRun: 3" >> ${BMK2_TEST_CFG} ; \

	@ echo "Proxy,Sleep 0s,Sleep 0.25s,Sleep 0.5s,Sleep 1s" > ${CSV_FILE_BMK2} ; \

	@ for proxy in ${PROXIES}; do \
		if [ "$$proxy" = "envoy" ]; then \
			COMPOSE_FILE=${DOCKER_COMPOSE_ENVOY}; \
		elif [ "$$proxy" = "haproxy" ]; then \
			COMPOSE_FILE=${DOCKER_COMPOSE_HAPROXY}; \
		elif [ "$$proxy" = "nginx" ]; then \
			COMPOSE_FILE=${DOCKER_COMPOSE_NGINX}; \
		elif [ "$$proxy" = "traefik" ]; then \
			COMPOSE_FILE=${DOCKER_COMPOSE_TRAEFIK}; \
		fi; \
		node ${SLA_WIZARD_PATH}/src/index.js config --authLocation ${AUTH_LOCATION} $$proxy \
			--oas ${NT_OAS4TEST} \
			--sla ${NT_SLAS_PATH} \
			--outFile /tmp/proxy-configuration-file ; \
		if [ "$$proxy" = "traefik" ]; then \
			D_CFG_PATH=/tmp/proxy-configuration-file CFG_PATH=./traefik.yaml docker-compose \
				--file $$COMPOSE_FILE up \
				--detach ; \
		else \
			CFG_PATH=/tmp/proxy-configuration-file docker-compose \
				--file $$COMPOSE_FILE up \
				--detach ; \
		fi ; \
		sleep 4 # Wait until containers are ready and launch test ; \
		for sleep_time in ${NPM_TEST_DELAYS}; do \
			for iteration in $$( seq 1 ${BMK2_ITERATIONS} ); do \
				TEST_CONFIG=${BMK2_TEST_CFG} \
				OAS4TEST=${NT_OAS4TEST} \
				SLAS_PATH=${NT_SLAS_PATH} \
				npm --prefix ${SLA_WIZARD_PATH} test ; \
				sleep $$sleep_time; \
			done | grep "to equal 600\|Received 200s: 600" | sed 's/.*AssertionError: expected //g' | sed 's/ to equal 600//g' | sed 's/Received 200s: //g' > /tmp/test_sleep$$sleep_time-$$proxy ; \
		done ; \
		CFG_PATH=/tmp/proxy-configuration-file docker-compose --file $$COMPOSE_FILE down ; \
		for iteration in $$( seq 1 ${BMK2_ITERATIONS} ); do \
			echo -n $$proxy, >> ${CSV_FILE_BMK2} ; \
			for sleep_time in ${NPM_TEST_DELAYS}; do \
				echo -n $$(head -$$iteration /tmp/test_sleep$$sleep_time-$$proxy | tail +$$iteration), >> ${CSV_FILE_BMK2} ; \
			done ; \
			echo >> ${CSV_FILE_BMK2} ; \
		done ; \
	done ; \