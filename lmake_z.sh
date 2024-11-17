#!/bin/bash
param1=$1
echo $1
echo $param1
echo docker run -v "$(pwd)/:/home/ubuntu/work/" -v "$(pwd)/$param1:/home/ubuntu/work/todo.sh" -it --rm -u ubuntu bbb_amd:0.14
sudo docker run -v "$(pwd)/:/home/ubuntu/work/" -v "$(pwd)/$param1:/home/ubuntu/work/todo.sh" -it --rm -u ubuntu bbb_amd:0.14
