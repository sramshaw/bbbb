
- [Beagle Bone Black Build: minimum dev setup for building Embedded Linux as per bootlin 's lab](#beagle-bone-black-build-minimum-dev-setup-for-building-embedded-linux-as-per-bootlin-s-lab)
  - [1. Intro](#1-intro)
  - [2. Basic context](#2-basic-context)
  - [3. Requirements so far](#3-requirements-so-far)
  - [4. Trial and error, capture of configurations](#4-trial-and-error-capture-of-configurations)
  - [5. How the build works currently](#5-how-the-build-works-currently)


# Beagle Bone Black Build: minimum dev setup for building Embedded Linux as per [bootlin](https://bootlin.com) 's lab

## 1. Intro

The idea of this POC around this [beagle bone bootlin lab](https://bootlin.com/doc/training/embedded-linux-bbb/embedded-linux-bbb-labs.pdf) is to setup a simple build approach that is light in terms of preparation of the dev machine.

First, a docker container image is built that holds the ARM cross compilation toolchain.
The tools required for building the system modules (u-boot and linux) are for now also included in this container image, but could easily be separated out where both modules could have their own specialized container image based off of the toolchain container image.

Second, for each module targeted, there is a script that runs in WSL2 from within the repo root folder (lmake_*.sh), usually from vscode, and creates a short-lived containers combining the toolchain container image with access to the module's repo and a script of how to rehydrate the configuration before launching make in the module's repo root folder.
The resulting build output is therefore accessible outside of the container in the module's repo in vscode/WSL2.

As a result there is virtually no installation needed in the WSL2 environment, WSL2 is simply used to map folders into the containers via docker CLI. Note that attempting to use Windows + powershell to run the same docker CLI commands did fail on what I suppose are filesystem related limitations, hence the need for WSL2 to launch the containers.
Of course the build happens mainly from within a container that relies on docker on top of WSL2, so WSL2 is essential here.
WSL2 has minimum customization.

Along the way, the setup of configurations before the build is also an unsavory part of business (see menuconfig references in the lab's documentation), better avoided using files rather than manual configuration tools. Hence the use of ```savedefconfig```.

## 2. Basic context

- based on the documented training from bootlin: [embedded-linux-bbb-labs.pdf](https://bootlin.com/doc/training/embedded-linux-bbb/embedded-linux-bbb-labs.pdf)
- attempt to translate this document into a simpler experiment that carries the lessons forward to the next engineer going through it
    - use ubuntu@sha256:80dd3c3b9c6cecb9f1667e9290b3bc61b78c2678c02cbdae5f0fea92cc6734ab  (digest based pull that guarantees this is always the same)
        - it may be best to use a newer ubuntu when using this on a real project
    - use of a crosstool [crosstool-ng](https://github.com/crosstool-ng/crosstool-ng) that gets installed when building the toolchain
        - especially checkout commit 7622b490
    - the doc mentions configurations, but is not detailed enough to reach success on first try (or it is just me :smile: )
        - now rehydrated based on ct-ng-defconfig
        - I figured the options by hand, not necesserarily minimal yet

## 3. Requirements so far

- install Docker Desktop on a Windows laptop
- use docker/WSL2 (aka docker over WSL2) for running vscode
  - there were build issues with docker/Windows, failing the build
- install the vscode extension ```ms-vscode-remote.vscode-remote-extensionpack``` , in particular the ```ms-vscode-remote.remote-wsl``` extension will be used to open this repo in WSL
- be aware of the git submodules to other repositories
  - after cloning this repo, rehydrate the submodules if not done during clone
    - preferred: clone and pull submodules: ```git clone --recurse-submodules -j8 <repo>```
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

## 4. Trial and error, capture of configurations

- discovering how the kernel needs to be configured to build properly
  - see below how to enter a console on the container that has the cross compilation tool installed
  - there is some trial and error involved to change the config for a good build
  - example 1: for the cross compiler config,
    -  use of menuconfig:
    ```
    cd /home/ubuntu/crosstool-ng/
    ./ct-ng menuconfig
    <make changes as per lab and save>
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
  - example 2: for the linux kernel configuration
    -  use of menuconfig
    ```
    cd /home/ubuntu/work/modules/linux/
    make menuconfig
    <make changes as per lab and save>
    make savedefconfig
    mv defconfig <bettername for storing>
    ``` 
    - and vice versa to use the stored config
    ```
    cd /home/ubuntu/work/modules/linux/
    mv <bettername for storing> ./.config
    yes "" | make oldconfig

    ``` 
  
  - practical use of this in this repo
    - here several files saved like this:
      - [uboot-defconfic](./uboot-defconfig)
      - [ct-ng-defconfig](/ct-ng-defconfig)
    - these files are then reused to rehydrate a full config 
- the best way to get a console into the toolchain environment with access to the 2 projects that we could build, u-boot and linux (kernel)
  - (achieved by using docker from within the following, which maps the ```./modules``` folder to the container's ```/home/ubuntu/work/``` folder )
  - launch the console using the following script in a vscode terminal: [./lmake_explore_toolchain.sh](./lmake_explore_toolchain.sh) 
    - you now have access to the 

## 5. How the build works currently

- [lmake_toolchain.sh](./lmake_toolchain.sh) is the way to build the toolchain in a vscode WSL2 terminal as a container image
  - today it is built as a local only container image with the :sweat_smile:great:sweat_smile: name **bbb_amd:0.14**
  - this container will then be used to build everything else 
- [lmake_uboot.sh](./lmake_uboot.sh) is using the toolchain container image to build uboot in a vscode WSL2 terminal
    - the main magic is to tie the scripted build instructions [build_uboot.sh](./build_uboot.sh) to an expected script file ```/home/ubuntu/work/todo.sh``` that the container will run
    - the current repos' files are all available to the container at a folder ```/home/ubuntu/work/``` 
    - the resulting ```u-boot.img``` file is then found at ```./modules/u-boot/```
- [lmake_linux.sh](./lmake_linux.sh) is using the toolchain container image to build linux in a vscode WSL2 terminal
    - same with [build_linux.sh](./build_linux.sh)
    - the resulting output file ```zimage```  is found at ```./modules/linux/arch/arm/boot/```
