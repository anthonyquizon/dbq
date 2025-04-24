#! /usr/bin/env bash
cd "$(dirname "$0")"
export TIMEFORMAT='%3R'

if [[ "$@" == *"--expect"* ]]; then
    time diff <(../qbqn -c a.bqn) expect \
        && echo -e "\e[32mPassed\e[0m" || echo -e "\e[31mFail\e[0m"
else 
    time ../qbqn a.bqn
fi
