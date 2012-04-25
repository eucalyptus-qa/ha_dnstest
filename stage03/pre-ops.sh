#!/bin/bash
source ../stage01/functions.inc

# hi=$(run /bin/true)
# echo $?:$hi
log "Generating key pair"
KEYFILE=${STATE}/hihi.priv
KEY=hihi
if ! RET=$(run euca-add-keypair ${KEY}); then
	fail "${RET}"
else
	echo "${RET}" | tee ${KEYFILE}
	echo $(run euca-describe-keypairs ${KEY})
fi
endlog

log "Creating security group"
GROUP=baibai
if ! RET=$(run euca-add-group ${GROUP} -d "test group"); then
	fail "${RET}"
else
	echo "${RET}"
	run euca-authorize -P tcp -p 22 -s 0.0.0.0/0 ${GROUP}
	run euca-authorize -P icmp -t -1:-1 -s 0.0.0.0/0 ${GROUP}
fi
endlog


log "Registering new EMI"
if ! RET=$(run euca-describe-images | awk '/emi-/{print $3}'); then
	fail "${RET}"
else
	echo "${RET}"
	MANIFEST="${RET}"
	if ! RET=$(run euca-register ${MANIFEST}); then
		fail "${RET}"
	else
		EMI=$(echo "${RET}" | awk '{print $2}')
		if ! RET=$(run euca-describe-images ${EMI}); then
			fail "${RET}"
		fi
	fi
fi
endlog

log "Running an instance"
if ! RET=$(run euca-run-instances -k ${KEY} -g ${GROUP} ${EMI}); then
	fail "${RET}"
else
	echo "${RET}"
	VMID=$(echo "${RET}" | awk '/INSTANCE/{print $2}')
	echo $(run euca-describe-instances)
fi
endlog

log "Associating an address"
if ! RET=$(run euca-allocate-address); then
	fail "${RET}"
else
	echo "${RET}"
	ADDR=$(echo "${RET}" | awk '{print $2}') 
	if ! RET=$(run euca-associate-address -i ${VMID} ${ADDR}); then
		fail "${RET}"
	fi
fi
endlog
ZONE=$(euca-describe-availability-zones | head -n1 | awk '{print $2}')
#ZONE=$(euca-describe-instances --debug 2>&1 | grep availabilityZone | sed 's/.*availabilityZone>\(.*\)<\/availabilityZone.*/\1/g')
log "Attaching a volume"
if ! RET=$(run euca-create-volume --size 1 -z ${ZONE}); then
	fail "${RET}"
else
	echo "${RET}"
	VOLUME=$(echo "${RET}" | awk '{print $2}')
        a=0;
        while ! r=$(echo -ne "$a\t" >&2; euca-describe-volumes ${VOLUME} | tee /dev/stderr | grep available); do 
          a=$((a+1)); 
          if [ $a -gt ${VOLUMETIMEOUT} ]; then 
            break; 
          fi; 
          sleep 1; 
        done
	if ! RET=$(run euca-attach-volume -i ${VMID} -d /dev/sdb ${VOLUME}); then
		fail "${RET}"
	else
		echo "${RET}"
	fi
fi
endlog

while ! r=$(echo -ne "$a\t" >&2; euca-describe-instances ${VMID} | tee /dev/stderr | grep running); do 
  a=$((a+1)); 
  if [ $a -gt ${VMTIMEOUT} ]; then 
    break; 
  fi; 
  sleep 1; 
done

echo "
export KEY=${KEY}
export GROUP=${GROUP}
export EMI=${EMI}
export VMID=${VMID}
export ADDR=${ADDR}
export VOLUME=${VOLUME}
" | tee ${CTX}
