export KETO_WRITE_REMOTE=127.0.0.1:4467

set -x

keto relation-tuple create ./scenario1
keto relation-tuple create ./scenario2
