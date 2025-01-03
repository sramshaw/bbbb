# Beagle Black Bone Build: an Experiment in building Embedded Linux as per [bootlin](https://bootlin.com) 's lab

## Basic context

- based on the documented training from bootlin: [embedded-linux-bbb-labs.pdf](https://bootlin.com/doc/training/embedded-linux-bbb/embedded-linux-bbb-labs.pdf)
- attempt to translate this document into a simpler experiment that carries the lessons forward to the next engineer going through it
    - use ubuntu@sha256:80dd3c3b9c6cecb9f1667e9290b3bc61b78c2678c02cbdae5f0fea92cc6734ab  (digest based pull that guarantees this is always the same)
        - it may be best to use a newer ubuntu when using this on a real project
    - use of a crosstool [crosstool-ng](https://github.com/crosstool-ng/crosstool-ng) that gets installed when building the toolchain
        - especially checkout commit 7622b490
    - the doc mentions configurations, but is not detailed enough to reach success on first try (or it is just me :smile: )
        - now rehydrated based on ct-ng-defconfig
        - I figured the options by hand, not necesserarily minimal yet

## Requirements so far

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

## capture of configurations

- discovering how the kernel needs to be configured to build properly
  - there is some trial and error
  - there is the ?GUI tool? (make config?) to allow choices that end up in a config
  - this is also where saving this config can be done with ?make saveconfig?
    - here several files saved like this:
      - [uboot-defconfic](./uboot-defconfig)
      - [ct-ng-defconfig](/ct-ng-defconfig)
    - these files are then reused to rehydrate a full config

## how the build works currently

- [lmake_toolchain.sh](./lmake_toolchain.sh) is the way to build the toolchain as a container that stays local with the :/ great :/ name **bbb_amd:0.14**
  - this container will be used to build everything else 
- [lmake_uboot.sh](./lmake_uboot.sh) is using the toolchain to build uboot
    - the main magic is to tie the scripted build instructions [build_uboot.sh](./build_uboot.sh) to an expected script file ```/home/ubuntu/work/todo.sh``` that the container will run
    - the current repos' files are all available to the container at a folder ```/home/ubuntu/work/``` 
    - the resulting ```u-boot.img``` file is then found at ```./modules/u-boot/```
- [lmake_linux.sh](./lmake_linux.sh) is using the toolchain to build linux
    - same with [build_linux.sh](./build_linux.sh)
    - the resulting output file ```zimage```  is found at ```./modules/linux/arch/arm/boot/```
