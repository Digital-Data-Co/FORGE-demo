#!/bin/bash
now=$(date +"%m%d%Y")
zip -r /root/scc_$now.zip /root/scc/Sessions/
sshpass -p tSpLUmPzpp8R6ox9cUW1Oczbi/i19ebI scp /root/scp_$now.zip scopedevvram.scopedevvram@scopedevvram.blob.core.usgovcloudapi.net:/
rm -rf /root/SCC/Sessions/20*
rm -rf /root/SCC/*.zip

