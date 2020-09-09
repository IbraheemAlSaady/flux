#!/bin/bash

BOLD='\033[1;37m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

targets=$(find . -name kustomization.yaml)

echo ""
echo -e "${BOLD}Checking Kustomize configurations${NC}"
echo "---------------------------------"
echo ""

printf "${BOLD}%-100s%-10s${NC}\n" "Directory" "Status"
printf "%-100s%-10s\n" "---------" "------"

for target in $targets
do
  directory=$(dirname "$target")
  printf "%-100s" "$directory"
  kustomize build --load_restrictor none "$directory" > /dev/null 2>&1
  if [ $? -eq 0 ]
  then
    printf "${GREEN}%-10s${NC}" "ok"
  else
    printf "${RED}%-10s${NC}" "errpr"
  fi
  printf "\n"
done
