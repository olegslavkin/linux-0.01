[Русская версия](readme.md)
# Introduction
I have tried to replicate, as much as possible, Linus Torvalds' efforts to compile and run the very first version of the Linux kernel 0.01. The reasons that motivated Linus to start developing the kernel are well described in the book "[Just for Fun: The Story of an Accidental Revolutionary](https://en.wikipedia.org/wiki/Linus_Torvalds#Bibliography)" (hereafter J4F) and many other sources, and we will not touch on them. Instead, we will look at the technical side of compiling and running the Linux kernel.

The actual process of building a kernel in Unix style is very simple: just run the make command and you will get a ready binary file that you can write to a floppy disk and boot from it. But to make the build successful, you need to do a lot of preparation. That is what we are going to do. I have compiled a very detailed step-by-step guide for you.

First, in the emulator [86Box](https://86box.readthedocs.io/) create an empty virtual machine with characteristics close to Linus's computer at the time, install the original version of the Minix operating system 1.5.10, apply patches from "the king and god of Minix-386" (c) Bruce Evans, install the Minix-386 port of the gcc compiler version 1.37.1 from [Alan W Black](https://www.cs.cmu.edu/~awb/) and [Richard Tobin](https://www.cogsci.ed.ac.uk/~richard/), and finally build and run a Linux kernel with bash inside.

After each step, I saved the state of the virtual machine, the hard disk, and the floppy disk images that were modified. You can go through all the steps by yourself or unpack any of the archives and continue the instructions from the desired point. All distributions, screenshots, configurations, this guide, archives with backups for each step and even the binary AppImage 86box (for Linux x86_64) can be found in the [repository](https://github.com/olegslavkin/linux-0.01).

Let's get started.

---

# Table of contents<a name="toc"></a>
- [Introduction](#introduction)
- [Table of contents](#table-of-contents)
- [Linus Torvalds' alleged PC characteristics](#linus-torvalds-alleged-pc-characteristics)
- [Prerequisites](#prerequisites)
- [Installing the original 16-bit version of Minix 1.5.10](#installing-the-original-16-bit-version-of-minix-1510)
  - [Booting Minix 1.5.10](#booting-minix-1510)
  - [Partitioning a hard disk](#partitioning-a-hard-disk)
  - [Installing (copying) Minix 1.5.10 to hard disk](#installing-copying-minix-1510-to-hard-disk)
  - [Minix testing](#minix-testing)
- [Installing Bruce Evans' 386 patches aka Minix-386](#installing-bruce-evans-386-patches-aka-minix-386)
- [Compiling standard 1.5.10 utilities for the i386 architecture](#compiling-standard-1510-utilities-for-the-i386-architecture)
- [Installing the 387 coprocessor patch](#installing-the-387-coprocessor-patch)
- [Installing GCC 1.37.1 from Alan W Black and Richard Tobin](#installing-gcc-1371-from-alan-w-black-and-richard-tobin)
- [Compiling and running Linux 0.01 kernel](#compiling-and-running-linux-001-kernel)
- [Conclusion](#conclusion)
- [P.S.](#ps)
- [P.S.S](#pss)

---

# Linus Torvalds' alleged PC characteristics<a name="linus-pc"></a>
Before we start building and compiling Linux, we need to determine the conditions under which Linus Torvalds had to work. First of all, we are interested in what kind of personal computer he had and its characteristics. Yes, we know exactly what processor he was using and some other parameters, but I have not found (or have I searched badly?) a complete specification of his PC anywhere on the Internet. So I decided to do some "research" on the subject based on various open sources. Here is the hardware on which, **in my opinion**, the author of the Linux kernel worked.

| Hardware               | Manufacturer, model |
|------------------------|:--------------------|
| SVGA Monitor, 14''     | GoldStar 1460 Plus<sup>[1](#note-j4f) [2](https://usenetarchives.com/view.php?id=comp.sys.ibm.pc.hardware&mid=PDEwNDE0QGh5ZHJhLkhlbHNpbmtpLkZJPg)</sup> |
| Computer Case          | N/A. "A plain gray system unit"<sup>[3](#note-j4f)</sup> |
| Mainboard              | N/A |
| CPU                    | Intel 386DX, 33 MHz<sup>[4](#note-j4f)</sup> |
| FPU                    | Intel 387<sup>[5](#note-387)</sup> |
| RAM                    | 4 (or more likely 8) MB<sup>[6](#note-ram)</sup> |
| Video                  | Manufacturer unknown, based on ET4000 with 1 MB of memory<sup>[7](#note-video)</sup> |
| FDD A                  | 3.5-inch disk drive, 1.44 MB<sup>[8](#note-35fdd)</sup> |
| FDD B                  | 5.25-inch disk drive, 1.2 MB<sup>[9](#note-dualfdd)</sup> |
| HDD C                  | Conner CP3044 IDE Type 17<sup>[10](#note-hdd)</sup> |
| HDD D                  | Conner CP3044 IDE Type 17 |
| Modem                  | Manufacturer unknown<sup>[11](#note-modem)</sup> |
| Keyboard               | Finnish keyboard, manufacturer unknown |

Notes on the table:
- [1] The display size was mentioned in J4F. <a name="note-j4f"></a>
- [5] The 387 coprocessor appeared during the kernel development process. <a name="note-387"></a>
- [6] In J4F it was described as being 4 MB (most likely the original size), but in the book Linus writes: "I remember having to leave the house to increase the RAM from 4 to 8 megabytes", and it's not clear if this extra memory was still in his PC or if he borrowed it from someone temporarily. I think it did, because kernel 0.01 states in several places that it's already 8 MB. <a name="note-ram"></a>
- [7] "Happy owner" of an [ET4000 EVGA](https://www.tech-insider.org/linux/research/1991/0304.html), and when purchased [possibly](https://usenetarchives.com/view.php?id=comp.sys.ibm.pc.hardware&mid=PDEwNDE0QGh5ZHJhLkhlbHNpbmtpLkZJPg), was a Trident TVGA 8800 (?) video adapter. <a name="note-video"></a>
- [8] The [Release note](http://www.oldlinux.org/Linux.old/Linux-0.01/docs/RELNOTES-0.01) specifies the `/dev/PS0` device ("cp Image /dev/PS0 is what I use with a 1.44Mb floppy"). <a name="note-35fdd"></a>
- [9] Presumably there was a floppy drive, because it was common practice at the time to have both 3.5" and 5.25" floppy drives. Indirect evidence of a 5.25 floppy drive is that J4F says that Linus needed to insert 16 floppy disks during the Minix installation (*most likely, actually 15. The first three floppies are boot floppies and he used one of them*). And even though PH's Minix-1.5 on 3.5" floppies was officially [published](http://opennet.ru/docs/FAQ/OS/minix-info.html), I have my doubts that PH left the distribution on 17 3.5" floppies. The [Japanese](https://habrastorage.org/webt/3e/wd/p5/3ewdp5n7zc0onpcjmpe_rri5cjq.jpeg) edition of the book fit on 6. <a name="note-dualfdd"></a>
- [10] Two HDDs with characteristics [H5 S17 C980](https://kernel.googlesource.com/pub/scm/linux/kernel/git/nico/archive/+/refs/tags/v0.01/include/linux/config.h#48) + [CP3044](https://kernel.googlesource.com/pub/scm/linux/kernel/git/nico/archive/+/refs/tags/v0.01/kernel/hd.c#25). The fact of having a second disk [(see from "At my system fdisk reports the following…")](https://kernel.googlesource.com/pub/scm/linux/kernel/git/nico/archive/+/v0.11). <a name="note-hdd"></a>
- [11] External [HAYES](https://en.wikipedia.org/wiki/Hayes_command_set)-compatible (?) modem at [2400 baud](https://kernel.googlesource.com/pub/scm/linux/kernel/git/nico/archive/+/refs/tags/v0.01/kernel/serial.c#23). <a name="note-modem"></a>

> If you find errors in the table, please [let](https://github.com/olegslavkin/linux-0.01/issues) me know.

Let's now *approximately* configure the virtual computer in the 86Box emulator.

---

# Prerequisites<a name="req"></a>
These instructions are written and tested on an HP ProBook 440 G6 running Ubuntu 20.04.6 LTS and emulator version 86Box-Linux-x86_64-b4724.AppImage (AppImage is in the bin directory of the repository).

The first step is to clone the repository:
```bash
git clone git@github.com:olegslavkin/linux-0.01.git
cd linux-0.01
```

Next, you need to unpack the archive with an empty and unmapped 68 MB virtual hard disk:

```bash
mkdir -p disks
xz -kdc backups/empty-hda.img.xz > disks/minix.img
```

> Attentive readers will ask why disk 1 and not 2, as in the table above? And why does it have completely different characteristics? When I started writing this manual, I didn't know about two hard disks and their characteristics yet, so I created only one disk. I tried to adapt the manual for two disks, but I couldn't handle the partitioning in Minix :( In future releases, I will adapt for two and maybe not keep the 16- and 32-bit Minix/Minix-386 utilities together.

Now let's run the emulator in virtual PC configuration mode.

> If you have not installed 86box before, you will need to install the [ROM](https://github.com/86Box/roms/releases/latest)-image set. [See documentation for details](https://86box.readthedocs.io/en/latest/usage/gettingstarted.html).

```bash
$ ./86box -S
```
And based on the screenshots below, configure the virtual computer we will be working with throughout this tutorial.

<spoiler title="Virtual computer configuration in 86box.">

It might have been better to use "[SiS 310] ASUS ISA-386C" as "Machine". But as I wrote above, I have no information about the original motherboard.
![86box-settings-machine](https://habrastorage.org/webt/n-/1z/is/n-1zisoqfs8h92kh9ffzdsqgz3e.png)
![86box-settings-display](https://habrastorage.org/webt/eh/gg/ih/ehggihkae77fyppd7zexoobyp5g.png)
![86box-settings-input-devices](https://habrastorage.org/webt/0-/h1/bf/0-h1bfm6rwbjaqriesun-juvqmc.png)
![86box-settings-sound](https://habrastorage.org/webt/ff/xl/iw/ffxliwz5umgoqmory5vgs1ymnzo.png)
![86box-settings-network](https://habrastorage.org/webt/k0/9x/6a/k09x6alcgd79azai3rviklbyf3g.png)
![86box-settings-ports-com-ltp-serial-port-1](https://habrastorage.org/webt/fv/mg/6v/fvmg6v2x_0cdpkt9iacbdzsw27o.png)
![86box-settings-storage-controllers](https://habrastorage.org/webt/sz/lq/9j/szlq9jenf01qdezeqyvomwtyof0.png)
Add the hard disk `disks/minix.img` with the specified characteristics:
![86box-settings-hdd](https://habrastorage.org/webt/mj/rl/p-/mjrlp-nos1_0eyoaygirwnrscu0.png)
![86box-settings-floppy-cdroms](https://habrastorage.org/webt/-s/ay/_e/-say_ejgu3h9ben62spahjn6qzi.png)
![86box-settings-other-removable-devices](https://habrastorage.org/webt/zv/rk/qo/zvrkqoiuzxwtdkpznixyew4jw_k.png)
![86box-settings-other-peripherals](https://habrastorage.org/webt/ed/n8/yq/edn8yqedng6cwco7bpfihyzk22s.png)
</spoiler>

---

# Installing the original 16-bit version of Minix 1.5.10<a name="minix-1.5.10-ph"></a>
Install the original Minix 1.5.10 from the original floppy disk images. I wrote this chapter based on the second chapter of the original [MINIX 1.5 REFERENCE MANUAL](https://github.com/olegslavkin/linux-0.01/blob/master/manual/minix-15-reference-manual-1991.pdf).

> Sometimes you can find the name "Minix 1.5.10 PH" on the web, or "Minix PH". PH is an abbreviation of Prentice-Hall, the name of the publishing house that published the book [Andrew S. Tanenbaum "Operating Systems Design and Implementation-Prentice-Hall" (1987)](https://github.com/olegslavkin/linux-0.01/blob/master/manual/Andrew%20S.%20Tanenbaum%20-%20Operating%20Systems%20Design%20and%20Implementation-Prentice-Hall%20(1987).pdf). This is the same "719 pages in a soft red binding, you might say, that settled in my bed" (c) (J4F).

## Booting Minix 1.5.10
Run the emulator:
```bash
$ ./86box
```
The first step is to enter the BIOS settings (press the DEL key). Set the characteristics of the hard disk (the most suitable type 36) and disk drives. **Important** that "Floppy drive A:" should be "360KB 5.25". Save the BIOS settings and exit.
![bios-floppyA-360k](https://habrastorage.org/webt/1a/lf/qr/1alfqrp_iygthsjhfopgwqy_tyw.png)

Check that the [boot floppy for PC (disk02)](https://github.com/olegslavkin/linux-0.01/raw/master/dist/minix/disk02.img) is inserted into the disk drive, and after checking the BIOS and loading the boot sector, a menu should appear on the emulator screen.

![Minix boot menu](https://habrastorage.org/webt/ts/ls/ho/tslshocapqa-_nbmsm92u1c7dkk.png)

When the boot program has fully loaded from the floppy disk (*the emulator status bar will stop flashing green with the floppy drive "indicator"*, this may take a few seconds) and the command prompt appears:
```sh
# _
```
...in the emulator menu *Media -> Floppy 1 -> Existing image...* change it to a floppy disk with root file system [disk04](https://github.com/olegslavkin/linux-0.01/raw/master/dist/minix/disk04.img). After that, in the emulator window, enter the `=` command to load Minix into RAM (`/dev/ram`) from the selected floppy diskette (`/dev/fd0`). After successfully booting into memory, Minix will prompt you to insert a [disk05](https://github.com/olegslavkin/linux-0.01/raw/master/dist/minix/disk05.img) floppy diskette, which will be mounted in the `/usr` directory. Insert the floppy disk image into the emulator menu and press Enter.

After mounting the floppy disk, the system will ask you to enter the current time and day. Enter in the format `MMDDYYhhmmss` (see screenshot below). And at the end of the boot Minix will prompt you to log in.

> As you can see, Minix works correctly if you enter the year 2023. And recently linkmeup published a funny screenshot where SunOS 4.1.4 wrote a [warning](https://t.me/linkmeup_podcast/7372).

Minix 1.5.10 has at least two accounts. The first is the privileged `root` account with the password `Geheim`, and the second is the regular user account `ast` with the password `Wachtwoord`. Authorize as `root`.

![login](https://habrastorage.org/webt/3g/cm/e8/3gcme8tv_m-ph34-t8tbqbfz3di.png)
<spoiler title="Configuring getty (optional)">

At this point we will simplify further interaction with Minix. Entering commands in the emulator window is, on the one hand, a more "correct" way, but it is still an emulator, besides, entering commands in this way is very slow, and copy-paste from this instruction will be impossible :).

Lucky for us, Minix 1.5.10 supports [getty](https://en.wikipedia.org/wiki/Getty), which means that thanks to 86Box's ability to route a virtual COM port as a pseudo terminal device to the host operating system, it is possible to use minicom, (c)kermit and other similar terminals to connect to Minix.

> Since COM port forwarding had not yet been added to the release when this tutorial was written (*this will tentatively happen in v4.0*), there is an AppImage in the repository. The intermediate build is downloaded from their [Jenkins](https://ci.86box.net/job/86Box/).

However, there is no way to use getty during the out-of-the-box installation phase, but it is very easy to fix this. To do this, mount the disk04 floppy in the host operating system (modern Linux still understands the old Minix file system) and add one line to the `etc/ttys` file:
```bash
$ sudo mount dist/minix/disk04.img <path>
$ echo '2f1' >> <path>/etc/ttys

$ cat <path>/etc/ttys

100
0f1
2f1 <- Added a line
```
> For this tutorial, the string is already added to disk04, but if you want to do it yourself, there is an original diskette [disk04.img.orig](https://github.com/olegslavkin/linux-0.01/raw/master/dist/minix/disk04.img.orig) in the repository.

And then you can connect to Minix "remotely". The pseudo terminal device `/dev/pts/7`, as in this case, will be displayed in stdout when the 86box emulator is started.
```bash
$ minicom -o -c off -t vt100 -p pts/7 -b 9600
```
![minicom](https://habrastorage.org/webt/aj/vx/km/ajvxkmyalabtzzpfhhiukibnq1m.png)

<spoiler title="You can connect not only from the host to Minix, but also in the opposite direction...">

To do this on the host OS, run agetty:
```bash
DEV='X'
sudo agetty -o '-p -- \\u' --keep-baud 9600 pts/${DEV} vt100
```

And in Minix, run kermit and enter the commands:
> The tty2 device is COM2. To avoid creating a loop, enable COM2 forwarding in the same way as COM1.
```
set line /dev/tty2
set speed 9600
connect
```
</spoiler>

It is also possible to send and receive files (*albeit crookedly*) using the zmodem protocol (via `sz` and `rz`). But I find it easier to mount a floppy disk or hard disk partition on the host and copy the necessary files to or from it.

</spoiler>

## Partitioning a hard disk
Before you can begin installing Minix, you must partition the virtual hard disk. To do this, enter the command:
```bash
fdisk -h8 -s17 /dev/hd0
```
The first 5 MB partition of the `hd1` disk with a DOS file system will not be used in this manual, but it is specifically left as an MS-DOS installation option, because even Linus himself had an MS-DOS partition where he played ["Prince of Persia"](https://www.tech-insider.org/linux/research/1992/1028.html).

To create a partition, type the following commands:
```
c
1
0  (first cylinder)
75 (last cylinder)
y  (change partition to active)
a
1  (active)
```
The second partition of the `hd2` disk, also 5 MB in size and with the Minix file system, will be used as the root partition (`/`):
```
c
2
76  (first cylinder)
512 (last cylinder)
n
```
The third partition `hd3` is as `/usr`:
```
c
3
513 (first cylinder)
588 (last cylinder)
n
```

The fourth partition `hd4` will not be used yet, let's leave it for the future (*for Linux*):
```
c
4
589  (first cylinder)
1023 (last cylinder)
n
```
The result is the following partition table:
```bash
                          ----first----  -----last----  --------sectors-------
Num Sorted Active Type     Cyl Head Sec   Cyl Head Sec    Base    Last    Size
 1     1     A    DOS-BIG    0   0   2     75   7   16       1   10334   10334
 2     2          MINIX     76   0   1    150   7   17   10336   20535   10200
 3     3          MINIX    151   0   1    905   7   17   20536  123215  102680
 4     4          MINIX    906   0   1   1023   7   17  123216  139263   16048
```
To make changes and exit fdisk, press `w` and run the `sync` command. Reboot the virtual machine and boot as you did before. And then run `fdisk` again and make sure everything is successfully written. To exit fdisk, type `q`.
```bash
# fdisk -h8 -s17 /dev/hd0

                          ----first----  -----last----  --------sectors-------
Num Sorted Active Type     Cyl Head Sec   Cyl Head Sec    Base    Last    Size
 1     1     A    DOS-BIG    0   0   2     75   7   16       1   10334   10334
 2     2          MINIX     76   0   1    150   7   17   10336   20535   10200
 3     3          MINIX    151   0   1    905   7   17   20536  123215  102680
 4     4          MINIX    906   0   1   1023   7   17  123216  139263   16048

(Enter 'h' for help.  A null line will abort any operation)
```
Next, format all three Minix partitions of the hard disk using file system tools. For each of them, run the command `mkfs /dev/hdX <SIZE IN BLOCKS>`, where `X` is the partition number and `SIZE IN BLOCKS` is set based on the fact that a block occupies 1024 bytes. It is calculated as the number of sectors divided by 2.
```bash
mkfs /dev/hd2 5100
mkfs /dev/hd3 51340
mkfs /dev/hd4 8024
```
## Installing (copying) Minix 1.5.10 to hard disk
After the hard disks are prepared, you can run the shell script to install Minix 1.5.10. To do this, you must specify as arguments the partition of the root disk (in our case it is `/dev/hd2`), the size of `ram` in MB, and the sizes (in blocks) of all four partitions.

```bash
/etc/setup_root /dev/hd2 4096 5139 5100 51340 8024

/dev/hd2 mounted
/dev/hd2 unmounted
```

Now "insert" the `disk02` boot diskette image again and reboot. After the boot menu is displayed, you need to change the root partition from which to boot. In all the previous steps we booted from a floppy disk (`disk04`), but this time we need to boot from a hard disk partition. To change the root partition, type `r` (*select root device*) in the menu, then `h2`, then Enter and then type `=`.

As with the first startup, the operating system will ask you to insert a `/usr` floppy diskette (this is `disk05`), and then you will need to re-authorize as `root`.

![change-root](https://habrastorage.org/webt/nw/ng/uv/nwnguvvdq_gve20zcuwvfeuelgu.png)

> If you connected to Minix with minicom before, you can connect to it again after booting from the floppy disk. If in the 86Box emulator you reboot the virtual computer with the Reset button in the emulator menu, then, as a rule, the device of the pseudo-terminal remains the same and you don't need to do anything in minicom, just enter the login and password and then follow this guide.

Now we need to initialize the `/usr` partition. To do this, run another shell script in the terminal, specifying as an argument the disk partition to be used as `/usr`. In this manual it is `hd3`.
```bash
/etc/setup_usr /dev/hd3
```
The `/usr` partition will be initialized. The script will ask you to insert floppies from `disk05` to `disk17` one by one.

```bash
<Cut out, leaving only the last disk output>

/dev/fd0 mounted
Copying commands
/dev/fd0 unmounted
Please insert disk 17, then hit the ENTER key

/dev/fd0 mounted
Copying LAST_DISK
Copying amoeba
/dev/fd0 unmounted
Loading finished. Please remove the last diskette from the drive.
```
After copying data from floppy disks, unpacking the archives will start automatically.

<spoiler title="View the output of the script">

```
The files will now be unpacked.
Unpacking /usr/lib
Unpacking /usr/include
Unpacking /usr/include/minix
Unpacking /usr/include/sys
Unpacking /usr/src/elle
Unpacking /usr/src/kernel
Unpacking /usr/src/fs
Unpacking /usr/src/mm
Unpacking /usr/src/tools
Unpacking /usr/src/test
Unpacking /usr/src/lib/ansi
Unpacking /usr/src/lib/posix
Unpacking /usr/src/lib/other
Unpacking /usr/src/lib/ibm
Unpacking /usr/src/lib/string
Unpacking /usr/src/commands
Unpacking /usr/src/commands/ibm
Unpacking /usr/src/commands/bawk
Unpacking /usr/src/commands/de
Unpacking /usr/src/commands/dis88
Unpacking /usr/src/commands/indent
Unpacking /usr/src/commands/ic
Unpacking /usr/src/commands/m4
Unpacking /usr/src/commands/make
Unpacking /usr/src/commands/mined
Unpacking /usr/src/commands/nroff
Unpacking /usr/src/commands/patch
Unpacking /usr/src/commands/sh
Unpacking /usr/src/commands/zmodem
Unpacking /usr/src/commands/kermit
Unpacking /usr/src/commands/elvis
Unpacking /usr/src/amoeba
Unpacking /usr/src/amoeba/kernel
Unpacking /usr/src/amoeba/fs
Unpacking /usr/src/amoeba/mm
Unpacking /usr/src/amoeba/examples
Unpacking /usr/src/amoeba/util
Installation completed.
```
</spoiler>

Since we have just initialized the `/usr` partition, it is no longer necessary to insert the `disk05` floppy diskette at the start of the operating system boot. Now we can automatically mount the `hd3` disk partition as `/usr`. To do this, you need to fix `/etc/rc` a little bit:
```bash
mined /etc/rc
```
> If you edit files in minicom and similar utilities, it is possible that documents may not be displayed correctly when scrolling in the terminal. You can edit the file in the main console of the emulator, where you can continue typing commands in minicom after saving it. Or if you know how to fix this, please email me and I'll include it in the manual.

Comment out (or delete) the floppy disk mount strings (as well as the floppy disk insertion prompt) and add a mount entry for the hard disk partition.
```bash
#/bin/getlf "Please insert /usr diskette in drive 0.  Then hit ENTER."
#/etc/mount /dev/fd0 /usr               # mount the floppy disk
/etc/mount /dev/hd3 /usr                # mount the hard disk
```
Optionally, set a higher serial port speed:
```bash
# Initialize the first RS232 line to 9600 baud.
/usr/bin/stty 9600 </dev/tty1
```
> In the mined editor, save the changes with the CTRL+W key combination, and to exit the editor press CTRL+X.
>
> In addition to mined, the original Minix 1.5.10 has both a vi clone and an emacs elle clone, but I will use mined throughout this guide.

Enter the `sync` command, check that we have the `disk02` boot floppy inserted and reboot again. After booting, select r -> h2 and press =, as we did last time. Such actions should be performed every time you boot the operating system.

## Minix testing
To make sure that the operating system is installed correctly, the developers have prepared test programs (they must be compiled beforehand) and shell scripts. For testing you should go to the directory and compile `*.c`. It is recommended to compile as `root` (at the last stage execution rights are set for the files):

```bash
cd /usr/src/test
make all
```
<spoiler title="Compilation process of test programs">

```
cc -F -D_MINIX -D_POSIX_SOURCE -o test0 test0.c;             chmem =8192  test0
test0: Stack+malloc area changed from 56042 to 8192 bytes.
cc -F -D_MINIX -D_POSIX_SOURCE -o test1 test1.c;             chmem =8192  test1
test1: Stack+malloc area changed from 59024 to 8192 bytes.
cc -F -D_MINIX -D_POSIX_SOURCE -o test2 test2.c;             chmem =8192  test2
test2: Stack+malloc area changed from 58086 to 8192 bytes.
cc -F -D_MINIX -D_POSIX_SOURCE -o test3 test3.c;             chmem =8192  test3
test3: Stack+malloc area changed from 58816 to 8192 bytes.
cc -F -D_MINIX -D_POSIX_SOURCE -o test4 test4.c;             chmem =8192  test4
test4: Stack+malloc area changed from 58982 to 8192 bytes.
cc -F -D_MINIX -D_POSIX_SOURCE -o test5 test5.c;             chmem =8192  test5
test5: Stack+malloc area changed from 54974 to 8192 bytes.
cc -F -D_MINIX -D_POSIX_SOURCE -o test6 test6.c;             chmem =8192  test6
test6: Stack+malloc area changed from 59156 to 8192 bytes.
cc -F -D_MINIX -D_POSIX_SOURCE -o test7 test7.c;             chmem =8192  test7
test7: Stack+malloc area changed from 49378 to 8192 bytes.
cc -F -D_MINIX -D_POSIX_SOURCE -o test8 test8.c;             chmem =8192  test8
test8: Stack+malloc area changed from 58098 to 8192 bytes.
cc -F -D_MINIX -D_POSIX_SOURCE -o test9 test9.c;             chmem =8192  test9
test9: Stack+malloc area changed from 57486 to 8192 bytes.
cc -F -D_MINIX -D_POSIX_SOURCE -o test10 test10.c;   chmem =8192  test10
test10: Stack+malloc area changed from 57522 to 8192 bytes.
cc -F -D_MINIX -D_POSIX_SOURCE -o test11 test11.c;   chmem =8192  test11
test11: Stack+malloc area changed from 57490 to 8192 bytes.
cc -F -D_MINIX -D_POSIX_SOURCE -o test12 test12.c;   chmem =8192  test12
test12: Stack+malloc area changed from 60678 to 8192 bytes.
cc -F -D_MINIX -D_POSIX_SOURCE -o test13 test13.c;   chmem =8192  test13
test13: Stack+malloc area changed from 58574 to 8192 bytes.
cc -F -D_MINIX -D_POSIX_SOURCE -o test14 test14.c;   chmem =20000 test14
test14: Stack+malloc area changed from 59476 to 20000 bytes.
cc -F -D_MINIX -D_POSIX_SOURCE -o test15 test15.c;   chmem =8192  test15
"test15.c", line 438: (warning) incompatible pointers in ==
"test15.c", line 439: (warning) incompatible pointers in ==
"test15.c", line 440: (warning) incompatible pointers in ==
"test15.c", line 441: (warning) incompatible pointers in ==
"test15.c", line 443: (warning) incompatible pointers in ==
"test15.c", line 445: (warning) incompatible pointers in ==
"test15.c", line 447: (warning) incompatible pointers in ==
"test15.c", line 453: (warning) incompatible pointers in ==
"test15.c", line 506: (warning) incompatible pointers in ==
"test15.c", line 512: (warning) incompatible pointers in ==
"test15.c", line 514: (warning) incompatible pointers in ==
"test15.c", line 517: (warning) incompatible pointers in ==
"test15.c", line 523: (warning) incompatible pointers in ==
test15: Stack+malloc area changed from 49120 to 8192 bytes.
cc -F -D_MINIX -D_POSIX_SOURCE -o test16 test16.c;   chmem =8192  test16
test16: Stack+malloc area changed from 54988 to 8192 bytes.
cc -F -D_MINIX -D_POSIX_SOURCE -o test17 test17.c;   chmem =8192  test17
test17: Stack+malloc area changed from 43274 to 8192 bytes.
cc -F -D_MINIX -D_POSIX_SOURCE -o test18 test18.c;   chmem =8192  test18
test18: Stack+malloc area changed from 46508 to 8192 bytes.
cc -F -D_MINIX -D_POSIX_SOURCE -o test19 test19.c;   chmem =8192  test19
test19: Stack+malloc area changed from 54990 to 8192 bytes.
cc -F -D_MINIX -D_POSIX_SOURCE -o test20 test20.c;   chmem =65000 test20
```
</spoiler>

And to run the tests themselves, it is recommended to login as a normal user, not `root`. Login as `ast` with the password `Wachtwoord`.
```bash
cd /usr/src/test
run
```

If all tests were successful, then additionally run the two test shell scripts `sh1` and `sh2`.
```
$ run
Test  0 ok
Test  1 ok
Test  2 ok
Test  3 ok
Test  4 ok
Test  5 ok
Test  6 ok
Test  7 ok
Test  8 ok
Test  9 ok
Test 10 ok
Test 11 ok
Test 12 ok
Test 13 ok
Test 14 ok
Test 15 ok
Test 16 ok
Test 17 ok
Test 18 ok
Test 19 ok
Test 20 ok
Test 21 ok
All system call tests completed.
Try running sh1 and sh2.

$ sh1
Shell test  1 ok

$ sh2
Shell test  2 ok
```
> Phantom errors may appear on startup in minicom, but they usually disappear after restarting.

<spoiler title="Backing up the intermediate point">
At this point you can pause the emulator and save the hard disk image, BIOS settings, and the configuration file of the emulator itself. This will be very helpful in the future if you need to roll back changes.

```bash
tar cvfJ backups/minix-1.5.10-install-hda.tar.xz disks/minix.img nvr/acc386.nvr 86box.cfg
```
</spoiler>

---

# Installing Bruce Evans' 386 patches aka Minix-386 <a name="minix-386"></a>
In the previous chapter we installed the classic 16-bit version of Minix 1.5.10, as originally intended by the author. But the purpose of this guide is to go through the steps Linus Torvalds took when writing Linux (*okay, okay, okay, not all the steps, we won't write Linux itself :)*). As mentioned above, Linus was not working in the original, but in a patched version of Minix 1.5.10, also known as Minix-386. The patches were prepared by Bruce Evans, and John Nall wrote an [excellent manual](https://github.com/olegslavkin/linux-0.01/raw/master/dist/minix-386/tutor.asc) on how to use them.

But before we start the transformation, we need to "upgrade" our virtual PC a bit. When installing the classic Minix, a 5.25" 360KB disk drive was used. Only by specifying this type of virtual disk drive in the emulator and BIOS settings, I was able to perform the installation and write this manual. But to boot the 32-bit version of Minix (*and later for Linux*) you will need already 5.25 inch 1.2 MB floppy disks. So you need to make sure that in the emulator settings and in the BIOS the appropriate type of floppy drive is specified.

![86box_floppy](https://habrastorage.org/webt/4w/py/fq/4wpyfqmjbllooyqxqzfk1hq8cv8.png)
![1_2M_FDD](https://habrastorage.org/webt/y0/mv/yw/y0mvywl-hvryhlyb1ate7zndmda.png)

> There is a [patch](https://usenetarchives.com/view.php?id=comp.os.minix&mid=PDc4MDZAbmlnZWwudWRlbC5FRFU%2B) online that allows booting from various types of floppy disks, but I haven't tested it out.

Boot as usual from the `disk02` boot floppy, remembering to specify the `h2` partition as the root partition at boot. Authorize as `root`. Next, instead of the boot floppy, in the emulator, insert a floppy with patches from Bruce Evans [minix-386](https://github.com/olegslavkin/linux-0.01/raw/master/dist/minix-386/minix-386.img), create a directory `/usr/oz`, mount the floppy and copy all the files.

> The files contained on the diskette were taken from the [archive](http://www.oldlinux.org/Linux.old/study/linux-travel/minix-386/zhao.rar) from oldlinux.org. In addition to patches, there are other useful files there.

```bash
mkdir /usr/oz
cd /usr/oz
/etc/mount /dev/at0 /user
cp /user/* /usr/oz
/etc/umount /dev/at0
sync
```

Prepare a boot floppy diskette. Insert the [shoelace](https://github.com/olegslavkin/linux-0.01/raw/master/dist/minix-386/shoelace.img) diskette and format it:
```bash
mkfs /dev/at0 1200
```
Go to the directory with the archives and unzip them:
```bash
cd /usr/oz
compress -d mx386_1.1.t.Z
compress -d mx386_1.1.01.Z
compress -d bcc.tar.Z
compress -d bccbin16.tar.Z
compress -d bccbin32.tar.Z
compress -d bcclib.tar.Z

rm mx386_1.1.t.Z
rm mx386_1.1.01.Z
```
Next, create a folder for the bootloader and unzip it:
```bash
mkdir /usr/oz/shoelace
mv shl-1.0a.t.Z shoelace
cd shoelace
compress -d shl-1.0a.t.Z
tar xvf shl-1.0a.t
rm shl-1.0a.t shl-1.0a.t.Z
```
Create a folder for the bcc compiler, unpack the archives with the 16- and 32-bit versions and the source codes of the standard C library:
```bash
cd /usr/oz
mkdir bcc
mv bcc*.tar bcc

cd /usr/oz/bcc
tar xvf bcc.tar
tar xvf bccbin16.tar
tar xvf bccbin32.tar
tar xvf bcclib.tar
rm bcc*.tar
```
Unpack the archive with minix-386 patches and rename the directory to mx386 for convenience:
```bash
cd /usr/oz
tar xvf mx386_1.1.t
mv mx386_1.1 mx386
rm mx386_1.1.t
```
Unzip a small patch to the minix-386 patch:
```bash
cd /usr/oz
unshar < mx386_1.1.01
rm mx386_1.1.01
mv klib386.x* /usr/oz/mx386/kernel
```
Go to the kernel patch folder and apply:
```bash
cd /usr/oz/mx386/kernel
patch klib386.x klib386.x.cdif
```
Mount the boot floppy (*shoelace floppy must still be inserted in the floppy drive*), create the necessary directories and copy the `dev` and `etc` directories:
```bash
/etc/mount /dev/at0 /user
cd /user
mkdir usr
mkdir user
cd /
cpdir -s dev /user/dev
cpdir -ms etc /user/etc
```
Uninstall the three 16-bit versions of the programs:
```bash
cd /user/etc
rm mount umount update
```
Comment out the line with the disk mount as `/usr`:
```bash
mined /user/etc/rc
# comment
# /etc/mount /dev/hd3 /usr
```
Create a `/local` folder in the root and copy the 16- and 32-bit versions of the compiler into it.
> Using the `/local` path is mandatory. If it suddenly does not fit, you will have to change it in `bcc.c` and recompile the compiler.

```bash
cd /
mkdir local

cd /usr/oz/bcc
cpdir -ms bccbin16 /local/bin
cpdir -ms bccbin32 /local/bin3

cd /usr/oz/mx386
cpdir -ms bin0 /local/bin  # 16-bit compiler stuff
cpdir -ms bin3 /local/bin3 # 32-bit compiler stuff
```
Copy the patches for the Minix kernel to the kernel source directory, and copy the patches for the header files:
```bash
cpdir -ms fs /usr/src/fs         # mods for fs
cpdir -ms kernel /usr/src/kernel # mods for kernel
cpdir -ms mm /usr/src/mm         # mods for mm
cpdir -ms tools /usr/src/tools   # mods for tools

cd /usr/oz/bcc/lib/fix1.5.10     # move Bruce's changes
cp include.cdif /usr/include     # to include

cp ansi.cdif /usr/src/lib/ansi   # to ansi
cp other.cdif /usr/src/lib/other # to other
cp posix.cdif /usr/src/lib/posix # and to posix
```
Applying header files patches:
```bash
cd /usr/include
patch < include.cdif

cd /usr/src/lib/ansi
patch < ansi.cdif

cd /usr/src/lib/other
patch < other.cdif

cd /usr/src/lib/posix
patch < posix.cdif

cd /usr/src/tools
patch < tools.cdif

cd /usr/oz/bcc/lib
cpdir -ms bcc /usr/src/lib/bcc
```
Save (*do not delete, it will still be needed*) the original binary make and compile without the `-DMINIXPC` flag:
```bash
cd /usr/bin
mv make make_s
cd /usr/src/commands/make
mined Makefile # Leave only "CFLAGS = -Dunix"
make_s
mv make /usr/bin
```
Add the path to the bcc compilers to the PATH, and rename the original C compiler (cc) and symlink:
```bash
PATH=/local/bin:$PATH
export PATH
cd /usr/bin
mv cc cc_old
cd /local/bin
ln bcc cc
```
Compile the 16-bit version of the `libc.a` and `longlib.a` libraries:
```bash
cd /usr/src/lib/ansi
rm -f *.s
cd ../posix
rm -f *.s
cd ../ibm
rm -f *.s
cd ../other
rm -f *.s
cd ../string
rm -f *.s

cd /usr/src/lib/bcc
sh makelib 86 | tee problems.out 2>&1

cd /usr
mkdir local
cd local
mkdir lib
cd lib
mkdir i86
cd /usr/src/lib/bcc/i86
cp * /usr/local/lib/i86

cd /usr/src/lib/bcc/86
ar r /usr/src/kernel/longlib.a laddl.o lcmpl.o ldecl.o lorl.o \
        lsll.o lsrul.o lsrl.o
cd /usr/src/kernel
ar t longlib.a  # check to be sure they are there...
```
Compile the 32-bit version of the library:
```bash
cd /usr/src/lib/bcc
sh makelib 86 clean

sh makelib 386 | tee problems.out 2>&1

cd /usr/src/lib/bcc/i386
mkdir /usr/local/lib/i386
cp * /usr/local/lib/i386
cd ..
sh makelib 386 clean
```
Create a directory for the Minix kernel components:
```bash
cd /etc
mkdir system
```
Compile the Minix kernel components. Note that when editing makefile.cpp, it is required that all cpp preprocessor lines start at the beginning of the line.
During the linking process, `warning: _exit (or _unlock or _lock) redefined` warnings may appear. Do not pay attention to them now or later.
```bash
cd /usr/src/mm
rm -f *.s *.o
mined makefile.cpp   # be sure all "#" commands start in column 1
/usr/lib/cpp -P -DINTEL_32BITS makefile.cpp > makefile
make                 # generate /etc/system/mm

cd /usr/src/fs
rm -f *.s *.o
mined makefile.cpp   # again, be sure all "#" commands start in col 1
/usr/lib/cpp -P -DINTEL_32BITS makefile.cpp > makefile
make                 # generate /etc/system/fs
```
When editing `xx`, remove all comments that do not refer to the `cpp` preprocessor syntax, as well as unnecessary tab characters in expressions such as `#define O s`, `#if INTEL_32BITS`, `#else`, `#endif`.
```bash
cd /usr/src/kernel
cp makefile.cpp xx
mined xx              # remove all of the comment lines
rm -f *.s *.o
sh config 386         # set up proper files.
/usr/lib/cpp -P -DINTEL_32BITS xx > makefile
make                  # generate  /etc/system/kernel
```
Compile `init`. During linking process there may also appear `warning: _exit (or _sbrk) redefined` warnings, which we also ignore.
```bash
cd /usr/src/tools
cc -3 -c -D_POSIX_SOURCE -D_MINIX init.c
ld -3 -o /etc/system/init /usr/local/lib/i386/head.o \
   init.o /usr/local/lib/i386/libc.a
```
Compile the shoelace loader, but to do so we temporarily revert the original make and cc.
```bash
cd /usr/bin
mv cc_old cc
mv make make_o
mv make_s make
PATH=/usr/bin:/bin
export PATH
cd /usr/oz/shoelace
mined shoe.c          # Replace <varargs.h> with "varargs.h"
make -f makefile.min
```
Create a boot sector on a floppy disk and copy the boot loader binary files, its configuration files and Minix kernel components.
```bash
cd /usr/oz/shoelace
./laceup /dev/at0 5.25dshd
cd /etc/system
mkdir /user/etc/system
cp * /user/etc/system       # copy kernel, fs, mm, init
cp /usr/oz/shoelace/config /user/etc/config
cp /usr/oz/shoelace/shoelace /user/shoelace
cp /usr/oz/shoelace/bootlace /user/etc/bootlace
cp /usr/oz/shoelace/disktab /user/etc/disktab
cp /usr/oz/shoelace/laceup /user/etc/laceup

mined /user/etc/config
# Comment out run    /etc/system/db
# Replace with a floppy disk
setdev rootdev /dev/at0
```
Return make and cc, as well as the `PATH` variable to the previous state.
```bash
cd /usr/bin
mv cc cc_old
mv make make_s
mv make_o make
PATH=/local/bin:$PATH
export PATH
```
Compile 32-bit sh:
```bash
cd /user
mkdir bin
cd /usr/src/commands/sh

rm -f *.s *.o
cc -3 -D_POSIX_SOURCE -o /user/bin/sh *.c
```
Compile other minimally required programs:
```bash
cd /usr/src/commands
cc -3 -D_POSIX_SOURCE -D_MINIX -o /user/bin/login login.c
cc -3 -D_POSIX_SOURCE -D_MINIX -o /user/etc/update update.c
cc -3 -D_POSIX_SOURCE -D_MINIX -o /user/etc/mount mount.c
cc -3 -D_POSIX_SOURCE -D_MINIX -o /user/etc/umount umount.c
cc -3 -D_POSIX_SOURCE -D_MINIX -o /user/bin/cat cat.c
cc -3 -D_POSIX_SOURCE -D_MINIX -o /user/bin/ls ls.c
cc -3 -D_POSIX_SOURCE -D_MINIX -o /user/bin/cp cp.c
cc -3 -D_POSIX_SOURCE -D_MINIX -o /user/bin/mv mv.c

cd /usr/src/commands/ibm
cc -3 -D_POSIX_SOURCE -D_MINIX -o /user/bin/readclock readclock.c
```

Make sure that the floppy disk with `shoelace` is still inserted in the disk drive and restart the computer.

Welcome to Minix-386!

![minix-386](https://habrastorage.org/webt/fd/kh/mr/fdkhmrv3fdmlkmnb_jsdszpg9cc.png)

Ignore that some of the `readclock`, `date`, `wtmp`, `printroot`, and `stty` programs involved in the `/etc/rc` initiating script failed to start, they are still 16-bit. We will fix this in the next chapter.
![minix-386-not-found](https://habrastorage.org/webt/gy/xk/nu/gyxknupcepkzdeqd6yqcnk15rx0.png)

<spoiler title="Backing up an intermediate point">

Pause the emulator and save:

```bash
tar cvfJ backups/minix-386-1.5.10-stage1.tar.xz disks/minix.img dist/minix-386/shoelace.img nvr/acc386.nvr 86box.cfg
```
</spoiler>

---

# Compiling standard 1.5.10 utilities for the i386 architecture <a name="i386bin"></a>
After verifying that we have successfully booted with the new kernel from the floppy disk, we need to recompile the utilities. To do this, boot the 16-bit Minix (using the `disk02` floppy and the `h2` hard disk partition) and perform cross-compilation of the 80386 versions of the binary utilities.

To simplify the process, I prepared a Makefile and an auxiliary sh-script. Unpack the archive with the Makefile and run the compilation:
```bash
cd /usr/oz
compress -d bin32.tar.Z
tar xvf bin32.tar && rm bin32.tar
/tmp/bin32.sh | tee problems.out 2>&1
```
Create a directory for the 32-bit version of the kernel and move the components compiled in the previous step there:
```bash
mkdir /etc/system3
cd /etc/system/
mv kernel fs mm init /etc/system3
```
Move binary files to `/bin`:
```bash
cd /etc
mv mount umount update /bin
```
> Yes, from Minix's point of view, this may not be canonical, but this way you can have both 16- and 32-bit versions of the programs at the same time. It will also make it easier to switch between 16- and 32-bit modes. And I just got used to having mount/umount in PATH.

Unmount the floppy disk, if something other than `shoelace` is inserted in the drive, swap it for shoelace and mount it. Change the `rootdev` value in the bootloader configuration file from floppy (`at0`) to disk (`hd2`) and change the paths for `mount` and `update`:
```bash
umount /dev/at0
mount /dev/at0 /user

mined /user/etc/config
# setdev rootdev /dev/hd2   <- replace with HDD partition

mined /etc/rc
# /bin/mount /dev/hd3 /usr  <- replace with /bin/
# /bin/update  &            <- replace with /bin/

sync
```
Rename directories. Don't rush to reboot!
```bash
/local/bin/bin3
```
The script we just ran does not rename the `/usr/binX` directory. Do it manually:
```bash
/bin0/mv /usr/bin /usr/bin0
/bin0/mv /usr/bin3 /usr/bin
```

Now you can reboot, and welcome to Minix-386 (again)!
![minix-386-again](https://habrastorage.org/webt/j7/kl/u3/j7klu3cww5klhkaqexhnonhqkbe.png)

<spoiler title="Backing up an intermediate point">
Pause the emulator and save:

```bash
tar cvfJ backups/minix-386-1.5.10-stage2.tar.xz disks/minix.img dist/minix-386/shoelace.img nvr/acc386.nvr 86box.cfg
```
</spoiler>

<spoiler title="Reverting to the 16-bit version">

If you need to go back to the 16-bit version, you just need to rename the paths to the binary files, insert the `disk02` floppy and use the `h2` hard disk partition as root.
```bash
/local/bin/bin0
/bin3/mv /usr/bin /usr/bin3
/bin3/mv /usr/bin0 /usr/bin
/bin3/sync
```

</spoiler>

<spoiler title="Utilities not available in the 80386 version">

Some utilities are missing from the 32-bit version of Minix. The emacs clone [elle](https://www.unix.com/man-page/minix/9/elle/) is missing (the `elle`, `ellec` files) because the original diskettes do not contain their source code.

In bcc, cpdir and ttt do not compile — this is a known issue. There is a fix for cpdir, but for ttt — unknown. However, ttt is the game "Tic Tac Toe", which I had no need for.

There is no need for the ast and cc utilities because we use the bcc compiler. There are no source files for pc — The Minix [Pascal Compiler](https://www.krsaborio.net/unix-source-code/research/1987/1014-a.html), but it may simply be a symlink to cc.

Also, compress (and its symlinks uncompress and zcat) does not work for me, but later with the gcc installation we will install a working compress.

</spoiler>

---

# Installing the 387 coprocessor patch <a name="fix387"></a>
Insert the `shoelace` floppy and temporarily migrate to the 16-bit version to compile the kernel.
```bash
/local/bin/bin0
/bin3/mv /usr/bin /usr/bin3
/bin3/mv /usr/bin0 /usr/bin
/bin3/sync
```
Insert the `disk02` floppy and reboot. After rebooting, insert the [gcc-1.37.1](https://github.com/olegslavkin/linux-0.01/raw/master/dist/gcc-1.37.1-plains/awb-gcc-1.37.1.img) floppy. Copy the kernel patch that emulates the presence of a 387 coprocessor. It is part of gcc-1.37.1 and, as I understand it, reassigns the second bit of the `CR0` register that "tells" the compiler that we have no 387 coprocessor. This patch is mandatory, otherwise you will not be able to build the Linux kernel later — you will get the `fp stack overflow` compilation error. After applying the patch, rebuild the minix-386 kernel (*only kernel is enough*):
```bash
/bin/mount /dev/at0 /user
cp /user/klib386.cdiff /usr/src/kernel
cd /usr/src/kernel
PATH=/local/bin:/usr/bin:bin
export PATH
patch < klib386.cdiff
rm -f *.s *.o
make
```
Copy the kernel to the boot floppy. Unmount the inserted floppy, insert `shoelace`, mount it and copy the kernel:
```bash
/bin/umount /dev/at0
/bin/mount /dev/at0 /user
mv /etc/system/kernel /etc/system3
cp /etc/system3/kernel /user/etc/system
sync
```
Migrate back to minix-386:
```bash
/local/bin/bin3
/bin0/mv /usr/bin /usr/bin0
/bin0/mv /usr/bin3 /usr/bin
/bin0/sync
```
<spoiler title="Backing up an intermediate point">

Pause the emulator and save the current state.

```bash
tar cvfJ backups/minix-386-1.5.10-stage3.tar.xz disks/minix.img dist/minix-386/shoelace.img nvr/acc386.nvr 86box.cfg
```
</spoiler>

---

# Installing GCC 1.37.1 from Alan W Black and Richard Tobin <a name="gccbin137"></a>
As is well known, the Linux kernel was compiled with gcc. And originally it was Linus's own patched version of gcc 1.40 with support for the `-mstring-insns` option (*maybe something else*). I don't know where this exact version of the compiler can be found now. Perhaps [this](http://www.oldlinux.org/Linux.old/Linux-0.10/binaries/compilers/gccbin.tar.Z) is that very version. The files in the archive are dated September 22, 1991, very, very close to that time. On the other hand, you can't rely on those dates. Perhaps this is gcc for building inside Linux itself, not inside Minix.

I will take a slightly different path and use gcc-1.37.1 from Alan W Black and Richard Tobin, also known as "awb-gcc from plains". Sometimes it is simply called "gcc from plains" on the web. There is also [gcc-1.40](https://www.cs.cmu.edu/~awb/pub/minix/gasdiff.tar.gz) for Minix-386, but I will not use it because: a) the patch is not from Linus Torvalds, but from Andy Michael; b) there is only a diff, and it would need to be compiled as well :)

Boot from the `shoelace` floppy, then swap it for the [gcc-1.37.1](https://github.com/olegslavkin/linux-0.01/raw/master/dist/gcc-1.37.1-plains/awb-gcc-1.37.1.img) floppy, mount it and copy the 16-bit version of the compress utility (*Minix used [13-bit compression](https://www.unix.com/man-page/minix/1/compress/)*):
```bash
mount /dev/at0 /user
cp /user/16bcompress /usr/bin
chmod 755 /usr/bin/16bcompress
```
Copy the gcc binary files to a temporary folder, unpack and install them:
```bash
cd /usr/tmp
cp /user/gcc*.tar.Z /usr/tmp
16bcompress -d gcc*.tar.Z

tar xvf gccbin.tar
cd gccbin
mkdir /usr/local/bin
mkdir /usr/local/lib/gcc
mv ar gcc gcc2minix make nm size /usr/local/bin
mv gcc-ld gcc-cc1 gcc-cpp gcc-as /usr/local/lib/gcc
ln /usr/local/lib/gcc/gcc-as /usr/local/bin/gas
ln /usr/local/lib/gcc/gcc-ld /usr/local/bin/gld
ln /usr/local/bin/ar /usr/local/bin/gar
cd /usr/tmp
rm -fr gccbin*
```
Install the header files:
```bash
cd /usr/tmp
tar xvf gccinc.tar
cd gccinc
mkdir /usr/local/lib/gcc/gcc-include
mv * /usr/local/lib/gcc/gcc-include
cd /usr/tmp
rm -fr gccinc*
```
Install the C libraries:
```bash
cd /usr/tmp
tar xvf gcclib.tar
cd gcclib
cp /usr/lib/libc.a /usr/lib/libc.a.orig # in case it's needed
cp libc.a /usr/lib/libc.a
cp libm.a /usr/lib/libm.a
cp gnulib /usr/local/lib/gcc/gnulib
cp crt0.o /usr/local/lib/gcc/crt0.o
cd /usr/tmp
rm -rf gcclib*
```
Test the compiler by writing a traditional "Hello World":
```bash
cd /usr/tmp
PATH=/usr/local/bin/:$PATH
export PATH

cat <<EOF > gcc_test.c
#include <stdio.h>
main()
{
  printf("Hello World\\n");
}
EOF

gcc gcc_test.c
```
You will get the equally traditional a.out. But if you try to run it directly, you will get an error:
```bash
a.out
: not found
```
The reason is that gcc generates a binary file that is not directly compatible with Minix. There are two solutions. The first (popular one): convert to a compatible format using gcc2minix, which was included in the gccbin package.
```bash
gcc2minix < a.out > test
chmod +x test
./test
Hello World
```
The second option: use the [gnutoo](https://www.cs.cmu.edu/~awb/pub/minix/gnutoo.tar.gz) patch. It didn't work for me, but maybe I did something wrong.

<spoiler title="Backing up an intermediate point">

Pause the emulator and save the current state.
```bash
tar cvfJ backups/minix-386-1.5.10-gcc1.37.1.tar.xz disks/minix.img dist/minix-386/shoelace.img nvr/acc386.nvr 86box.cfg
```
</spoiler>

---

# Compiling and running Linux 0.01 kernel <a name="linux-0.01"></a>
And now, finally, after all the preparation steps, we can proceed to compiling the Linux kernel. But we need a little more preparation for that :). Remember at the very beginning, when we were partitioning the hard disk, we had an unused `h4` partition? It was left specifically for Linux. Format the partition and also add it to auto-mount at Minix-386 startup:
```bash
mkdir /linux
mkfs /dev/hd4 8024
mined /etc/rc
# add right after the /dev/hd3 mount line
# /bin/mount /dev/hd4 /linux              # linux
/bin/mount /dev/hd4 /linux
```
Create the necessary directories:
```bash
cd /linux
mkdir usr
mkdir tmp
cd usr
mkdir src
```
Insert the floppy with Linux source code [linux-src-0.01](https://github.com/olegslavkin/linux-0.01/raw/master/dist/linux/src.img) and mount the floppy. The source code archive itself [linux-0.01.tar.Z](http://www.oldlinux.org/Linux.old/Linux-0.01/sources/system/linux-0.01.tar.Z) was taken from oldlinux.org. Notably, the official Linux kernel website has a [tar.gz version](https://mirrors.edge.kernel.org/pub/linux/kernel/Historic/linux-0.01.tar.gz) from October 1993 (*kernel 0.01, I remind you, ["was born" on 17.09.1991](https://lkml.org/lkml/2021/9/17/1018)*). This is most likely a repackaging into an archive format supported by the GNU utilities of that time.
```bash
/bin/mount /dev/at0 /user
cp /user/linux.tar.Z /linux/tmp
16bcompress -d /linux/tmp/linux.tar.Z
cd /linux/usr/src
tar xvf /linux/tmp/linux.tar
rm /linux/tmp/linux.tar
cd linux
```
Adapting the kernel for gcc-1.37.1:
```bash
mined Makefile

# Add the path to gnulib:
LIBS    =lib/lib.a /usr/local/lib/gcc/gnulib

# Linus had the gnutoo patch (or similar), so no conversion was needed.
# Change to the following form.
# Don't forget that in a Makefile the indent from the line start is a tab character!
tools/build: tools/build.c
        $(CC) $(CFLAGS) \
        -o tools/a.out tools/build.c
        gcc2minix < tools/a.out > tools/build
        chmod +x tools/build
        chmem +65000 tools/build

# Remove `-mstring-insns` from CFLAGS
mined fs/Makefile
mined kernel/Makefile
mined lib/Makefile
```
Adapt to our "hardware": use 5.25-inch 1.2 MB floppies instead of 3.5-inch ones, set the upper memory limit, and specify that we will use the `h4` hard disk partition and its characteristics.

> Now and a bit later you will see why I doubt that Linus had a computer with 4 MB of RAM — most likely he had 8 MB. Perhaps at purchase it was indeed 4, but later he increased it to 8. Just as he possibly added a second hard disk.

```bash
# Specify that we'll use 1.2 MB
mined boot/boot.s
| sectors = 18
sectors = 15

mined include/linux/config.h
/* #define LASU_HD */
/* #define LINUS_HD */
#define E86BOX_HD
...
#if     defined(LINUS_HD)
#define HIGH_MEMORY (0x800000)
#elif   defined(LASU_HD)
#define HIGH_MEMORY (0x400000)
#elif   defined(E86BOX_HD)
#define HIGH_MEMORY (0x400000)
#else
#error "must define hd"
#endif
...
/* Root device at bootup. */
#if     defined(LINUS_HD)
#define ROOT_DEV 0x306
#elif   defined(LASU_HD)
#define ROOT_DEV 0x302
#elif   defined(E86BOX_HD)
#define ROOT_DEV  0x304
#else
#error "must define HD"
#endif

#if     defined(LASU_HD)
#define HD_TYPE { 7,35,915,65536,920,0 }
#elif   defined(LINUS_HD)
#define HD_TYPE { 5,17,980,300,980,0 },{ 5,17,980,300,980,0 }
#elif   defined(E86BOX_HD)
#define HD_TYPE { 8,17,1024,65536,1024,0 }
#else
#error "must define a hard-disk type"
#endif
```
Add paths to the compilers and assembler to PATH, and finally compile:
```bash
PATH=/usr/local/bin:/local/bin:/bin:/usr/bin
export PATH
make
```
If the compilation is successful, an `Image` file will appear in the kernel directory. This is our Linux kernel.
```bash
...
gld -s -x -M boot/head.o init/main.o \
kernel/kernel.o mm/mm.o fs/fs.o \
lib/lib.a /usr/local/lib/gcc/gnulib \
-o tools/system > System.map
(echo -n "SYSSIZE = (";ls -l tools/system | grep system \
        | cut -c25-31 | tr '\012' ' '; echo "+ 15 ) / 16") > tmp.s
cat boot/boot.s >> tmp.s
as -0 -a -o boot/boot.o tmp.s
rm -f tmp.s
ld -0 -s -o boot/boot boot/boot.o
gcc -Wall -O -fstrength-reduce -fomit-frame-pointer -fcombine-regs \
-o tools/a.out tools/build.c
gcc2minix < tools/a.out > tools/build
chmod +x tools/build
chmem +65000 tools/build
tools/build: Stack+malloc area changed from 65536 to 130536 bytes.
tools/build boot/boot tools/system > Image <---- this is Linux!!!
Boot sector 452 bytes.
System 93184 bytes.
sync
```

<spoiler title="But perhaps you, like me, may encounter a compilation error">

```bash
gcc: installation problem, cannot exec /usr/local/lib/gcc/gcc-cc1: No more processes
```
This happens, as I understand it, due to the small amount of RAM (remember, we are using 4 MB). And there are two solutions: a) temporarily increase to 8 MB in the emulator settings and everything will work as it should; or b) build in several stages.
```bash
cd kernel && make
cd ../mm  && make
cd ../fs  && make
cd ../lib && make
cd ..     && make
```

</spoiler>

After successful compilation, create the necessary directories and devices on the hard disk.
```bash
cd /linux
mkdir dev
mkdir bin

cd dev
mknod tty c 5 0
mknod tty0 c 4 0
mknod tty1 c 4 1
mknod tty2 c 4 2
mknod hd0 b 3 0 0
mknod hd1 b 3 1 5139
mknod hd2 b 3 2 5100
mknod hd3 b 3 3 51340
mknod hd4 b 3 4 8024
```
Insert the [bin](https://github.com/olegslavkin/linux-0.01/raw/master/dist/linux/bin.img) floppy with pre-built binaries of [bash](http://www.oldlinux.org/Linux.old/gnu/bash/bash-1.05-linux.tar.gz) and [update](http://www.oldlinux.org/Linux.old/Linux-0.01/binaries/sbin/update.Z).

> bash is not original, compiled in 2004, most likely by Jiong Zhao (the author of oldlinux.org). The original should have used [bash-1.08](https://en.wikipedia.org/wiki/Linux_kernel#cite_note-minix-10), but I was unable to find either the binary or the source code of that version.

```bash
/bin/mount /dev/at0 /user
cp /user/bash /linux/bin/sh
cp /user/update /linux/bin/update
```
Insert a blank [boot](https://github.com/olegslavkin/linux-0.01/raw/master/dist/linux/boot.img) floppy and write the kernel to it.
```bash
/bin/umount /dev/at0
cd /linux/usr/src/linux

dd if=Image of=/dev/at0
183+0 records in
183+0 records out
```
Reboot the computer. And congratulations, you are in Linux-0.01 with a [hardcoded](http://www.oldlinux.org/Linux.old/Linux-0.01/docs/RELNOTES-0.01) [Finnish](https://upload.wikimedia.org/wikipedia/commons/1/1c/IBM_model_M2_for_Sweden_and_Finland.jpg) keyboard layout.

![linux-0.01](https://habrastorage.org/webt/nn/yy/qp/nnyyqp3ss4bk1plc0y4_gjspn-4.png)

But, as Linus wrote, there is absolutely nothing to do in this kernel version, just admire it. A bare bash shell with nothing but built-in commands. You can't even run `ls`, but you can try to emulate it with `alias ls='echo *'`.

<spoiler title="Backing up an intermediate point">

Pause the emulator and save the current state.
```bash
tar cvfJ backups/minix-386-1.5.10-linux-0.01.tar.xz disks/minix.img dist/minix-386/shoelace.img dist/linux/boot.img nvr/acc386.nvr 86box.cfg
```
</spoiler>

---

# Conclusion
In addition to Linux 0.01 we have created three different environments in which you can spend time in a long and engaging way.

First, the original Minix 1.5.10, where you can explore the Minix microkernel, and Andrew's book will help with that. Over the years, the community has created and ported many interesting programs. Some of them can still be found on the internet. Some are preserved on the legendary [nic.funet.fi](http://www.nic.funet.fi/pub/minix/).

Second, Minix-386, for which a lot of interesting things were also made. For example, there was a GUI implementation Mini-X (not X11 compatible), virtual consoles (just like modern screen), an [IP stack](http://www.nic.funet.fi/pub/minix/communications/tnet4.tar.Z) implementation which Minix didn't have but many people requested, and much more.

And third, we created an environment with gcc and Linux where you can compile and run other kernel versions yourself or try porting GNU utilities. Unfortunately, subsequent kernel versions 0.02 and 0.03 have not survived to this day, and from [0.10](https://mirrors.edge.kernel.org/pub/linux/kernel/Historic/old-versions/tytso/linux-0.10.tar.gz) only the version by [Theodore Ts'o](https://en.wikipedia.org/wiki/Theodore_Ts%27o) has been preserved. However, versions 0.11 and 0.12 can be used to [study](http://www.oldlinux.org/download/ECLK-5.0-WithCover.pdf) the internal structure of the Linux kernel.

And also, the same author of oldlinux.org, Jiong Zhao, [wrote](http://www.oldlinux.org/Linux.old/bochs-images/linux-0.00-050613.zip) a fake version [0.00](http://gunkies.org/wiki/Linux_0.00). As Linus wrote: "My first test program used one process to print the letter A on the screen, and another to print the letter B. (Sounds boring, I know.) I programmed it so that a few letters were printed every second. Using the timer interrupt, I made it so that at first the screen was filled with AAAAAAA. Then suddenly the letters changed to BBBBBBBB." However, I couldn't get it to work in 86Box :(.

---

# P.S.
If anyone has a desire to run everything on real, not virtual hardware, and you have questions, my contacts can be found in my Habr profile or on github.com.

# P.S.S
While this guide was being written, an article about the [internals of Linux version 0.01](https://habr.com/ru/articles/754322/) was published. I recommend checking it out.
