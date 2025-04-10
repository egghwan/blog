---
title: "Petalinux Build Demo (Zybo-z7-10)"
description: ""
icon: "code"
date: "2023-05-22T00:44:31+01:00"
lastmod: "2023-05-22T00:44:31+01:00"
draft: false
toc: true
weight: 210
---

{{% alert context="warning" text="The front matter `description` value for this page has been intentionally left empty in order to demonstrate FlexSearch's suggested results fallback behaviour." /%}}

## 1. 데모 설명
Zybo Z7-10 FPGA 보드에서 Petalinux를 빌드하는 방법을 기술한다. 

본 문서는 Zybo z7-10 보드를 기준으로 설명된 문서지만, 다른 Xilinx FPGA 보드에도 적용 가능하다.

## 2. What is Petalinux?
Petalinux란 Vivado FPGA에 포팅 가능한 운영체제를 뜻한다. 운영체제 안에는 커널, 쉘, 네트워크 등등 다양한 디바이스 드라이버가 미리 구현되어 있기 때문에 개발 시간을 단축할 수 있다. 또한 운영체제가 자원을 효과적으로 관리 가능하다.

 이와 반대로 Vivado에서 제공하는 Vitis 환경이 있는데 이는 운영체제가 없는 Baremetal 환경이다. Baremetal은 부팅 속도가 빠르고 단순하지만 주변 장치를 FPGA와 연동할 때에는 디바이스 드라이버를 따로 구현해야 하는 단점이 있다.
 
  만약 FPGA에 연결되는 주변 장치가 없다면 Baremetal 환경으로 검증하는 것도 좋은 방법이다. Petalinux를 FPGA에 Build한다는 뜻은 FPGA에 리눅스를 설치하는 것이다. 컴퓨터에 윈도우를 설치하는 것과 같다.

## 3. Demo
Petalinux를 Build하기 위한 Demo다. 3.1 항목 부터 차례대로 따라서 진행하면 된다. 이하 모든 과정은 [WSL](/docs/terms/wsl)  환경에서 실행한다. 3번 과정이 모두 끝나면 FPGA에서 Petalinux가 빌드된다. 숫자로 인덱싱된 과정들을 놓치지 말고 차근차근 따라해보자.
&nbsp;  
### 3.1 WSL 환경 셋업  

Petalinux 빌드를 위해서 먼저 컴퓨터에 [WSL](/docs/terms/wsl) 환경이 컴퓨터에 세팅되어야 한다. WSL 버전은 Petalinux가 정상적으로 동작하는데 매우 중요한 조건이다.  

https://docs.amd.com/r/en-US/ug1144-petalinux-tools-reference-guide/Navigating-Content-by-Design-Process  

위 링크를 클릭하면 PetaLinux Tools Documentation: Reference Guide (UG1144) 문서로 연결된다. 문서의 Installation Requirements 항목에 Supported OS: 부분에 지원되는 WSL 환경이 명시되어 있다.
  
![Internal link preview tooltip](/images/content/support_os_petalinux.png)  

