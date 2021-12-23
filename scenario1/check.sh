
export KETO_READ_REMOTE=127.0.0.1:4466

set -x
 
keto check /user/zhangsan view rc /asset/a_02
keto check /user/zhangsan view rc /asset/a_01
keto check /user/zhangsan view rc /device/dev_01
