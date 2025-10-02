#!/bin/bash
set -e

# Проверка обязательных переменных
if [[ -z ${YC_TOKEN} ]]; then
	echo "Error: YC_TOKEN must be set"
	exit 1
fi

yc config set token "${YC_TOKEN}"
yc iam whoami # initialize yc

exec /bin/terraform "$@"
