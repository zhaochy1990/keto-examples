
export KETO_READ_REMOTE=127.0.0.1:4466

set -x

keto check /user/Bob Read rc /device/001

keto check /user/Bob Update rc /device/002

keto check /user/Bob Update rc /device/003