1. 해당 Demo는 Ubuntu 20.04.6 LTS로 WSL를 구축한다. [(VMWare로 WSL 환경 구축 방법 참고)](https://leirbag.tistory.com/145)  

&nbsp;
### 3.2 리눅스 패키지 설치
 Petalinux를 설치하기 위해서 필요한 리눅스 패키지 파일을 설치한다.  

1. 리눅스 터미널을 열고 아래 명령어를 입력해 패키지 파일을 설치한다.

2. sudo apt-get install gawk
3. sudo apt-get install gcc
4. sudo apt-get install net-tools
5. sudo apt-get install xterm
6. sudo apt-get install libtool
7. sudo apt-get install texinfo
8. sudo apt-get install zlib1g-dev
9. sudo apt-get install gcc-multilib
10. sudo apt-get install build-essential
11. sudo apt-get install ncurses-dev
12. sudo apt-get install libncurses5-dev
13. sudo dpkg-reconfigure dash -> "No" 엔터
  
&nbsp;
    

### 3.3 BSP 파일 (직접 만들기 or 구하기)

Petalinux 빌드를 위해서는 bsp파일이 필요하다. 다행히 Xilinx에서 제공하는 EVM 보드는 미리 Petalinux가 빌드된 bsp 파일을 공식 사이트에서 배포한다.

 Zybo-z7-10의 경우는 Digilent 홈페이지에서 bsp 파일을 배포한다. 
 
 만약 미리 빌드된 bsp파일을 구하지 못한다면 petalinux 구성 설정을 통해 직접 bsp파일을 만들어야 한다. (아직 bsp 파일을 직접 만드는 방법은 몰라서 추후 업데이트)

1. https://digilent.com/reference/programmable-logic/zybo-z7/demos/petalinux 로 들어간다.  


    ![Internal link preview tooltip](/images/content/zybo_petalinux_bsp.png)  

2. 위 사진에서 원하는 petalinux 버전의 bsp파일을 선택한다. 이 때 반드시 3.4에서 설치할 petalinux 버전과 동일해야 한다. 이 데모는 Zybo-z7-10-Petalinux-2022-1.bsp를 설치한다.

&nbsp;
### 3.4 Petalinux 설치
이제 Petalinux 툴을 WSL 환경에 설치한다. 설치 파일은 AMD 홈페이지에서 구할 수 있다.
1. https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/embedded-design-tools/archive.html 접속
2. bsp 버전과 똑같은 Petalinux 버전 설치 (만약 bsp를 직접 만들거라면 내가 생성하려는 Petalinux 버전을 선택하면 된다.)
3. PetaLinux 2022.1 Installer를 클릭해 설치한다. 설치가 완료되면 <파일 이름>.run 파일이 받아짐을 확인할 수 있다. (BSP 파일 버전과 Petalinux 버전을 꼭 일치시키자!)
![Internal link preview tooltip](/images/content/petalinux_install.png)  
4. 설치가 완료되면 <Petalinux 파일 이름>.run 파일이 받아진다.
5. 리눅스 터미널을 열고 <Petalinux 파일 이름>.run이 있는 경로를 cd 명령어를 활용해 들어간다.
6. 터미널에서 "chmod 755 ./<Petalinux 파일 이름>.run" 을 입력한다.  
    ```bash
       ex) "chmod 755 ./petalinux-v2022.1-04191534-installer.run"
    ```
    
7. Petalinux를 설치할 폴더를 만들기 위해 터미널에서 "mkdir -p /opt/pkg/petalinux"를 입력한다. 
      ```bash
        "mkdir -p /opt/pkg/petalinux"
      ```
8. 터미널에서 "./<Petalinux 파일 이름>.run /opt/pkg/petalinux" 명령어를 입력한다.  
      ```bash
        ex) "./petalinux-v2022.1-04191534-installer.run /opt/pkg/petalinux"
      ```
9. INFO : Petalinux SDK has been installed to <설치 경로> 가 뜨면 정상적으로 Petalinux가 설치되었다.  

    ![Internal link preview tooltip](/images/content/petalinux_install_done_log.png)
10. 터미널에서 "cd /opt/pkg/petalinux" 명령어를 입력한다.
    ```bash
    "cd /opt/pkg/petalinux"
    ```

11. 터미널에서 "source settings.sh" 명령어를 입력한다.
    ```bash
     "source settings.sh"
    ```
12. 터미널에서 "echo $PETALINUX" 명령어를 입력해 뜨는 로그가 /opt/pkg/petalinux 이면 Petalinux가 WSL 환경에 잘 설치 되었다.
    ```bash
     "echo $PETALINUX"
    ```

&nbsp;
### 3.5 Petalinux 프로젝트 생성 및 설정
우리가 Vivado 프로젝트를 만드는 것과 동일하게 Petalinux 프로젝트를 새로 생성한다. 그리고 Petalinux 설정을 통해 이더넷 등 다양한 디바이스 드라이버들을 사용하기 위한 설정을 진행한다. (각 디테일한 옵션은 To do)

1. Petalinux 프로젝트들을 저장할 디렉토리를 하나 만든다.
    ```bash
       ex) "mkdir -p /home/kkh/Desktop/kkh"
    ```
2. cd 명령어를 이용해 Petalinux 프로젝트 폴더로 이동한다.
    ```bash
       ex) "cd /home/kkh/Desktop/kkh"
    ```
3. 3.3절의 2번 항목에서 받았던 bsp파일을 Petalinux 프로젝트 폴더로 이동시킨다.
4. 터미널에서 "petalinux-create --t project -s <bsp 파일 이름>"명령어를 입력해서 Petalinux 프로젝트를 생성한다.
    ```bash
      ex) "petalinux-create -t project -s Zybo-Z7-10-Petalinux-2022-1.bsp"
    ```
5. 터미널에서 cd 명령어를 활용해 생성된 petalinux 프로젝트 폴더 안으로 이동한다. (프로젝트 이름은 기본값 "os"로 생성된다.)
6. 터미널에서 "petalinux-config" 명령어를 입력한다.
    ```bash
      ex) "petalinux-config"
    ```
7. Subsystem Hardware Settings -> Ethernet Settings -> Obtain IP address automatically -> "n 입력" -> 아래와 같이 IP 설정 (IP address는 192.168.x.x 임의로 설정 가능하다.)  

    해당 과정은 컴퓨터에서 FPGA 보드에 ssh 이더넷을 활용해 접속할 때 FPGA의 IP를 정적으로 할당하기 위함이다. 만약 해당 옵션을 체크하지 않으면 무작위로 FPGA의 이더넷 IP가 할당된다.  &nbsp;

    ![Internal link preview tooltip](/images/content/petalinux_config.png)
8. Exit을 2번 눌러 최상위로 나온다.
9. Image Packing Configuration -> Root filesystem type (SD/eMMC/SATA/USB) -> EXT4 설정    &nbsp;


    ![Internal link preview tooltip](/images/content/petalinux_config_1.png)
10. 하단의 "SAVE"를 눌러서 Petalinux 설정을 저장한다.
11. 터미널을 열어 petalinux 프로젝트 폴더 안의 project-spec/meta-user/recipes-bsp/device-tree/files/ 경로로 들어간뒤 system-user.dtsi 파일을 연다.
    ```bash
      ex) "cd project-spec/meta-user/recipes-bsp/device-tree/files"
    ```
12. 파일의 내용 중 bootargs = console=ttyPS0,115200 earlyprintk uio_pdrv_genirq.of_id=generic-uio" 을 찾아서 bootargs = "console=ttyPS0,115200 earlyprintk uio_pdrv_genirq.of_id=generic-uio root=/dev/mmcblk0p2 rw rootwait"로 수정 후 저장한다.

13. 터미널에서 "petalinux-config -c rootfs"를 입력한다.
    ```bash
      ex) "petalinux-config -c rootfs"
    ```
14. Filesystem Packages -> misc -> packagegroup-core-buildessential -> packagegroup-core-buildessential -> "y"입력  &nbsp;


    ![Internal link preview tooltip](/images/content/petalinux_config_2.png)

    해당 과정은 Petalinux안에 C언어 컴파일을 위한 gcc 컴파일러를 설치하는 과정이다. 이를 통해 PS영역의 SW 프로그램을 코딩할 수 있다. 따라서 PL로부터 AXI 프로토콜을 활용해 데이터를 읽어오는 SW 프로그래밍 코드가 가능하다.

15. Filesystem Packages -> misc -> python3 -> python3 -> "y" 입력  &nbsp;

    ![Internal link preview tooltip](/images/content/petalinux_config_3.png)

    해당 과정은 Petalinux안에 Python 컴파일러를 설치하는 과정이다. Python으로도 SW 프로그밍이 가능하다.

16. 설정이 끝났으면 "SAVE"를 통해 설정을 저장한다.

기나긴 Petalinux 설정이 끝났다. 드디어 Petalinux를 빌드할 준비가 되었다.
&nbsp;
### 3.6 Petalinux 빌드
이제 Petalinux 빌드를 해보자. 빌드 방법은 매우 간단하다.

1. 터미널에서 "petalinux-build" 를 입력한다.
    ```bash
      ex) "petalinux-build"
    ```
    컴퓨터 성능에 따라 다르지만 약 15~20분 정도 걸린다.

2. 빌드가 완료되면 “petalinux-package --boot --fsbl ./images/linux/zynq_fsbl.elf --fpga ./images/linux/system.bit --u-boot ./images/linux/u-boot.elf –force” 을 입력한다.
    ```bash
      ex) “petalinux-package --boot --fsbl ./images/linux/zynq_fsbl.elf --fpga ./images/linux/system.bit --u-boot ./images/linux/u-boot.elf –force”
    ```
3. 1번과 2번 과정이 모두 완료되면 Petalinux 프로젝트 폴더 안에 /images 하위에 boot.scr, image.ub, BOOT.BIN, rootfs.tar.gz 파일이 생성된다.

이로써 Petalinux Build를 완료했다.

### 3.7 SD 카드 포맷
FPGA에서 Petalinux를 부팅시키는 과정은 SD 카드를 통해서 진행한다. SD카드 안에 3.6과정을 통해 생성된 boot.scr, image.ub, BOOT.BIN, rootfs.tar.gz 파일을 넣는다. USB나 SD카드를 통해 윈도우 부팅 디스크를 만드는 것과 똑같다.

이를 위해선 SD 카드가 특정 형태로 포맷되어야 한다.

1. 컴퓨터에 SD카드를 꽂는다.

2. 터미널에 "sudo fdisk -l" 명령어를 입력한다.
    ```bash
      ex) “sudo fdisk -l”
    ```
    그러면 log로 /dev/sdb 또는 /(dev/sda, /dev/sdc) 형태로 SD카드가 검색된다. 이 때 내가 넣은 SD카드의 용량을 확인해서 다른 저장공간과 헷갈리지 않게 유의한다.

    ![Internal link preview tooltip](/images/content/sd_card_fdisk.png)


3. 터미널에 "sudo fdisk <SD카드 장치 이름>을 입력한다.
    ```bash
      ex) “sudo fdisk /dev/sdb”
    ```
4. 터미널에 "p"를 입력한다.

    ![Internal link preview tooltip](/images/content/sd_card_fdisk_1.png)

    현재 파티션이 하나도 없음을 확인 할 수 있다.

5. 터미널에 "n"을 입력 -> 터미널에 "p" 입력 -> 그냥 한 번 엔터 -> 그냥 한 번 엔터 -> +1G 입력 엔터를 수행한다. (아래 그림 참고)

    ![Internal link preview tooltip](/images/content/sd_card_fdisk_2.png)

    위 과정을 수행한 뒤 터미널에 "a"를 입력하면 /dev/sdb1 이름으로 파티션이 한 개 생성된다.

6. 터미널에 "n"을 입력 -> 터미널에 "p" 입력 -> 그냥 한 번 엔터 -> 그냥 한 번 엔터 -> 터미널에 "p"입력 -> 터미널에 "w"입력 (아래 그림 참고)

    ![Internal link preview tooltip](/images/content/sd_card_fdisk_3.png)

    위 과정을 수행하면 총 2개의 파티션 (/dev/sdb1, /dev/sdb2)가 생성됨을 확인할 수 있다.
7. 터미널에 "sudo mkfs.vfat -F 32 -n BOOT /dev/sdb1" 입력
    ```bash
      ex) "sudo mkfs.vfat -F 32 -n BOOT /dev/sdb1"
    ```
8. 터미널에 "sudo mkfs.ext4 -L ROOT /dev/sdb2" 입력
    ```bash
      ex) "sudo mkfs.ext4 -L ROOT /dev/sdb2"
    ```
9. 위 과정이 모두 완료되면 SD카드 파티션이 boot, root 이름으로 2개가 생성되는지 확인하기
10. sd카드의 boot 영역에 3.6 항목의 3번에서 생성했던 boot.src, BOOT.BIN, image.ub 3개의 파일을 드래그 앤 드롭으로 복사
11. BOOT.BIN파일이 존재하는 경로에서 터미널을 열기
12. 터미널에서 “sudo dd if=rootfs.ext4 of=/dev/sdb2” 입력
    ```bash
      ex) “sudo dd if=rootfs.ext4 of=/dev/sdb2” 
    ```
    약 30분 정도 소요된다.

13. 터미널에서 “sudo resize2fs /dev/sdb” 입력
    ```bash
      ex) “sudo resize2fs /dev/sdb”
    ```

위 과정을 거쳐서 SD카드에 petalinux 부팅 파일이 정상적으로 올라갔다.

&nbsp;
### 3.8 FPGA에서 Petalinux 부팅하기
이제 FPGA에서 Petalinux를 부팅만 하면 된다. 부팅 방법은 간단하다.
1. 3.7에서 만든 SD카드를 FPGA SD 카드 슬롯에 꽂기

2. Zybo-z7-10을 SD카드 부팅 모드로 설정하기 (아래 그림 참고). 파란색 고무 마개를 빨간색 네모 처럼 꼽으면 된다.

    ![Internal link preview tooltip](/images/content/z7_10_sd_boot.jpg)

    만약 다른 EVM 보드라면 SD카드 부팅 모드를 스위치로 설정하기도 한다. 보드에 맞게 SD카드 부팅 설정 방법을 적용해야 한다.


3. 컴퓨터와 FPGA 이더넷 포트를 랜선으로 연결하기
4. 컴퓨터의 설정 -> 네트워크 및 인터넷 -> 이더넷 ->IPv4 주소를 192.168.255.xxx로 설정한다. 이때 IPv4 주소는 3.5항목의 7번 과정에서 설정한 IP의 3번째 구역까지 같아야하고 마지막 구역은 달라야 한다.

    ex) 3.5항목의 7번과정에서 IP를 192.168.255.10으로 설정했으면 내 컴퓨터의 IP는 192.168.255.100이어야 한다.
5. 서브넷 마스크는 255.255.255.0으로 설정한다.
6. MobaXterm이나 Tera-Term으로 serial 접속을 수행한다. 이때 Baurd-Rate를 115200으로 설정한다.
7. FPGA 보드 전원을 켜면 시리얼 통신으로 부팅 로그가 뜬다.
8. 초기 login ID는 root, 초기 비밀번호도 root이다.
9. 로그인을 완료하면 root@Petalinux-2022가 뜬다. 이를 통해 Petalinux가 성공적으로 부팅됨을 확인 할 수 있다.
10. ssh 이더넷 포트를 통해서도 접속이 가능하다 ssh root@<FPGA IP주소>를 입력하면 ssh 접속도 가능하다.