#!/bin/bash

# git-switch.sh: Git 계정 및 SSH 키 전환 스크립트
# 계정 정보 설정
WORK_NAME="rootiron"
WORK_EMAIL="ggg03062@naver.com"
WORK_SSH_KEY="/Users/gray/.ssh/id_ed25519_work"

PERSONAL_NAME="GeunSam2"
PERSONAL_EMAIL="rootiron96@gamil.com"
PERSONAL_SSH_KEY="/Users/gray/.ssh/id_ed25519"

# 함수 정의
switch_to_work() {
    echo "Switching to work account..."
    git config --global user.name "$WORK_NAME"
    git config --global user.email "$WORK_EMAIL"
    ssh-add -D # 모든 키 제거
    ssh-add $WORK_SSH_KEY # 작업용 SSH 키 추가
    echo "Switched to Work account: $WORK_NAME <$WORK_EMAIL>"
}

switch_to_personal() {
    echo "Switching to personal account..."
    git config --global user.name "$PERSONAL_NAME"
    git config --global user.email "$PERSONAL_EMAIL"
    ssh-add -D
    ssh-add $PERSONAL_SSH_KEY
    echo "Switched to Personal account: $PERSONAL_NAME <$PERSONAL_EMAIL>"
}

show_current() {
    echo "Current Git User:"
    git config --global user.name
    git config --global user.email
    echo "Active SSH Keys:"
    ssh-add -l
}

# 사용법 안내
usage() {
    echo "Usage: $0 {rootiron|geunsam2|status}"
    exit 1
}

# 명령어 처리
case "$1" in
    rootiron)
        switch_to_work
        ;;
    geunsam2)
        switch_to_personal
        ;;
    status)
        show_current
        ;;
    *)
        usage
        ;;
esac
