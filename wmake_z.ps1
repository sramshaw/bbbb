$param1=$args[0]
docker run -v "$((Get-Item .).FullName)/:/home/ubuntu/work" -v "$((Get-Item .).FullName)/$($param1):/home/ubuntu/work/todo.sh" -it --rm -u ubuntu bbb_amd:0.14
