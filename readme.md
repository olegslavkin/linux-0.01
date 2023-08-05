# Введение
Данное руководство описывает попытку повторить, на сколько это возможно, первые шаги Линуса Торвальдса по компиляции и запуску самой первой версии ядра Linux 0.01. Процесс зарождения операционной системы, было хорошо написано в книге "[Ради удовольствия: Рассказ нечаянного революционера](https://ru.wikipedia.org/wiki/%D0%A0%D0%B0%D0%B4%D0%B8_%D1%83%D0%B4%D0%BE%D0%B2%D0%BE%D0%BB%D1%8C%D1%81%D1%82%D0%B2%D0%B8%D1%8F)" (далее J4F). Но нас в первую очередь интересует техническая возможность компиляции, поэтому нам необходим PC на процессоре i386, с установленным minix-386 (minix c патчами Брюса Эванса) и всеми необходимыми утилитами для компиляции.

# Оглавление<a name="toc"></a>
1. [Предположительные характеристики PC Линуса Торвальдса](#linus-pc)
2. [Предварительные условия](#req)
3. [Установка оригинальной 16-битной версии Minix 1.5.10](#minix-1.5.10-ph)
4. [Установка патчей от Брюса Аванса (Bruce Evans' 386 patches) ака minix-386](#minix-386)
5. [Компиляция стандартных утилит 1.5.10 под архитектуру i386](#i386bin)
6. [Установка компилятора GCC-1.37.1 от Alan W Black и Richard Tobin](#gnubin137)
7. [Компиляция ядра Linux 0.01 и попытка загрузиться](#linux-0.01)
8. [Разное](#other)

# Предположительные характеристики PC Линуса Торвальдса<a name="linus-pc"></a>
Предположительные характеристики PC Линуса Торвальдса, на основании различных источников в сети. В таблице, возможно, есть не точности.
| Аппаратное обеспечение  |   Производитель, модель  |
|-------------------------|:-------------------------|
| SVGA Монитор 14''       | GoldStar 1460 Plus<sup>[1](#note-j4f) [2](https://usenetarchives.com/view.php?id=comp.sys.ibm.pc.hardware&mid=PDEwNDE0QGh5ZHJhLkhlbHNpbmtpLkZJPg)</sup> |
| Системный блок          | Н/Д. "Неизвестный серый ящик" <sup>[3](#note-j4f)</sup> |
| Материнская плата       | Н/Д |
| CPU                     | Intel 386DX 33Mhz <sup>[4](#note-j4f)</sup> |
| FPU                     | Intel 387 <sup>[5](#note-387)</sup> |
| RAM                     | 4 (или скорее всего 8) Mb <sup>[6](#note-ram)</sup> |
| Video                   | Производитель неизвестен на базе ET4000 на 1Mb <sup>[7](#note-video)</sup> |
| FDD A                   | 3.5 1.44 <sup>[8](#note-35fdd)</sup> |
| FDD B                   | 5.25 1.2 <sup>[9](#note-dualfdd)</sup> |
| HDD C                 | Conner CP3044 IDE Type 17 <sup>[10](#note-hdd)</sup> |
| HDD D                 | Conner CP3044 IDE Type 17 |
| Modem        | Производитель неизвестен <sup>[11](#note-modem)</sup> |
| Клавиатура      | Финская клавиатура, производитель неизвестен |

Примечания по таблице:
- [1] J4F<a name="note-j4f"></a>
- [5] Появилась в процессе разработки ядра (в анонсе 0.03)<a name="note-387"></a>
- [6] В J4F описывалось, что 4 Мб, в ядре 0.01 в нескольких местах указано, что уже 8Мб<a name="note-ram"></a>
- [7] [Возможно](https://usenetarchives.com/view.php?id=comp.sys.ibm.pc.hardware&mid=PDEwNDE0QGh5ZHJhLkhlbHNpbmtpLkZJPg) в начале была карта Trident TVGA 8800 (?) <a name="note-video"></a>
- [8] В руководстве указано устройство `/dev/PS0` (это 3.5`` 1.44M) <a name="note-35fdd"></a>
- [9] Предположительно, что дисковод был, т.к. в то время было распространенной практикой иметь и 3.5 и 5.25 <a name="note-dualfdd"></a>
- [10] 2 HDD c характеристиками [H5 S17 C980](https://kernel.googlesource.com/pub/scm/linux/kernel/git/nico/archive/+/refs/tags/v0.01/include/linux/config.h#48) + [CP3044](https://kernel.googlesource.com/pub/scm/linux/kernel/git/nico/archive/+/refs/tags/v0.01/kernel/hd.c#25). Факт наличия 2-го диска [(см. с момента "At my system fdisk reports the following...)](https://kernel.googlesource.com/pub/scm/linux/kernel/git/nico/archive/+/v0.11)<a name="note-hdd"></a>
- [11] Внешний [HAYES](https://ru.wikipedia.org/wiki/AT-%D0%BA%D0%BE%D0%BC%D0%B0%D0%BD%D0%B4%D1%8B) совместимый (?) модем на [2400 baud](https://kernel.googlesource.com/pub/scm/linux/kernel/git/nico/archive/+/refs/tags/v0.01/kernel/serial.c#23)<a name="note-modem"></a>

## Предварительные условия<a name="req"></a>
Данная инструкция написана и тестировалась на HP ProBook 440 G6 с операционной системой `Ubuntu 20.04.6 LTS` и версией эмулятора `86Box-Linux-x86_64-b4724.AppImage` (есть в директории `bin` репозитория).

Клонируем репозиторий
```
git clone git@github.com:olegslavkin/linux-0.01.git
cd linux-0.01
```
Запускаем эмулятор в режиме конфигурацию виртуального PC. 
> Если у вас не установлен 86box, то также необходимо будет установить набор [ROM](https://github.com/86Box/roms/releases/latest) образов. [Подробнее в документации](https://86box.readthedocs.io/en/latest/usage/gettingstarted.html).

Распаковываем архив с пустым, неразмеченным виртуальным жестким диском на 68Мб.
```
mkdir -p disks
xz -kdc backups/empty-hda.img.xz > disks/minix.img
```
И запускаем эмулятор в режиме его конфигурации.
```
$ ./86box -S
```
Проверяем, что настройки эмулятора 86box выставлены согласно скриншотам ниже.
![86box-settings-machine](https://habrastorage.org/webt/n-/1z/is/n-1zisoqfs8h92kh9ffzdsqgz3e.png)
![86box-settings-display](https://habrastorage.org/webt/eh/gg/ih/ehggihkae77fyppd7zexoobyp5g.png)
![86box-settings-input-devices](https://habrastorage.org/webt/0-/h1/bf/0-h1bfm6rwbjaqriesun-juvqmc.png)
![86box-settings-sound](https://habrastorage.org/webt/ff/xl/iw/ffxliwz5umgoqmory5vgs1ymnzo.png)
![86box-settings-network](https://habrastorage.org/webt/k0/9x/6a/k09x6alcgd79azai3rviklbyf3g.png)
![86box-settings-ports-com-ltp-serial-port-1](https://habrastorage.org/webt/fv/mg/6v/fvmg6v2x_0cdpkt9iacbdzsw27o.png)
![86box-settings-storage-controllers](https://habrastorage.org/webt/sz/lq/9j/szlq9jenf01qdezeqyvomwtyof0.png)
Добавляем жесткий диск `disks/minix.img` с указанными характеристиками.
![86box-settings-hdd](https://habrastorage.org/webt/mj/rl/p-/mjrlp-nos1_0eyoaygirwnrscu0.png)
![86box-settings-floppy-cdroms](https://habrastorage.org/webt/-s/ay/_e/-say_ejgu3h9ben62spahjn6qzi.png)
![86box-settings-other-removable-devices](https://habrastorage.org/webt/zv/rk/qo/zvrkqoiuzxwtdkpznixyew4jw_k.png)
![86box-settings-other-peripherals](https://habrastorage.org/webt/ed/n8/yq/edn8yqedng6cwco7bpfihyzk22s.png)


# Установка оригинальной 16-битной версии Minix 1.5.10<a name="minix-1.5.10-ph"></a>
## Загрузка
Запускаем эмулятор.
```
$ ./86box
```
Первым делом заходим в настройки BIOS и установливаем характеристики жесткого диска и флоппи дисководов. ВАЖНО, что бы floppy A был 360K 5.25. Сохраняемся и выходим.
![bios-floppyA-360k](https://habrastorage.org/webt/1a/lf/qr/1alfqrp_iygthsjhfopgwqy_tyw.png)

Проверяем, что в дисковод вставлена [загрузочная дискета для PC](https://github.com/olegslavkin/linux-0.01/raw/master/dist/minix/disk02.img) и после проверки BIOS на экране эмулятора должно появится меню.
![Загрузка](https://habrastorage.org/webt/ts/ls/ho/tslshocapqa-_nbmsm92u1c7dkk.png)

После того, как загрузочная программа полностью загрузилось с дискеты (*в статусной строке эмулятора перестанет мигать зеленым цветом "индикатор" дисковода*) и появилось приглашение ввода команды:
```
# _
```
В меню эмулятора *Media -> Floppy 1 -> Existing image...* меняем на дискету с корневой файловой системой [disk04](https://github.com/olegslavkin/linux-0.01/raw/master/dist/minix/disk04.img) и в окне эмулятора вводим команду `=` для загрузки Minix в оперативную память (`/dev/ram`) с только, что выбранной дискеты(`/dev/fd0`). После успешной загрузки в память, Minix предложить вставить дискету [disk05](https://github.com/olegslavkin/linux-0.01/raw/master/dist/minix/disk05.img), которая будет смонтирована в каталог `/usr`. Вставьте образ дискеты и нажмите enter.

После монтирования дискеты система попросит ввести текущее время и день. Введите в формате `MMDDYYhhmmss` (см. скриншот ниже). И в конце этапа загрузки Minix предложит авторизоваться в системе.

В Minix 1.5.10, имеется, по меньшей мере, 2 учетные записи. Первая из них - это привелигированная рутовая учетная запись `root` с паролем `Geheim`, а также имеется обычный пользователь `ast` с паролем `Wachtwoord`. Авторизуйтесь как `root`.

![login](https://habrastorage.org/webt/3g/cm/e8/3gcme8tv_m-ph34-t8tbqbfz3di.png)

## Настраиваем getty (опционально)
На этом этапе упростим дальнейшее взаимодействие с Minix. Вводить команды в окне эмулятора это с одной стороны более "правильный" путь, но всё же это эмулятор, плюс вводить команды таким способом это очень медленно, да и copy-paste с этой инструкции будет не возможен :)

Но, на наше счастье, Minix 1.5.10 поддерживает [getty](https://ru.wikipedia.org/wiki/Getty), а значит благодаря возможности 86box пробрасывать виртуальный com-порт как устройство псевдотерминала на хостовую операционную систему, можно с помощью minicom, (c)kermit и других подобных утилит можно подключится к minix. 


> По причине того, что на момент написания данной инструкции, функция проброса com-порта не включена в релиз (*а это предварительно произойдет в v4.0*), в репозитории и есть AppImage. Промежуточная сборка была скачена с их [Jenkins](https://ci.86box.net/job/86Box/).

Однако на этапе установки, с коробки, нет возможности использовать getty, но очень легко это исправить. Для этого смонтируйте диску disk04 (современный Linux всё ещё понимает старую файловую систему minix) и добавьте 1 строку в файл `etc/ttys`.
```
$ sudo dist/minix/disk04.img <path>
$ echo '2f1' >> <path>/etc/ttys

$ cat <path>/etc/ttys

100
0f1
2f1 <- Добавлена строка
```
> В данной инструкции строка уже добавлена в disk04, но если хотите сделать это самостоятельно в репозитории есть оригинальная дискета [disk04.img.orig](https://github.com/olegslavkin/linux-0.01/raw/master/dist/minix/disk04.img.orig)

И далее можно подключится к Minix "удаленно". Псевдоустройство терминала `/dev/pts/7` как в данном случаи, будет отображено в stdout при старе эмулятора 86box.
```
$ minicom -o -c off -t vt100 -p pts/7 -b 9600
```
![minicom](https://habrastorage.org/webt/aj/vx/km/ajvxkmyalabtzzpfhhiukibnq1m.png)

## Разметка жесткого диска
Перед началом установки Minix необходимо разметить виртуальный жесткий диск. Для этого введите команду:
```
# fdisk -h8 -s17 /dev/hd0
```
Первая партиция диска `hd1`, размером в 5Мб и с файловой системой DOS, не будет использована в данном руководстве, но она специально оставлена как возможность установке MS-DOS.

Для создания партиции набираем следующие:
```
c
1
0  (first cylinder)
75 (last cylinder)
y  (change partition to active)
a
1  (active )
```
Вторая партиция диска `hd2`, также размером в 5Мб, с файловой системой Minix будет использован как корневой раздел (`/`).
```
c
2
76  (first cylinder)
512 (last cylinder)
n
```
Третья партиция `hd3` как `/usr`.
```
c
3
513 (first cylinder)
588 (last cylinder)
n
```

Четвертая партиция `hd4` пока не будет использована, оставлена на будущее (*для linux*).
```
c
4
589  (first cylinder)
1023 (last cylinder)
n
```
В результате получится, что-то подобное.
```
                          ----first----  -----last----  --------sectors-------
Num Sorted Active Type     Cyl Head Sec   Cyl Head Sec    Base    Last    Size
 1     1     A    DOS-BIG    0   0   2     75   7   16       1   10334   10334
 2     2          MINIX     76   0   1    150   7   17   10336   20535   10200
 3     3          MINIX    151   0   1    905   7   17   20536  123215  102680
 4     4          MINIX    906   0   1   1023   7   17  123216  139263   16048
```
Для внесения изменений и выхода из fdisk нажмите `w` и выполните команду `sync`. Перезагрузите виртуальную машину и загрузитесь как проделывали до этого выше. И после этого вновь выполните `fdisk` и убедитесь, что всё успешно записалось. Для выхода из `fdisk` вводим `q`.
```
# fdisk -h8 -s17 /dev/hd0

                          ----first----  -----last----  --------sectors-------
Num Sorted Active Type     Cyl Head Sec   Cyl Head Sec    Base    Last    Size
 1     1     A    DOS-BIG    0   0   2     75   7   16       1   10334   10334
 2     2          MINIX     76   0   1    150   7   17   10336   20535   10200
 3     3          MINIX    151   0   1    905   7   17   20536  123215  102680
 4     4          MINIX    906   0   1   1023   7   17  123216  139263   16048

(Enter 'h' for help.  A null line will abort any operation)
```
Далее необходимо отформатировать 3 minix партиции (раздела) жесткого диска файловой системой. Для этого, для каждой партиции, выполните команду `mkfs /dev/hdX <РАЗМЕР В БЛОКАХ>`, где `X` - это номер партиции, а `РАЗМЕР В БЛОКАХ` - это размер в партиции в блоках (по 1024 байта). Рассчитывается как размер секторов разделенный на 2. Соответственно введите:
```
# mkfs /dev/hd2 5100
# mkfs /dev/hd3 51340
# mkfs /dev/hd4 8024
```
## Установка (копирование) minix 1.5.10 на жесткий диск
После подготовки жестких дисков, можно запустить скрипт по установке Minux 1.5.10. Для установки minix на жесткий диск авторами был подготовлен sh скрипт. Для его запуска необходимо указать в качестве аргументов раздел корневого диска (в нашем случаи это `/dev/hd2`), размер `ram` в Мб, а также размеры в блоках всех 4-х партиций.

```
# /etc/setup_root /dev/hd2 4096 5139 5100 51340 8024
/dev/hd2 mounted
/dev/hd2 unmounted
```

Теперь вновь вставьте в виртуальный образ загрузочной дискеты `disk02` и отправьте виртуальную машину в перезагрузитесь.

После отображения загрузочного меню, необходимо изменить корневой раздел с которого будет производится загрузка. Во всех предыдущих шагах загружались с дискеты (`disk04`), но в этот раз необходимо загрузится с раздела жесткого диска. Для изменения корневого раздела в меню введите `r` (*select root device*), и далее `h2`, далее <ENTER> и после этого `=`.

![change-root](https://habrastorage.org/webt/nw/ng/uv/nwnguvvdq_gve20zcuwvfeuelgu.png)

Также, как в первом запуске, операционная система попросит вставить дискету с `/usr` (это `disk05`) и затем необходимо будет вновь авторизоваться как `root`.

> Если до этого подключилась с помощью minicom, но после загрузки с дискеты вновь можно будет подключится с minix.

Теперь необходимо проинициализировать раздел `/usr`. Для этого в терминале запускаем другой sh скрипт, указав в качестве аргумента партицию диска которая планируется использовать как `/usr`. В данном руководстве это `hd3`.
```
# /etc/setup_usr /dev/hd3
```
Запуститься процесс инициализации раздела `/usr`. В процессе данной инициализации, скрипт попросит вставить по очереди дискеты от `disk05` по `disk17`.

```
<Вырезано, оставлен вывод только последнего диска>

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
После копирования с дискет данных, тут же, автоматически, запуститься процесс распаковки архивов.
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
Так как только что инициализировали раздел `/usr`, то нет больше необходимости вставлять дискету `disk05` в начале процесса загрузки операционной системы. Теперь можно монтировать партицию диска `hd3` как `/usr`. Для этого надо немного исправить `/etc/rc`.
```
# mined /etc/rc
```
> Если редактирование производите в `minicom` и подобных утилитах, то возможно при скроллинге будут не корректно работать настройки терминала. Для этого можно открыть редактор в окне эмулятора.

И комментируем (можно удалить) строки монтирования дискеты (а также приглашение вставки дискеты) и добавляем запись монтирования раздела жесткого диска.
```
#/bin/getlf "Please insert /usr diskette in drive 0.  Then hit ENTER."
#/etc/mount /dev/fd0 /usr               # mount the floppy disk
/etc/mount /dev/hd3 /usr                # mount the hard disk
```
Опиционально, устанавливаем более высокую скорость serial порта.
```
# Initialize the first RS232 line to 9600 baud.
/usr/bin/stty 9600 </dev/tty1
```
В редакторе `mined` сохраняем изменений производится комбинаций `<CTRL+W>`, а выход из редактора `<CTRL+X>`. Вводим команду `sync`, проверяем, что у нас вставлена загрузочная дискета `disk02.img` и вновь перезагружаемся.

После загрузки выбираем, как в прошлый раз `r` -> `h2` и нажимаем `=`. Такие действия необходимо будет производить каждый раз при загрузке операционной системы.

## Тестирование работосопособности Minix
Чтобы убедится, что операционная система установлена корректно, разработчиками были подготовлены тестовые программы и sh скрипты, которые необходимо скомпилировать и запустить на исполнение. Для проведения тестирования необходимо перейти в каталог и запустить компиляцию. Рекомендуется компилировать как `root` (на последнем этапе устанавливаются права доступа на файлы)

```
# cd /usr/src/test
# make all
```
Процесс компиляции тестовых программ, если хотите тест-кейсов.
```
cc -F -D_MINIX -D_POSIX_SOURCE -o test0 test0.c;                chmem =8192  test0
test0: Stack+malloc area changed from 56042 to 8192 bytes.
cc -F -D_MINIX -D_POSIX_SOURCE -o test1 test1.c;                chmem =8192  test1
test1: Stack+malloc area changed from 59024 to 8192 bytes.
cc -F -D_MINIX -D_POSIX_SOURCE -o test2 test2.c;                chmem =8192  test2
test2: Stack+malloc area changed from 58086 to 8192 bytes.
cc -F -D_MINIX -D_POSIX_SOURCE -o test3 test3.c;                chmem =8192  test3
test3: Stack+malloc area changed from 58816 to 8192 bytes.
cc -F -D_MINIX -D_POSIX_SOURCE -o test4 test4.c;                chmem =8192  test4
test4: Stack+malloc area changed from 58982 to 8192 bytes.
cc -F -D_MINIX -D_POSIX_SOURCE -o test5 test5.c;                chmem =8192  test5
test5: Stack+malloc area changed from 54974 to 8192 bytes.
cc -F -D_MINIX -D_POSIX_SOURCE -o test6 test6.c;                chmem =8192  test6
test6: Stack+malloc area changed from 59156 to 8192 bytes.
cc -F -D_MINIX -D_POSIX_SOURCE -o test7 test7.c;                chmem =8192  test7
test7: Stack+malloc area changed from 49378 to 8192 bytes.
cc -F -D_MINIX -D_POSIX_SOURCE -o test8 test8.c;                chmem =8192  test8
test8: Stack+malloc area changed from 58098 to 8192 bytes.
cc -F -D_MINIX -D_POSIX_SOURCE -o test9 test9.c;                chmem =8192  test9
test9: Stack+malloc area changed from 57486 to 8192 bytes.
cc -F -D_MINIX -D_POSIX_SOURCE -o test10 test10.c;      chmem =8192  test10
test10: Stack+malloc area changed from 57522 to 8192 bytes.
cc -F -D_MINIX -D_POSIX_SOURCE -o test11 test11.c;      chmem =8192  test11
test11: Stack+malloc area changed from 57490 to 8192 bytes.
cc -F -D_MINIX -D_POSIX_SOURCE -o test12 test12.c;      chmem =8192  test12
test12: Stack+malloc area changed from 60678 to 8192 bytes.
cc -F -D_MINIX -D_POSIX_SOURCE -o test13 test13.c;      chmem =8192  test13
test13: Stack+malloc area changed from 58574 to 8192 bytes.
cc -F -D_MINIX -D_POSIX_SOURCE -o test14 test14.c;      chmem =20000 test14
test14: Stack+malloc area changed from 59476 to 20000 bytes.
cc -F -D_MINIX -D_POSIX_SOURCE -o test15 test15.c;      chmem =8192  test15
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
cc -F -D_MINIX -D_POSIX_SOURCE -o test16 test16.c;      chmem =8192  test16
test16: Stack+malloc area changed from 54988 to 8192 bytes.
cc -F -D_MINIX -D_POSIX_SOURCE -o test17 test17.c;      chmem =8192  test17
test17: Stack+malloc area changed from 43274 to 8192 bytes.
cc -F -D_MINIX -D_POSIX_SOURCE -o test18 test18.c;      chmem =8192  test18
test18: Stack+malloc area changed from 46508 to 8192 bytes.
cc -F -D_MINIX -D_POSIX_SOURCE -o test19 test19.c;      chmem =8192  test19
test19: Stack+malloc area changed from 54990 to 8192 bytes.
cc -F -D_MINIX -D_POSIX_SOURCE -o test20 test20.c;      chmem =65000 test20

```

Для самих запусков тестов, рекомендуется авторизоваться как обычный пользователь, а не `root`. Авторизуйтесь как `ast` с паролем `Wachtwoord`.
```
$ cd /usr/src/test
$ run
```

Если все тесты были успешно пройдены, то дополнительно запустите два тестовых shell скрипта `sh1` и `sh2`.
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
> При запуске в minicom могут появится фантомные ошибки, после повторного запуска, ошибки обычно исчезают.

## Резервное копирование промежуточной точки
На этом этапе можно поставить эмулятор паузу и сохранить образ жесткого диска, настройки bios, а также конфигурационный файл самого эмулятора. Это очень поможет в будущем, если необходимо будет откатить изменения.
```
tar cvfJ backups/minix-1.5.10-install-hda.tar.xz disks/minix.img nvr/acc386.nvr 86box.cfg
```

# Установка патчей от Брюса Аванса (Bruce Evans' 386 patches) ака minix-386 <a name="minix-386"></a>
В предыдущем разделе была установлена классическая 16-битная версия Minix 1.5.10, в том виде как и изначально задумывалась автором, но цель этого руководства - это пройти шаги сделанные Линусом Торвальдсом по написанию собственной операционной системы Linux (*ну ладно, ладно не все шаги, сам Linux писать не будем :)*). Как мы знаем из многочисленных источников, как с вышеупомянутой книги J4F, так и c многочисленных интервью, Линус работал не в оригинальной, а в пропатченной версии Minux 1.5.10, также известный как minix-386. Преобразующие патчи были подготовлены Брюсом Эвансом, а Джоном Наллом (John Nall) был написан [прекрасное руководство](https://github.com/olegslavkin/linux-0.01/raw/master/dist/minix-386/tutor.asc) по их применению.

Но прежде, чем мы начнем преображение, необходимо немного "апгрейдить" наш виртуальный PC. Изначально, при установке классического Minix, были задействован дисковод 5.25 на 360Кб. Только установив данный тип виртуального дисковода в настройках эмулятора и BIOS, мне удалось произвести установку и написать это руководство. Но для загрузки 32-битной версии Minix понадобятся уже 5.25 1.2 Мб дискеты (*а также позже для Linux*), соответственно необходимо, убедиться, что в настройках эмулятора указан соответствующий тип дисковода, а в BIOS также установлен этот же тип.

![86box_floppy](https://habrastorage.org/webt/4w/py/fq/4wpyfqmjbllooyqxqzfk1hq8cv8.png)
![1_2M_FDD](https://habrastorage.org/webt/y0/mv/yw/y0mvywl-hvryhlyb1ate7zndmda.png)

Загружаемся как обычно с загрузочной дискеты `disk02`, не забываем при этом указать в качестве корневого раздела партицию `h2` при загрузке. Авторизуемся как `root`. Далее вместо загрузочной дискеты, в эмуляторе, вставляем дискету с патчами от Брюса Эванса [minix-386](https://github.com/olegslavkin/linux-0.01/raw/master/dist/minix-386/minix-386.img), создаем каталог `/usr/oz`, монтируем дискету и копируем все файлы.
> Файлы содержащие на дискете были взяты из [архива](http://www.oldlinux.org/Linux.old/study/linux-travel/minix-386/zhao.rar) с сайта oldlinux.org. Кроме патчей там есть есть полезные файлы.

```
mkdir /usr/oz
cd /usr/oz
/etc/mount /dev/at0 /user
cp /user/* /usr/oz
/etc/umount /dev/at0
sync
```

Подготавливаем загрузочную дискету. Вставляем дискету [shoelace.img](https://github.com/olegslavkin/linux-0.01/raw/master/dist/minix-386/shoelace.img) и форматируем её.
```
mkfs /dev/at0 1200
```
Переходим в каталог с архивами и распаковываем их.
```
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
Далее создаем папку для загрузчика и распаковываем его.
```
mkdir /usr/oz/shoelace
mv shl-1.0a.t.Z shoelace
cd shoelace
compress -d shl-1.0a.t.Z
tar xvf shl-1.0a.t
rm shl-1.0a.t shl-1.0a.t.Z
```
Создаем папку для компилятора bcc, распаковываем архивы с 16 и 32 битной версии компилятора bcc, и исходными коды стандартной библиотеки Си.
```
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
Распаковываем архив с патчами minix-386, а также для удобства работы, переименовываем директорию в mx386.
```
cd /usr/oz
tar xvf mx386_1.1.t
mv mx386_1.1 mx386
rm mx386_1.1.t
```
Распаковываем небольшой патч на патч minix-386.
```
cd /usr/oz
unshar < mx386_1.1.01
rm mx386_1.1.01
mv klib386.x* /usr/oz/mx386/kernel
```
Переходим в папку с патчами ядра и применяем только что распакованный патч
```
cd /usr/oz/mx386/kernel
patch klib386.x klib386.x.cdif
```
Монтируем загрузочную дискету (*в дисковод всё ещё должна быть вставлена дискета `shoelace`*), создаем необходимые директории и копируем директории `dev` и `etc`.
```
/etc/mount /dev/at0 /user
cd /user
mkdir usr
mkdir user
cd /
cpdir -s dev /user/dev
cpdir -ms etc /user/etc
```
Удаляем 16-битные версии программы
```
cd /user/etc
rm mount umount update
```
Комментируем строку с монтированием диска как `/usr`.
```
mined /user/etc/rc # comment /etc/mount /dev/hd3 /usr
```
В корне создаем папку `/local` и копируем в нее 16/32-битные версии компиляторов.
> Использование `/local` обязательно. Если он не подходит, по каким-то причинам, необходимо будет его изменить `bcc.c` и перекомпилировать компилятор.

```
cd /
mkdir local

cd /usr/oz/bcc
cpdir -ms bccbin16 /local/bin
cpdir -ms bccbin32 /local/bin3

cd /usr/oz/mx386
cpdir -ms bin0 /local/bin  # 16-bit compiler stuff
cpdir -ms bin3 /local/bin3 # 32-bit compiler stuff
```
Копируем патчи для ядра Minix в директорию с исходным кодом ядра, а также копируем патчи для заголовочных файлов.
```
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
Применяем патчи заголовочных файлов
```
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
Сохраняем (*не удаляем, он уже будет нужен*) оригинальный бинарный make и компилируем без флага `-DMINIXPC`.
```
cd /usr/bin
mv make make_s
cd /usr/src/commands/make
mined Makefile # Оставить только "CFLAGS = -Dunix"
make_s
mv make /usr/bin
```
Добавляем в PATH путь до компиляторов bcc, а также переименовываем оригинальный компилятор Си (сс) и делаем симлинк.
```
PATH=/local/bin:$PATH
export PATH
cd /usr/bin
mv cc cc_old
cd /local/bin
ln bcc cc
```
Производим компиляцию 16-ти битную версию библиотеки `libc.a` и `longlib.a`.
```
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
Компилируем 32-ти битную версию библиотеки.
```
cd /usr/src/lib/bcc
sh makelib 86 clean

sh makelib 386 | tee problems.out 2>&1

cd /usr/src/lib/bcc/i386
mkdir /usr/local/lib/i386
cp * /usr/local/lib/i386
cd ..
sh makelib 386 clean
```
Создаем директорию где будут сохранены компоненты ядра Minix.
```
cd /etc
mkdir system
```
Производим компиляцию компонентов ядра. Обратите внимание, что при редактирование makefile.cpp, необходимо чтобы все строки препроцессора cpp начинались с начала строки.
В процессе линковки могут появится предупреждения `warning: _exit (или _unlock или _lock) redefined` необращаем на предупреждение внимание, как тут так и в других частях данного руководства.
```
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
При редактирование `xx` удалите все комментарии, которые не относятся к синтаксису препроцессора `cpp`, а также лишние символы табуляции в таких выражении как `#define O       s`, `#if INTEL_32BITS`, `#else`, `#endif`.
```
cd /usr/src/kernel
cp makefile.cpp xx
mined xx              # remove all of the comment lines
rm -f *.s *.o
sh config 386         # set up proper files.
/usr/lib/cpp -P -DINTEL_32BITS xx > makefile
make                  # generate  /etc/system/kernel
```
Компилируем `init`. В процессе линковки также могут появится предупреждения `warning: _exit (или _sbrk) redefined`, которые можно смело игнорировать.
```
cd /usr/src/tools
cc -3 -c -D_POSIX_SOURCE -D_MINIX init.c
ld -3 -o /etc/system/init /usr/local/lib/i386/head.o \
   init.o /usr/local/lib/i386/libc.a
```
Компилируем загрузчик shoelace, но для этого временно возвращаем оригинальный make и cc.
```
cd /usr/bin
mv cc_old cc
mv make make_o
mv make_s make
PATH=/usr/bin:/bin
export PATH
cd /usr/oz/shoelace
mined shoe.c          # Заменить <varargs.h> на "varargs.h"
make -f makefile.min
```
Создаем загрузочный сектор на дискете и копируем бинарные файлы загрузчика, его конфигурационные файлы и компоненты ядра minix.
```
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
# Закомментировать run	/etc/system/db
# Заменить на
setdev rootdev /dev/at0
```
Возвращаем make и сс, а также переменную PATH в прежнее состояние.
```
cd /usr/bin
mv cc cc_old
mv make make_s
mv make_o make
PATH=/local/bin:$PATH
export PATH
```
Компилируем 32-х битный sh
```
cd /user
mkdir bin
cd /usr/src/commands/sh

rm -f *.s *.o
cc -3 -D_POSIX_SOURCE -o /user/bin/sh *.c
```
Компилируем другие минимально необходимые программы.
```
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

Убеждаемся, что дисковод по прежнеум вставлена дискета с shoelace и перезагружаем компьютер.

Добро пожаловать в Minix-386!
![minix-386](https://habrastorage.org/webt/fd/kh/mr/fdkhmrv3fdmlkmnb_jsdszpg9cc.png)

Не обращяем внимание, что часть программ `readclock`, `date`, `wtmp`, `printroot` и `stty` задействованные иницилизирующем скриптом `/etc/rc` не смог запуститься. В следующем разделе данного руководства исправим это.
![minix-386-not-found](https://habrastorage.org/webt/gy/xk/nu/gyxknupcepkzdeqd6yqcnk15rx0.png)

## Резервное копирование промежуточной точки
Ставим эмулятор на паузу и сохраняемся.
```
tar cvfJ backups/minix-386-1.5.10-stage1.tar.xz disks/minix.img dist/minix-386/shoelace.img nvr/acc386.nvr 86box.cfg
```

# Компиляция стандартных утилит 1.5.10 под архитектуру i386 <a name="i386bin"></a>
После того, как проверили, что с дискеты успешно загрузились с новым ядром, необходимо произвести перекомпиляцию утилит. И для этого загружаемся в 16-битный minix (используем дискету `disk02` и раздел жесткого диска `h2`). И выполним кросс-компиляцию 80386 версий бинарных утилит.

Чтобы упростить процесс я подготовил Makefile и вспомогательный sh скрипт. Распаковываем архив с Makefile его и запускаем компиляцию.
```
cd /usr/oz
compress -d bin32.tar.Z
tar xvf bin32.tar && rm bin32.tar
/tmp/bin32.sh | tee problems.out 2>&1
```
Создаем директорию для 32-х битной версии ядра и переносим туда скомпилированные на предыдущем этапе компоненты ядра.
```
mkdir /etc/system3
cd /etc/system/
mv kernel fs mm init /etc/system3
```
Переносим бинарные файлы в `/bin`. 
> Да, с точки зрения minix, это возможно не канон, но так можно иметь как 16-ти, так и 32-х битные их версии программ, а также проще переключатся между режимами. Да, и просто я уже привык, что mount/umount находится в PATH.

```
cd /etc
mv mount umount update /bin
```

Размонтируем дискету (если в дисководе, что-то отличное от `shoelace`, поменяйте дискету на shoelace и примонтируйте ее. Меняем в конфигурационном файде загрузчика значение `rootdev` с дискеты (`at0`) на диск (`hd2`) и меняем пути для `mount`/`update`.
```
umount /dev/at0
mount /dev/at0 /user
mined /user/etc/config
# setdev rootdev /dev/hd2 <- заменить на раздел HDD

mined /etc/rc
# /bin/mount /dev/hd3 /usr <- заменить на /bin/
# /bin/update  &           <- заменить на /bin/

sync
```
Производим переименование директорий. Не спешите перезагружаться!
```
/local/bin/bin3
```
Скрипт, который выполнили только, что не переименовывает `/usr/binX` директорию. Сделает это вручную.
```
/bin0/mv /usr/bin /usr/bin0
/bin0/mv /usr/bin3 /usr/bin
```

Вот теперь можно перезагрузится и добро пожаловать в Minix-386 (снова)!
![minix-386-again](https://habrastorage.org/webt/j7/kl/u3/j7klu3cww5klhkaqexhnonhqkbe.png)

## Резервное копирование промежуточной точки
Ставим эмулятор на паузу и сохраняемся.
```
tar cvfJ backups/minix-386-1.5.10-stage2.tar.xz disks/minix.img dist/minix-386/shoelace.img nvr/acc386.nvr 86box.cfg
```

## Возврат 16-битную версию (для информации)
Если необходимо возвратится в 16-ти битную версию, то нужно просто переименовывать пути до бинарных файлов, вставить дискету disk02 (и использовать раздел жесткого диска `h2` как корневой раздел).
```
/local/bin/bin0
/bin3/mv /usr/bin /usr/bin3
/bin3/mv /usr/bin0 /usr/bin
/bin3/sync
```
## Утилиты которых нет в версии 80386
Часть утилит нет в 32-х битной версий minix. Нет клона emacs [elle](https://www.unix.com/man-page/minix/9/elle/) (это файлы файлы `elle`, `ellec`), т.к. в оригинальных дискетах нет на них исходных кодов. 

Не компилируется в bcc `cpdir` и `ttt`, это известная проблема. На `cpdir` есть fix. А вот есть ли fix на `ttt`, неизвестно. Сам по себе `ttt` - это игра "Tic Tac Toe" или "Крестики-Нолики", мне она была не к чему. 

Нет необходимости в утилитах `ast` и `cc`, т.к. используется компилятор `bcc`. Нет исходных файлов на `pc` - The Minix [Pascal Compiler](https://www.krsaborio.net/unix-source-code/research/1987/1014-a.html), но возможно это просто симлинк на `cc`. 

Также у меня не работает `compress` (а также его симлинки `uncompress` и `zcat`), но позже с установкой gcc поставим работающий `compress`.

# Установка патча для сопроцессора 387
Вставляем дискету с shoelace и для компиляции ядра мигрируем, временно, в 16-ти битную версию.
```
/local/bin/bin0
/bin3/mv /usr/bin /usr/bin3
/bin3/mv /usr/bin0 /usr/bin
/bin3/sync
```
Вставляем дискету disk02 и перезагружаемся. После перегрузки вставляем дискету с [gcc-1.37.1](https://github.com/olegslavkin/linux-0.01/raw/master/dist/gcc-1.37.1-plains/awb-gcc-1.37.1.img)

Копируем патч ядра имитирующий наличие сопроцессора 387. Вообще этот патч является частью gcc-1.37.1 и как я понял устанавает во 2-й бит регистра `CR0`, "говорящий" компилятору, что у нас нет сопроцессора 387. Этот патч обязателен, в противном случаи, в будущем, не получится собрать ядро linux, получим ошибку компиляции вида `fp stack overflow`. После применения патча необходимо пересобрать ядро (*только kernel*) minix-386.
```
/bin/mount /dev/at0 /user
cp /user/klib386.cdiff /usr/src/kernel
cd /usr/src/kernel
PATH=/local/bin:/usr/bin:bin
export PATH
patch < klib386.cdiff
rm -f *.s *.o
make
```
Копируем ядро на загрузочную дискету. Размонтируем вставленную дискету, и вставляем дискету shoelace, монтируем ее и копируем ядро.
```
/bin/umount /dev/at0
/bin/mount /dev/at0 /user
mv /etc/system/kernel /etc/system3
cp /etc/system3/kernel /user/etc/system
sync
```
Мигрируем обратно на minix-386.
```
/local/bin/bin3
/bin0/mv /usr/bin /usr/bin0
/bin0/mv /usr/bin3 /usr/bin
/bin0/sync
```
## Резервное копирование промежуточной точки
Ставим эмулятор на паузу и сохраняем текущее состояние.
```
tar cvfJ backups/minix-386-1.5.10-stage3.tar.xz disks/minix.img dist/minix-386/shoelace.img nvr/acc386.nvr 86box.cfg
```

# Установка компилятора GCC-1.37.1 от Alan W Black и Richard Tobin
Как известно ядро linux было скомпилировано с помощью gcc. И в оригинале это был собственная пропатченная версия gcc 1.40 от Линуса с поддержкой опции `-mstring-insns`. Где сейчас можно найти именно эту версию компилятора мне не известно. Возможно это та [самая версия](http://www.oldlinux.org/Linux.old/Linux-0.10/binaries/compilers/gccbin.tar.Z). В архиве файлы датированы 22 сентября 1991, очень-очень близкие к тем временам, с другой стороны эти даты нельзя ориентироваться. Я же пойду немного другим путем и буду использовать версию gcc-1.37.1 от Alan W Black и Richard Tobin, также известный как "awb-gcc from plains" иногда в сети её называли, просто "gcc from plains".

Загружаемся с дискеты shoelace, а затем меняем её на дискету c [gcc-1.37.1](https://github.com/olegslavkin/linux-0.01/raw/master/dist/gcc-1.37.1-plains/awb-gcc-1.37.1.img), монтируем ее и копируем 16-ти версию утилиты compress (*в minix использовалась [13-ти версия](https://www.unix.com/man-page/minix/1/compress/)*).
```
mount /dev/at0 /user
cp /user/16bcompress /usr/bin
chmod 755 /usr/bin/16bcompress
```
Копируем бинарные файлы gcc во временную папку и распаковываем и устанавливаем их.
```
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
Устанавливаем заголовочные файлы.
```
cd /usr/tmp
tar xvf gccinc.tar
cd gccinc
mkdir /usr/local/lib/gcc/gcc-include
mv * /usr/local/lib/gcc/gcc-include
cd /usr/tmp
rm -fr gccinc*
```
Устанавливаем библиотеки Си.
```
cd /usr/tmp
tar xvf gcclib.tar
cd gcclib
cp /usr/lib/libc.a /usr/lib/libc.a.orig # вдруг будет необходима
cp libc.a /usr/lib/libc.a
cp libm.a /usr/lib/libm.a
cp gnulib /usr/local/lib/gcc/gnulib
cp crt0.o /usr/local/lib/gcc/crt0.o
cd /usr/tmp
rm -rf gcclib*
```
Тестируем компилятор, напишем традиционный "Hello World".
```
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
На выходе получим, тоже, традиционный a.out. Но если попробовать запустить его напрямую, то получим ошибку
```
a.out
: not found
```
Всё дело в том, что gcc генерирует бинарный файл напрямую несовместимый с minix. Есть два пути решения. Первый - это сконвертировать в совместимый формат с помощью gcc2minix который входил в комплект gccbin.
```
gcc2minix < a.out > test
chmod +x test
./test
Hello World
```
Второй вариант - это использовать патч [gnutoo](https://www.cs.cmu.edu/~awb/pub/minix/gnutoo.tar.gz), у меня он не заработал, но возможно я что-то сделал не правильно.

## Резервное копирование
Ставим эмулятор на паузу и сохраняем текущее состояние.
```
tar cvfJ backups/minix-386-1.5.10-gcc1.37.1.tar.xz disks/minix.img dist/minix-386/shoelace.img nvr/acc386.nvr 86box.cfg
```

# Компиляция ядра Linux 0.01 и попытка загрузиться <a name="linux-0.01"></a>
И вот, наконец-то, после всех этапов подготовки можно приступить непосредственно к компиляции ядра Linux, но для этого ещё немного подготовится :). Помните, в самом начале, когда разбивали жесткий диск на разделы, у нас остался не использованный раздел `h4`, его оставили как раз для Linux.
```
mkdir /linux
mkfs /dev/hd4 8024
mined /etc/rc
# добавить, можно сразу после строки монтирования /dev/hd3
# /bin/mount /dev/hd4 /linux              # linux
/bin/mount /dev/hd4 /linux
```
Создадим необходимые каталоги
```
cd /linux
mkdir usr
mkdir tmp
cd usr
mkdir src
```
Вставляем дискету с исходными кодами Linux [linux-src-0.01](https://github.com/olegslavkin/linux-0.01/raw/master/dist/linux/src.img) и монтируем дискету. Сам архив 
[linux-0.01.tar.Z](http://www.oldlinux.org/Linux.old/Linux-0.01/sources/system/linux-0.01.tar.Z) с сайте oldlinux.org. Примечательно, что на официальном сайте ядра Linux имеется [tar.gz версия](https://mirrors.edge.kernel.org/pub/linux/kernel/Historic/linux-0.01.tar.gz) от октября 1993 (*ядро 0.01, я напомню, ["родилось" 17.09.1991](https://lkml.org/lkml/2021/9/17/1018)*) это скорее всего "перепак" в формат архива поддерживаемый gnu утилитами того времени.
```
/bin/mount /dev/at0 /user
cp /user/linux.tar.Z /linux/tmp
16bcompress -d /linux/tmp/linux.tar.Z
cd /linux/usr/src
tar xvf /linux/tmp/linux.tar
rm /linux/tmp/linux.tar
cd linux
```
Адаптация ядра под gcc-1.37.1
```
mined Makefile

# Добавялем путь до gnulib
LIBS    =lib/lib.a /usr/local/lib/gcc/gnulib

# Приводим к следующему виду
# Не забывайте, что в Makefile отступ от начала строки разделяет символ табуляции (!)
tools/build: tools/build.c
        $(CC) $(CFLAGS) \
        -o tools/a.out tools/build.c
        gcc2minix < tools/a.out > tools/build
        chmod +x tools/build
        chmem +65000 tools/build

# Удаляем `-mstring-insns` из CFLAGS
mined fs/makefile
mined kernel/Makefile
mined lib/Makefile
```
Адаптируем под наше "железо", используем дискеты на 5.25 на 1.2М вместо 3.5, задаем верхнею границу оперативной памяти, а также указываем, что будем использовать раздел `h4` жесткого диска и его характеристики.

> Вот на этапе и чуть ниже, у меня есть сомнения, что у Линуса был компьютер с 4Мб оперативной памяти, скорее всего у него было 8Мб. Возможно, при покупке, было действительно 4, но потом был доукомплектован до 8Мб, как, возможно, собственно и 2-й жесткий диск.

```
# Указываем, что будем использовать 1.2Mb
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
Добавляем в PATH пути до компиляторов и ассемблера, а наконец компилируем.
```
PATH=/usr/local/bin:/local/bin:/bin:/usr/bin
export PATH
make
```
Если компиляция пройдет успешно, то в папке с ядром появится файл `Image`. Это и есть наше ядро Linux.
```
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
tools/build boot/boot tools/system > Image <---- это Linux!!!
Boot sector 452 bytes.
System 93184 bytes.
sync
```

Но, возможно, у вас, как и у меня, компиляция может упасть с ошибкой:
```
gcc: installation problem, cannot exec /usr/local/lib/gcc/gcc-cc1: No more processes
```
Это происходит, как я понял, из-за малого размера оперативной памяти (напомню мы используем 4Мб). И тут есть 2 решения: а) в настройках эмулятора временно увеличить до 8Мб или б) осуществить сборку в несколько этапов.
```
cd kernel && make
cd ../mm  && make
cd ../fs  && make
cd ../lib && make
cd ..     && make
```
После успешной компиляции создаем необходимые директории и устройства
```
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
Вставляем дискету [bin](https://github.com/olegslavkin/linux-0.01/raw/master/dist/linux/bin.img) c готовыми бинарными [bash](http://www.oldlinux.org/Linux.old/gnu/bash/bash-1.05-linux.tar.gz) и [update](http://www.oldlinux.org/Linux.old/Linux-0.01/binaries/sbin/update.Z). 
> bash не оригинальный, скомпилирован в 2004 году, скорее всего Jiong Zhao (автором сайта oldlinux.org). В оригинале должен использоваться [bash-1.08](https://ru.wikipedia.org/wiki/%D0%AF%D0%B4%D1%80%D0%BE_Linux#cite_note-minix-10), но мне не удалось найти, как бинарные, так и исходные коды данной версии.

```
/bin/mount /dev/at0 /user
cp /user/bash /linux/bin/sh
cp /user/update /linux/bin/update
```
Вставляем чистую дистеку [boot](https://github.com/olegslavkin/linux-0.01/raw/master/dist/linux/boot.img) и записываем на нее ядро.
```
/bin/umount /dev/at0
cd /linux/usr/src/linux

dd if=Image of=/dev/at0
183+0 records in
183+0 records out
```
И перезагружаем компьютер. И поздравляю, вы в Linux-0.01 с [финской](https://upload.wikimedia.org/wikipedia/commons/1/1c/IBM_model_M2_for_Sweden_and_Finland.jpg) раскладкой и [это хардкод](http://www.oldlinux.org/Linux.old/Linux-0.01/docs/RELNOTES-0.01).

![linux-0.01](https://habrastorage.org/webt/nn/yy/qp/nnyyqp3ss4bk1plc0y4_gjspn-4.png)

## Полезное
В bash нет традиционных bin-утилит, даже обычно `ls`, но его можно эмулировать.
```
alias ls='echo *'
```

## Резервное копирование
Ставим эмулятор на паузу и сохраняем текущее состояние.
```
tar cvfJ backups/minix-386-1.5.10-linux-0.01.tar.xz disks/minix.img dist/minix-386/shoelace.img dist/linux/boot.img nvr/acc386.nvr 86box.cfg
```

# Разное <a name="other"></a>
1. В исходных дискетах minux нет файл ckcpro.c от kermit (он должен генерироваться через wart), поэтому я взял готовый от сюда https://www.tuhs.org/cgi-bin/utree.pl?file=Minix1.5/commands/kermit
