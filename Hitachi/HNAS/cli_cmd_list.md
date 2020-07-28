### HNAS command list 

diagshowall

for-each-evs nfs-export list

for-each-evs cifs-share list

for-each-evs cifs-saa listall

for-each-evs for-each-fs ssrun -c 'security-mode get -f "$FS_LABEL"'

for-each-evs for-each-fs ssrun -c 'virtual-volume list "$FS_LABEL"'

for-each-evs for-each-fs ssrun -c 'quota list "$FS_LABEL"'

for-each-evs replication-policy-list

for-each-evs replication-schedule-list

for-each-evs replication-history-list --all

df

pn all ifconfig

route

for-each-evs dsb --show-sdg -a

for-each-evs cifs-name list

for-each-evs for-each-fs ssrun -c 'snapshot-list --all --file-system "$FS_LABEL"'

for-each-evs snapshot-rule-list

crontab list


## DM2C Commands
migration-cloud-account-list

migration-cloud-destination-list

for-each-evs for-each-fs ssrun -c 'migration-cloud-policy-list --source-fs-label "$FS_LABEL"'

migration-cloud-rule-list

for-each-evs migration-cloud-schedule-list

