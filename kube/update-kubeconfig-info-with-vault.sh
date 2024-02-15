#!/bin/bash

# ~/.kube/config 환경 설정
KUBE_CONFIG="$HOME/.kube/config"

# YAML 파일 수정 함수 정의
update_yaml() {
    local arn_name=$1
    local environment=$2

    # yq를 사용하여 YAML 파일 수정
    yq e ".users[] |= (
      select(.name == \"$arn_name\").user.exec.command = \"aws-vault\", 
      select(.name == \"$arn_name\").user.exec.args = [\"exec\", \"daangn/$environment\", \"--\", \"aws\"] + select(.name == \"$arn_name\").user.exec.args
    )" -i "$KUBE_CONFIG"

    echo "## $arn_name 프로필 aws-vault 설정 완료"
}

# aws-vault 실행 함수 정의
aws_vault_exec() {
    local profile=$1
    local command=$2
    aws-vault exec daangn/"$profile" -- $command
}

# 클러스터 업데이트 함수
update_clusters() {
  local environment=$1
  local region=$2
  echo "###-----------------------------###"
  echo "## $environment 환경의 $region 리전 config 업데이트 시작"
  
  local clusters=$(aws_vault_exec "$environment" "aws eks list-clusters --region $region" | jq -r '.clusters[]')
  
  for cluster in $clusters; do
    echo "#"
    echo "# $cluster config 업데이트 시작"
    
    local output=$(aws_vault_exec "$environment" "aws eks update-kubeconfig --region $region --name $cluster")
    local arn=$(echo "$output" | grep -o 'arn:aws:eks:[^ ]*')
    
    if [[ -n $arn ]]; then
      update_yaml "$arn" "$environment"
    fi

    echo "# $cluster config 업데이트 완료"
    echo "# 등록된 context 이름 : $arn"
    echo "#"
  done
  echo "## $environment 환경의 $region 리전 config 업데이트 완료"
  echo "###-----------------------------###"
}

# kubectl 컨텍스트 정리 함수
delete_kubectl_contexts() {
  local exclude_contexts=("docker-desktop" "k3d-test" "AUTHINFO")
  local exclude_pattern=$(IFS="|"; echo "${exclude_contexts[*]}")
  
  local contexts_to_delete=$(kubectl config get-contexts -o name | grep -Ev "$exclude_pattern")
  
  if [[ -z "$contexts_to_delete" ]]; then
    echo "삭제할 컨텍스트가 없습니다."
    return
  fi

  echo "다음 컨텍스트가 삭제될 예정입니다:"
  echo "$contexts_to_delete"

  read -p "리얼루 이 컨텍스트들을 정말 삭제하시겠습니까? (y/n): " reply
  if [[ $reply =~ ^[Yy]$ ]]; then
    echo "$contexts_to_delete" | while read context; do
      kubectl config delete-context "$context" > /dev/null
      echo "삭제한 context: $context"
    done
    echo "컨텍스트 정리가 완료되었습니다."
  else
    echo "컨텍스트 삭제를 스킵합니다."
  fi
}

# 메인 실행 조건
if [[ "$1" == "--clear-contexts" ]]; then
  delete_kubectl_contexts
else
  echo "컨텍스트 정리를 skip합니다. '--clear-contexts' 옵션을 사용하세요."
fi

# 클러스터 업데이트 실행
update_clusters alpha ap-northeast-2
update_clusters alpha ap-northeast-1
update_clusters alpha ca-central-1
update_clusters alpha eu-west-2

update_clusters prod ap-northeast-2
update_clusters prod ap-northeast-1
update_clusters prod ca-central-1
update_clusters prod eu-west-2
