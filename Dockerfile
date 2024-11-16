FROM ubuntu
RUN apt update && apt dist-upgrade -y  
# rsync needed for kernels v5.3+
# wget needed for ./ct-ng build , as per https://github.com/crosstool-ng/crosstool-ng/issues/1482
# sudo just in case, as cannot produce the toolchain as root, so need to use user ubuntu
 
RUN apt install build-essential git autoconf bison flex texinfo help2man gawk libtool-bin libncurses5-dev unzip rsync sudo wget -y
RUN echo  $USER_GID $USERNAME $USER_UID
 
ARG USERNAME=ubuntu
RUN echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME
 
USER $USERNAME
WORKDIR /home/ubuntu/
RUN git clone https://github.com/crosstool-ng/crosstool-ng
WORKDIR /home/ubuntu/crosstool-ng/
RUN git checkout 7622b490
RUN ./bootstrap
RUN ./configure --enable-local
RUN make
COPY ./ct-ng-defconfig /home/ubuntu/crosstool-ng/.config
RUN yes "" | ./ct-ng oldconfig
RUN ./ct-ng build.20
RUN sudo apt install -y libssl-dev device-tree-compiler swig python3-dev
RUN echo 'export PATH="$HOME/x-tools/arm-training-linux-uclibcgnueabihf/bin:$PATH"' >> ~/.bash_profile 
RUN echo 'export CROSS_COMPILE="arm-linux-"'                                        >> ~/.bash_profile
RUN echo 'export ARCH="arm"'                                                        >> ~/.bash_profile
#RUN chmod +x ~/.bash_profile
WORKDIR /home/ubuntu/work/

ENTRYPOINT [ "/bin/bash", "-c", "source /home/ubuntu/.bash_profile && /home/ubuntu/work/todo.sh" ]
