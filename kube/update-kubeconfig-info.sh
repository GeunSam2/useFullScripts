#!/bin/bash

KUBE_CONFIG="~/.kube/config"

# YAML 파일 수정 함수 정의
update_yaml() {
    local arn_name=$1
    local environment=$2
    local KUBE_CONFIG="$HOME/.kube/config" # 환경에 맞게 수정하세요.

    # yq를 사용하여 YAML 파일 수정
    yq e ".users[] |= (
      select(.name == \"$arn_name\").user.exec.command = \"aws-vault\", 
      select(.name == \"$arn_name\").user.exec.args = [\"exec\", \"daangn/$environment\", \"--\", \"aws\"] + select(.name == \"$arn_name\").user.exec.args
    )" -i $KUBE_CONFIG
}

# aws-vault를 사용하는 alias 대신 사용할 함수 정의
aws_alpha() {
    aws-vault exec daangn/alpha -- aws "$@"
}

aws_prod() {
    aws-vault exec daangn/prod -- aws "$@"
}

update_clusters() {
  local environment=$1
  local region=$2
  local command="aws_$environment"
  local clusters=$($command eks list-clusters --region $region | jq -r '.clusters[]')
  
  echo "# UPDATE ${clusters[@]}"
  echo "."
  for cluster in ${clusters[@]}
  do
	echo "## START $cluster in $region"
    output=$($command eks update-kubeconfig --region $region --name $cluster)
	arn=$(echo $output | grep -o 'arn:aws:eks:[^ ]*')
	echo "### Updated $cluster with ARN: $arn"
    if [[ -n $arn ]]; then
      update_yaml $arn $environment
	  echo "### Updated Yaml."
    fi
	echo "## DONE $cluster in $region"
	echo "."
  done
  echo "# UPDATE DONE"
  echo "---"
}

# 불필요한 kubectl 컨텍스트 삭제
for i in $(kubectl config get-contexts | grep -vE 'docker-desktop|k3d-test|AUTHINFO' | awk '{print $2}')
do
  kubectl config delete-context $i
done

# 함수 사용하여 클러스터 업데이트
update_clusters alpha ap-northeast-2
update_clusters alpha ap-northeast-1
update_clusters alpha ca-central-1
update_clusters alpha eu-west-2

update_clusters prod ap-northeast-2
update_clusters prod ap-northeast-1
update_clusters prod ca-central-1
update_clusters prod eu-west-2