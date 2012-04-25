#!/bin/bash
export EC2_URL=`./get_ec2_url.py $1`
source ../stage01/functions.inc
source ${CTX}
a=0;
while ! r=$(echo -ne "$a\t" >&2; euca-describe-instances ${VMID} | tee /dev/stderr | grep running); do 
  a=$((a+1)); 
  if [ $a -gt ${RECOVERTIMEOUT} ]; then 
    fail $r; 
  fi; 
  sleep 1; 
done

a=0;
while ! RET=$(run euca-describe-keypairs | grep ${KEY}); do
  a=$((a+1)); 
  if [ $a -gt ${RECOVERTIMEOUT} ]; then 
    fail $r; 
  fi; 
  sleep 1; 
done

while ! RET=$(run euca-describe-groups | grep ${GROUP}); do
  a=$((a+1)); 
  if [ $a -gt ${RECOVERTIMEOUT} ]; then 
    fail $r; 
  fi; 
  sleep 1; 
done

while ! RET=$(run euca-describe-images | grep ${EMI}); do
  a=$((a+1)); 
  if [ $a -gt ${RECOVERTIMEOUT} ]; then 
    fail $r; 
  fi; 
  sleep 1; 
done

while ! RET=$(run euca-describe-instances | grep ${VMID}); do
  a=$((a+1)); 
  if [ $a -gt ${RECOVERTIMEOUT} ]; then 
    fail $r; 
  fi; 
  sleep 1; 
done

while ! RET=$(run euca-describe-addresses | grep ${ADDR}); do
  a=$((a+1)); 
  if [ $a -gt ${RECOVERTIMEOUT} ]; then 
    fail $r; 
  fi; 
  sleep 1; 
done

while ! RET=$(run euca-describe-volumes | grep ${VOLUME}); do
  a=$((a+1)); 
  if [ $a -gt ${RECOVERTIMEOUT} ]; then 
    fail $r; 
  fi; 
  sleep 1; 
done


