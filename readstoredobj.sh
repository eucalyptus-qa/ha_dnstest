#!/bin/bash
export EC2_URL=`./get_ec2_url.py $1`
./readstoredobj.rb $2
