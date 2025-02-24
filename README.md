# Beagle Bone Black Build: minimum dev setup for Embedded Linux build
As per [bootlin](https://bootlin.com) 's lab , great job that deserved this little bit of TLC below.

The idea of this POC around the [beagle bone bootlin lab](https://bootlin.com/doc/training/embedded-linux-bbb/embedded-linux-bbb-labs.pdf) is to setup a simple build approach that is light and reproducible on any dev machine, based on the use of docker (no license required).
It is still possible to have an open console on a linux where the toolchain is readily available, though on a temporary container instead of WSL2.


__Table of Contents:__
- [Beagle Bone Black Build: minimum dev setup for Embedded Linux build](#beagle-bone-black-build-minimum-dev-setup-for-embedded-linux-build)
  - [1. What you will find in this demo](#1-what-you-will-find-in-this-demo)
  - [2. Main changes compared to the original bootlin lab](#2-main-changes-compared-to-the-original-bootlin-lab)
  - [3. Minimal dev machine setup](#3-minimal-dev-machine-setup)
    - [3.1 Tools](#31-tools)
    - [3.2 Repo (on WSL2)](#32-repo-on-wsl2)
  - [4. Steps to properly configre the various sub-repos](#4-steps-to-properly-configre-the-various-sub-repos)
    - [4.1 Enter a console that has the toolchain](#41-enter-a-console-that-has-the-toolchain)
    - [4.2 Tweak the configurations](#42-tweak-the-configurations)
    - [4.3 Example: the cross compiler config,](#43-example-the-cross-compiler-config)
    - [4.4 Example: the linux kernel configuration](#44-example-the-linux-kernel-configuration)
    - [4.4 In practice, list of defconfig files](#44-in-practice-list-of-defconfig-files)
  - [5. Current build scripts](#5-current-build-scripts)
    - [5.1 building the cross compilation ARM tool chain](#51-building-the-cross-compilation-arm-tool-chain)
    - [5.2 building u-boot](#52-building-u-boot)
    - [5.3 building a custom linux kernel](#53-building-a-custom-linux-kernel)
    - [5.4 building all](#54-building-all)


## 1. What you will find in this demo

First, a docker container image is built that holds the ARM cross compilation toolchain.
The tools required for building the system modules (u-boot and linux) are for now also included in this container image, but could easily be separated out where both modules could have their own specialized container image based off of the toolchain container image.

Second, for each module targeted, there is a script that runs in WSL2 from within the repo root folder (```lmake_<module name>.sh```), usually from vscode, and creates a short-lived containers combining the toolchain container image with access to the module's repo and a script rehydrating the build configuration before launching ```make``` in the module's repo root folder.
The resulting build output is accessible outside of the container in vscode/WSL2 at ```./modules/<module name>```.

There is no installation needed in the WSL2 environment, WSL2 is simply used to map folders into the containers via docker CLI. Note that attempting to use Windows + powershell to run the same docker CLI commands did fail on what I suppose are filesystem related limitations, hence the need for WSL2 to launch the containers.
Of course the build happens mainly from within a container that relies on docker on top of WSL2, so WSL2 is essential here.

Along the way, the setup of builds' configurations is also sometimes difficult (see ```menuconfig``` references in the lab's documentation), we will see how to do it manually once and leverage it with possible upgrades using ```savedefconfig``` and ```oldconfig```.

## 2. Main changes compared to the original [bootlin](https://bootlin.com) lab

- based on the documented training from bootlin: [embedded-linux-bbb-labs.pdf](https://bootlin.com/doc/training/embedded-linux-bbb/embedded-linux-bbb-labs.pdf)
- attempt to translate this document into a simpler experiment that carries the lessons forward to the next engineer going through it
    - use of digest for the container used, for reproductibility's  sake 
      - ubuntu@sha256:80dd3c3b9c6cecb9f1667e9290b3bc61b78c2678c02cbdae5f0fea92cc6734ab
        - it may be best to use a newer ubuntu when using this on a real project
    - use of a crosstool [crosstool-ng](https://github.com/crosstool-ng/crosstool-ng) that gets installed when building the toolchain
        - especially checkout commit 7622b490
    - the doc mentions configurations, but is not detailed enough to reach success on first try (or it is just me :smile: )
        - now configs are automatically rehydrated based on ```ct-ng-defconfig``` or ```<module name>-defconfig```
        - I figured the options by hand, not necesserarily minimal yet. IIRC the kernel config was tough for a newbee, one option seemed ever elusive and took 1h to find.

## 3. Minimal dev machine setup

### 3.1 Tools
- install WSL2
- install Docker Desktop on a Windows laptop, or directly in WSL2: ```sudo snap install docker ```
- install vscode
- install the vscode extension ```ms-vscode-remote.vscode-remote-extensionpack``` , in particular the ```ms-vscode-remote.remote-wsl``` extension will be used to open this repo in WSL
  - use docker/WSL2 (aka docker over WSL2) for opening this repo , + shell scripts
  - in contrast to running from docker/Windows + powershell scripts, which fail for equivalent script content (docker CLI)

### 3.2 Repo (on WSL2)

- clone this repo and be aware of the git submodules to other repositories
  - after cloning this repo, rehydrate the submodules if not done during clone
    - preferred: clone and pull submodules at the same time: ```git clone --recurse-submodules -j8 <repo>```
    - after the fact: ```git submodule update --init --recursive```
  - note also that you can make shallow clones, in our case it is the stable releases of linux that are cloned
  - see the repos linked using command ``` cat .gitmodules ```, the last output was:
  > [submodule "modules/u-boot"]  
        path = modules/u-boot  
        url = https://gitlab.denx.de/u-boot/u-boot  
[submodule "modules/linux"]  
        path = modules/linux  
        url = https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux
  - see the latest checkout for the submodules using the command ```git submodule status``` , the last output was:
   > d98fd109f8279feabed326ecd98923fa9b7affca modules/linux (v5.15.172)  
 e092e3250270a1016c877da7bdd9384f14b1321e modules/u-boot (v2022.07)

## 4. Steps to properly configre the various sub-repos

It is common to have to configure the builds as the repos can support multiple architectures.
Trial and error is bound to happen at this stage if following the lab pdf, as versions evolve. The menu are not always straightforward, though the lab makes the objective clear.
We need a way to experiment with the manual config with menuconfig from within the build environment.

### 4.1 Enter a console that has the toolchain
The easiest way to enter a console session in a container based on the toolchain container image is:
- launch the console using the following script in a vscode terminal: ```./lmake_explore_toolchain.sh``` 

### 4.2 Tweak the configurations
  - you now have access to the crosscompilation toolchain repo, and its configuration
    - repo: /home/ubuntu/crosstool-ng/
    - the  ```dockerfile``` uses the configuration (rehydrated) to build the toolchain 
  - you now have access to the modules ' repos, and can enter menuconfig to modify their configs
    - repo: /home/ubuntu/work/modules/linux/
    - the scripts ```scripts_for_container/build_<module name>.sh``` uses the configuration (once rehydrated) to build the repo  
    - note that the container has access due to folder mapping of host (WSL2) 's ```./modules``` folder to the container's ```/home/ubuntu/work/modules/``` folder

### 4.3 Example: the cross compiler config,
-  use of menuconfig:
```
cd /home/ubuntu/crosstool-ng/
./ct-ng menuconfig
<make changes as per lab and save>
<verify that the expected properties are set in the .config file , if not go back to the menuconfig step>
./ct-ng savedefconfig
mv defconfig <bettername for storing>
``` 
  - man page for [ct-ng savedefconfig](https://man.archlinux.org/man/ct-ng.1.en#savedefconfig)
- and vice versa to use the stored config
```
cd /home/ubuntu/crosstool-ng/
mv <bettername for storing> ./.config
yes "" | ./ct-ng oldconfig
``` 
### 4.4 Example: the linux kernel configuration
-  use of menuconfig
```
cd /home/ubuntu/work/modules/linux/
make menuconfig
<make changes as per lab and save>
<verify that the expected properties are set in the .config file , if not go back to the menuconfig step>
make savedefconfig
mv defconfig <bettername for storing>
``` 
- and vice versa to use the stored config
```
cd /home/ubuntu/work/modules/linux/
mv <bettername for storing> ./.config
yes "" | make oldconfig

``` 
### 4.4 In practice, list of defconfig files   
- [defconfigs/uboot-defconfig](./defconfigs/uboot-defconfig)
- [defconfigs/linux-defconfig](./defconfigs/linux-defconfig)
- [defconfigs/ct-ng-defconfig](./defconfigs/ct-ng-defconfig)

## 5. Current build scripts
### 5.1 building the cross compilation ARM tool chain
- ```./lmake_toolchain.sh``` to build the toolchain in a vscode WSL2 terminal as a container image
  - today it is built as a local only container image with the :sweat_smile:great:sweat_smile: name **bbb_amd:0.14**
  - this container will then be used to build everything else 

### 5.2 building u-boot

- ```./lmake_uboot.sh``` is using the toolchain container image to build uboot in a vscode WSL2 terminal
    - the main magic is to map the scripted build instructions [build_uboot.sh](./scripts_for_container/build_uboot.sh) as an expected script file ```/home/ubuntu/work/todo.sh``` that the container will run
    - the current repos' files are all available to the container at a folder ```/home/ubuntu/work/``` 
    - the resulting ```u-boot.img``` file is then found at ```./modules/u-boot/```

### 5.3 building a custom linux kernel
- ```./lmake_linux.sh``` is using the toolchain container image to build linux in a vscode WSL2 terminal
    - same with [build_linux.sh](./scripts_for_container/build_linux.sh)
    - the resulting output file ```zimage```  is found at ```./modules/linux/arch/arm/boot/```

### 5.4 building all
- ```./lmake_all.sh``` runs the other scripts mentioned above in the order: toolchain, u-boot, linux
