# Введение
Я попытался повторить, насколько это возможно, действия Линуса Торвальдса по компиляции и запуску самой первой версии ядра Linux 0.01. Причины, побудившие Линуса начать разработка ядра, хорошо описаны в книге «[Ради удовольствия: Рассказ нечаянного революционера](https://ru.wikipedia.org/wiki/%D0%A0%D0%B0%D0%B4%D0%B8_%D1%83%D0%B4%D0%BE%D0%B2%D0%BE%D0%BB%D1%8C%D1%81%D1%82%D0%B2%D0%B8%D1%8F)» (далее J4F) и во множестве других источниках и мы не будем их касаться. А рассмотрим техническую сторону компиляции и запуску ядра Linux.

Непосредственно процесс сборки ядра по-unix'овски очень прост: достаточно выполнить команду make, и на выходе получаете готовый бинарный файл, который надо записать на дискету и загрузиться с неё. Но чтобы сборка прошла успешно, надо провести большую подготовку. Вот этим мы и займёмся. Я составил для вас очень подробное пошаговое руководство.

Сначала в эмуляторе [86Box](https://86box.readthedocs.io/) создадим пустую виртуальную машину с характеристиками, близкими к компьютеру Линуса в то время, установим оригинальную версию операционной системы Minix 1.5.10, применим патчи «царя и бога Minix-386» (c) Брюса Эванса, поставим порт компилятора gcc версии 1.37.1 для Minix-386 от [Алана Блэка](https://www.cs.cmu.edu/~awb/) (Alan W Black) и [Ричарда Тобина](https://www.cogsci.ed.ac.uk/~richard/) (Richard Tobin), и в самом конце соберём и запустим ядро Linux с bash'ем внутри.

После каждого этапа я сохранял состояние виртуальной машины, жёсткого диска и образы дискет, которые подвергались изменению. Можете пройти все шаги самостоятельно или распаковать любой из архивов и продолжить выполнение инструкции с желаемого момента. Все дистрибутивы, скриншоты, конфигурации, это руководство, архивы с резервными копиями по каждому этапу и даже бинарный AppImage 86box (для Linux x86_64) можно найти в [репозитории](https://github.com/olegslavkin/linux-0.01).

Приступим.

---

# Оглавление<a name="toc"></a>
- [Введение](#введение)
- [Оглавление](#оглавление)
- [Предположительные характеристики PC Линуса Торвальдса](#предположительные-характеристики-pc-линуса-торвальдса)
- [Предварительные условия](#предварительные-условия)
- [Установка оригинальной 16-битной версии Minix 1.5.10](#установка-оригинальной-16-битной-версии-minix-1510)
  - [Загрузка Minix 1.5.10](#загрузка-minix-1510)
  - [Разметка жёсткого диска](#разметка-жёсткого-диска)
  - [Установка (копирование) Minix 1.5.10 на жёсткий диск](#установка-копирование-minix-1510-на-жёсткий-диск)
  - [Тестирование работоспособности Minix](#тестирование-работоспособности-minix)
- [Установка патчей от Брюса Эванса (Bruce Evans' 386 patches) ака Minix-386 ](#установка-патчей-от-брюса-эванса-bruce-evans-386-patches-ака-minix-386-)
- [Компиляция стандартных утилит 1.5.10 под архитектуру i386 ](#компиляция-стандартных-утилит-1510-под-архитектуру-i386-)
- [Установка патча для сопроцессора 387 ](#установка-патча-для-сопроцессора-387-)
- [Установка компилятора GCC-1.37.1 от Alan W Black и Richard Tobin ](#установка-компилятора-gcc-1371-от-alan-w-black-и-richard-tobin-)
- [Компилируем и запускаем ядра Linux 0.01 ](#компилируем-и-запускаем-ядра-linux-001-)
- [Заключение](#заключение)
- [P.S.](#ps)
- [P.S.S](#pss)

---

# Предположительные характеристики PC Линуса Торвальдса<a name="linus-pc"></a>
Прежде чем начать сборку и компиляцию Linux нужно определиться с условиями, в которых приходилось работать Линусу Торвальдсу. В первую очередь интересует, какой у него был персональный компьютер и его характеристики. Да, мы достоверно знаем, на каком процессоре он работал, и ещё некоторые параметры, но я нигде в интернете не встречал (или плохо искал?) полную спецификацию его ПК. Поэтому решил на основе различных открытых источников провести «исследование» по этому вопросу. Вот на каком «железе», **по моему мнению**, работал автор ядра Linux. 

| Аппаратное обеспечение  |   Производитель, модель  |
|-------------------------|:-------------------------|
| SVGA Монитор, 14 дюймов    	| GoldStar 1460 Plus<sup>[1](#note-j4f) [2](https://usenetarchives.com/view.php?id=comp.sys.ibm.pc.hardware&mid=PDEwNDE0QGh5ZHJhLkhlbHNpbmtpLkZJPg)</sup> |
| Системный блок      	| Н/Д. «Простой серый системный блок»<sup>[3](#note-j4f)</sup> |
| Материнская плата   	| Н/Д |
| CPU                 	| Intel 386DX, 33 МГц<sup>[4](#note-j4f)</sup> |
| FPU                 	| Intel 387<sup>[5](#note-387)</sup> |
| RAM                 	| 4 (или скорее всего 8) Мб<sup>[6](#note-ram)</sup> |
| Video               	| Производитель неизвестен, на основе ET4000 с 1 Мб памяти<sup>[7](#note-video)</sup> |
| FDD A               	| Дисковод 3,5 дюйма, 1,44 Мб<sup>[8](#note-35fdd)</sup> |
| FDD B               	| Дисковод 5,25 дюйма, 1,2 Мб<sup>[9](#note-dualfdd)</sup> |
| HDD C               	| Conner CP3044 IDE Type 17<sup>[10](#note-hdd)</sup> |
| HDD D               	| Conner CP3044 IDE Type 17 |
| Modem               	| Производитель неизвестен<sup>[11](#note-modem)</sup> |
| Клавиатура          	| Финская клавиатура, производитель неизвестен |

Примечания по таблице:
- [1] Размер дисплея был упомянут в J4F. <a name="note-j4f"></a>
- [5] Сопроцессор 387 появился в процессе разработки ядра. <a name="note-387"></a>
- [6] В J4F описывалось, что было 4 Мб (скорее всего, такой объём был изначально), но в книге Линус пишет: «Помню, мне пришлось выйти из дома, чтобы увеличить ОЗУ с 4 до 8 мегабайт», и непонятно, осталась эта дополнительная память в его ПК или он взял её у кого-то временно. Я думаю, что осталась, потому что в ядре 0.01 в нескольких местах указано, что уже 8 Мб. <a name="note-ram"></a>
- [7] "Счастливый обладатель" [ET4000 EVGA](https://www.tech-insider.org/linux/research/1991/0304.html), а при покупке [возможно](https://usenetarchives.com/view.php?id=comp.sys.ibm.pc.hardware&mid=PDEwNDE0QGh5ZHJhLkhlbHNpbmtpLkZJPg), был видеоадаптер Trident TVGA 8800 (?). <a name="note-video"></a>
- [8] В [Release note](http://www.oldlinux.org/Linux.old/Linux-0.01/docs/RELNOTES-0.01) указано устройство `/dev/PS0` ("cp Image /dev/PS0 is what I use with a 1.44Mb floppy"). <a name="note-35fdd"></a>
- [9] Предположительно, дисковод был, потому что, в то время было распространённой практикой иметь дисководы и 3,5, и 5,25 дюйма. Косвенное доказательно наличия дисковода на 5,25 заключается в том, что в J4F говорится, что во время установки Minix Линусу потребовалось вставить 16 дискет (*скорее всего, на самом деле 15. Первые три дискеты являются загрузочными и он использовал одну из них*). И несмотря на то, что Minix-1.5 от PH на дискетах 3,5 дюйма официально [издавался](http://opennet.ru/docs/FAQ/OS/minix-info.html), у меня есть сомнения, что PH оставили дистрибутив на 17 3,5-дюймовых дискетах. [Японское](https://habrastorage.org/webt/3e/wd/p5/3ewdp5n7zc0onpcjmpe_rri5cjq.jpeg) издание книги уместились на 6. <a name="note-dualfdd"></a>
- [10] Два HDD c характеристиками [H5 S17 C980](https://kernel.googlesource.com/pub/scm/linux/kernel/git/nico/archive/+/refs/tags/v0.01/include/linux/config.h#48) + [CP3044](https://kernel.googlesource.com/pub/scm/linux/kernel/git/nico/archive/+/refs/tags/v0.01/kernel/hd.c#25). Факт наличия второго диска [(см. с момента “At my system fdisk reports the following…”)](https://kernel.googlesource.com/pub/scm/linux/kernel/git/nico/archive/+/v0.11). <a name="note-hdd"></a>
- [11] Внешний [HAYES](https://ru.wikipedia.org/wiki/AT-%D0%BA%D0%BE%D0%BC%D0%B0%D0%BD%D0%B4%D1%8B)-совместимый (?) модем на [2400 baud](https://kernel.googlesource.com/pub/scm/linux/kernel/git/nico/archive/+/refs/tags/v0.01/kernel/serial.c#23). <a name="note-modem"></a>

> Если вы обнаружили в таблице ошибки, пожалуйста, [сообщите](https://github.com/olegslavkin/linux-0.01/issues) мне об этом.

Давайте теперь *приблизительно* сконфигурируем виртуальный компьютер в эмуляторе 86Box.

---

# Предварительные условия<a name="req"></a>
Эта инструкция написана и тестировалась на HP ProBook 440 G6 с операционной системой Ubuntu 20.04.6 LTS и версией эмулятора 86Box-Linux-x86_64-b4724.AppImage (AppImage есть в директории bin репозитория).

В первую очередь необходимо клонировать репозиторий:
```bash
git clone git@github.com:olegslavkin/linux-0.01.git
cd linux-0.01
```

Далее необходимо распаковать архив с пустым и неразмеченным виртуальным жёстким диском на 68 Мб:

```bash
mkdir -p disks
xz -kdc backups/empty-hda.img.xz > disks/minix.img
```

> Внимательные читатели спросят, почему диск 1, а не 2, как в таблице выше? И почему он совершенно с другими характеристиками? Когда я начал писать это руководство, то ещё не знал о двух жёстких дисках и их характеристиках, и поэтому создал только один диск. Я попытался адаптировать руководство под два диска, но не справился с разметкой в Minix :( В будущих релизах, адаптирую под два и, возможно, не буду хранить вместе 16- и 32-битные утилиты Minix/Minix-386.

Теперь запустим эмулятор в режиме конфигурацию виртуального PC.

> Если у вас до этого не был установлен 86box, то необходимо будет установить набор [ROM](https://github.com/86Box/roms/releases/latest)-образов. [Подробнее см. в документации](https://86box.readthedocs.io/en/latest/usage/gettingstarted.html).

```bash
$ ./86box -S
```
И на основании приведённых ниже скриншотов конфигурируем виртуальный компьютер, с которым будем работать на протяжении всего этого руководства.

<spoiler title="Конфигурация виртуального компьютера в 86box.">

В качестве “Machine”, возможно, лучше было бы использовать “[SiS 310] ASUS ISA-386C”. Но, как писал выше, у меня нет информации об изначальной материнской плате.
![86box-settings-machine](https://habrastorage.org/webt/n-/1z/is/n-1zisoqfs8h92kh9ffzdsqgz3e.png)
![86box-settings-display](https://habrastorage.org/webt/eh/gg/ih/ehggihkae77fyppd7zexoobyp5g.png)
![86box-settings-input-devices](https://habrastorage.org/webt/0-/h1/bf/0-h1bfm6rwbjaqriesun-juvqmc.png)
![86box-settings-sound](https://habrastorage.org/webt/ff/xl/iw/ffxliwz5umgoqmory5vgs1ymnzo.png)
![86box-settings-network](https://habrastorage.org/webt/k0/9x/6a/k09x6alcgd79azai3rviklbyf3g.png)
![86box-settings-ports-com-ltp-serial-port-1](https://habrastorage.org/webt/fv/mg/6v/fvmg6v2x_0cdpkt9iacbdzsw27o.png)
![86box-settings-storage-controllers](https://habrastorage.org/webt/sz/lq/9j/szlq9jenf01qdezeqyvomwtyof0.png)
Добавляем жёсткий диск `disks/minix.img` с указанными характеристиками:
![86box-settings-hdd](https://habrastorage.org/webt/mj/rl/p-/mjrlp-nos1_0eyoaygirwnrscu0.png)
![86box-settings-floppy-cdroms](https://habrastorage.org/webt/-s/ay/_e/-say_ejgu3h9ben62spahjn6qzi.png)
![86box-settings-other-removable-devices](https://habrastorage.org/webt/zv/rk/qo/zvrkqoiuzxwtdkpznixyew4jw_k.png)
![86box-settings-other-peripherals](https://habrastorage.org/webt/ed/n8/yq/edn8yqedng6cwco7bpfihyzk22s.png)
</spoiler>

---

# Установка оригинальной 16-битной версии Minix 1.5.10<a name="minix-1.5.10-ph"></a>
Установим оригинальную версию Minix 1.5.10 c оригинальных образов дискет. Я написал эту главу на основе второй главы оригинального [MINIX 1.5 REFERENCE MANUAL](https://github.com/olegslavkin/linux-0.01/blob/master/manual/minix-15-reference-manual-1991.pdf).

> Иногда в сети можно встретить название “Minix 1.5.10 PH”, ещё встречал “Minix PH”. PH — это аббревиатура от Prentice-Hall, названия издательства, которое и издавало книгу [Andrew S. Tanenbaum “Operating Systems Design and Implementation-Prentice-Hall” (1987)](https://github.com/olegslavkin/linux-0.01/blob/master/manual/Andrew%20S.%20Tanenbaum%20-%20Operating%20Systems%20Design%20and%20Implementation-Prentice-Hall%20(1987).pdf). Это те самые «719 страниц в мягком красном переплёте, можно сказать, поселились у меня в постели» (с) (J4F).

## Загрузка Minix 1.5.10
Запускаем эмулятор:
```bash
$ ./86box
```
Первым делом заходим в настройки BIOS (нажимаем клавишу DEL). Задаём характеристики жёсткого диска (наиболее подходящий нам тип type 36) и дисководов. **Важно**, чтобы “Floppy drive A:” был “360KB 5.25”. Сохраняем настройки BIOS и выходим.
![bios-floppyA-360k](https://habrastorage.org/webt/1a/lf/qr/1alfqrp_iygthsjhfopgwqy_tyw.png)

Проверяем, что в дисковод вставлена [загрузочная дискета для PC (disk02)](https://github.com/olegslavkin/linux-0.01/raw/master/dist/minix/disk02.img), и после проверки BIOS и загрузки загрузочного сектора на экране эмулятора должно появится меню.
![Загрузочное меню Minix](https://habrastorage.org/webt/ts/ls/ho/tslshocapqa-_nbmsm92u1c7dkk.png)

Когда загрузочная программа полностью загрузилась с дискеты (*в статусной строке эмулятора перестанет мигать зелёным цветом «индикатор» дисковода*, это может занять несколько секунд) и появилось приглашение ввода команды:
```sh
# _
```
…в меню эмулятора *Media -> Floppy 1 -> Existing image...* меняем на дискету с корневой файловой системой [disk04](https://github.com/olegslavkin/linux-0.01/raw/master/dist/minix/disk04.img). После этого в окне эмулятора вводим команду `=` для загрузки Minix в оперативную память (`/dev/ram`) с выбранной дискеты (`/dev/fd0`). После успешной загрузки в память, Minix предложит вставить дискету [disk05](https://github.com/olegslavkin/linux-0.01/raw/master/dist/minix/disk05.img), которая будет смонтирована в каталог `/usr`. Вставьте образ дискеты в меню эмулятора и нажмите Enter.

После монтирования дискеты система попросит ввести текущее время и день. Введите в формате `MMDDYYhhmmss` (см. скриншот ниже). И в конце загрузки Minix предложит авторизоваться в системе.

> Как видите, Minix корректно работает, если ввести 2023 год. А вот недавно на linkmeup опубликовали забавный скриншот, на котором SunOS 4.1.4 писала [предупреждение](https://t.me/linkmeup_podcast/7372).

В Minix 1.5.10 есть, по меньшей мере, две учётные записи. Первая из них — это привилегированная `root`овая с паролем `Geheim`, а вторая — учётная запись обычного пользователя `ast` с паролем `Wachtwoord`. Авторизуйтесь как `root`.

![login](https://habrastorage.org/webt/3g/cm/e8/3gcme8tv_m-ph34-t8tbqbfz3di.png)
<spoiler title="Настраиваем (опционально) getty">

На этом этапе упростим дальнейшее взаимодействие с Minix. Вводить команды в окне эмулятора, с одной стороны, более «правильный» путь, но всё же это эмулятор, к тому же вводить команды таким способом получается очень медленно, да и copy-paste с этой инструкции будет невозможен :)

На наше счастье, Minix 1.5.10 поддерживает [getty](https://ru.wikipedia.org/wiki/Getty), а значит, благодаря возможности 86Box пробрасывать виртуальный COM-порт как устройство псевдотерминала на хостовую операционную систему, можно с помощью minicom, (c)kermit и других подобных утилит подключиться к Minix.

> Поскольку при написании этого руководства проброс COM-порта ещё не был добавлен в релиз (*это, предварительно, произойдёт в v4.0*), в репозитории есть AppImage. Промежуточная сборка скачана с их [Jenkins](https://ci.86box.net/job/86Box/).

Однако на этапе установки из коробки нет возможности использовать getty, но очень легко это исправить. Для этого смонтируйте дискету disk04 в хостовой операционной системе (современный Linux всё ещё понимает старую файловую систему Minix) и добавьте одну строку в файл etc/ttys:
```bash
$ sudo dist/minix/disk04.img <path>
$ echo '2f1' >> <path>/etc/ttys

$ cat <path>/etc/ttys

100
0f1
2f1 <- Добавлена строка
```
> Для этого руководства строка уже добавлена в disk04, но если хотите сделать это самостоятельно, то в репозитории есть оригинальная дискета [disk04.img.orig](https://github.com/olegslavkin/linux-0.01/raw/master/dist/minix/disk04.img.orig).

И далее можно подключиться к Minix «удалённо». Псевдоустройство терминала `/dev/pts/7`, как в данном случае, будет отображено в stdout при запуске эмулятора 86box.
```bash
$ minicom -o -c off -t vt100 -p pts/7 -b 9600
```
![minicom](https://habrastorage.org/webt/aj/vx/km/ajvxkmyalabtzzpfhhiukibnq1m.png)

<spoiler title="Подключиться можно не только с хоста на Minix, но и в обратную сторону...">

Для этого на хостовой ОС запустите agetty:
```bash
DEV='X'
sudo agetty -o '-p -- \\u' --keep-baud 9600 pts/${DEV} vt100
```

А в Minix запустите kermit и введите команды:
> Устройство tty2 — это COM2. Чтобы не создавать петлю, включите проброс COM2 аналогично COM1.
```
set line /dev/tty2
set speed 9600
connect
```
</spoiler>

Также при желании можно передавать и принимать файлы (*правда, криво*) с помощью протокола zmodem (через `sz` и `rz`). Но я считаю, что проще смонтировать на хосте дискету или раздел жёсткого диска и скопировать туда или оттуда нужные файлы.

</spoiler>

## Разметка жёсткого диска
Перед началом установки Minix необходимо разметить виртуальный жёсткий диск. Для этого введите команду:
```bash
fdisk -h8 -s17 /dev/hd0
```
Первая партиция диска `hd1` размером в 5 Мб и с файловой системой DOS не будет использована в этом руководстве, но она специально оставлена как возможность установки MS-DOS, ведь даже у самого Линуса был раздел с MS-DOS где он играл в ["Принца Персии"](https://www.tech-insider.org/linux/research/1992/1028.html).

Для создания партиции набираем следующие команды:
```
c
1
0  (first cylinder)
75 (last cylinder)
y  (change partition to active)
a
1  (active )
```
Вторая партиция диска `hd2`, также размером в 5 Мб и с файловой системой Minix, будет использована как корневой раздел (`/`):
```
c
2
76  (first cylinder)
512 (last cylinder)
n
```
Третья партиция `hd3` — как `/usr`:
```
c
3
513 (first cylinder)
588 (last cylinder)
n
```

Четвёртая партиция `hd4` пока не будет использована, оставим её на будущее (*для Linux*):
```
c
4
589  (first cylinder)
1023 (last cylinder)
n
```
В результате получится такая таблица разделов:
```bash
                          ----first----  -----last----  --------sectors-------
Num Sorted Active Type     Cyl Head Sec   Cyl Head Sec    Base    Last    Size
 1     1     A    DOS-BIG    0   0   2     75   7   16       1   10334   10334
 2     2          MINIX     76   0   1    150   7   17   10336   20535   10200
 3     3          MINIX    151   0   1    905   7   17   20536  123215  102680
 4     4          MINIX    906   0   1   1023   7   17  123216  139263   16048
```
Для внесения изменений и выхода из fdisk нажмите `w` и выполните команду `sync`. Перезагрузите виртуальную машину и загрузитесь, как делали до этого. И потом вновь выполните `fdisk` и убедитесь, что всё успешно записалось. Для выхода из fdisk вводим `q`.
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
Далее необходимо отформатировать средствами файловой системы все три Minix-партиции (раздела) жёсткого диска. Для каждой из них выполните команду `mkfs /dev/hdX <РАЗМЕР В БЛОКАХ>`, где `X` — это номер партиции, а `РАЗМЕР В БЛОКАХ` задаётся исходя из того, что блок занимает 1024 байта. Рассчитывается как количество секторов, разделённое на 2.
```bash
mkfs /dev/hd2 5100
mkfs /dev/hd3 51340
mkfs /dev/hd4 8024
```
## Установка (копирование) Minix 1.5.10 на жёсткий диск
После подготовки жёстких дисков можно запустить shell-скрипт установки Minix 1.5.10. Для этого необходимо указать в качестве аргументов раздел корневого диска (в нашем случае это `/dev/hd2`), размер `ram` в Мб, а также размеры (в блоках) всех четырёх партиций.

```bash
/etc/setup_root /dev/hd2 4096 5139 5100 51340 8024

/dev/hd2 mounted
/dev/hd2 unmounted
```

Теперь вновь «вставьте» образ загрузочной дискеты `disk02` и перезагрузитесь. После отображения загрузочного меню необходимо изменить корневой раздел, с которого будет выполняться загрузка. Во всех предыдущих шагах мы загружались с дискеты (`disk04`), но в этот раз необходимо загрузиться с раздела жёсткого диска. Для изменения корневого раздела в меню введите `r` (*select root device*), далее `h2`, затем Enter и после введите `=`.

Как и при первом запуске операционная система попросит вставить дискету с `/usr` (это `disk05`), и затем необходимо будет вновь авторизоваться как `root`.

![change-root](https://habrastorage.org/webt/nw/ng/uv/nwnguvvdq_gve20zcuwvfeuelgu.png)

> Если до этого вы подключались к Minix с помощью minicom, то после загрузки с дискеты можно вновь будет к ней подключиться. Если в эмуляторе 86Box перезагружаете виртуальный компьютер кнопкой Reset в меню эмулятора, то, как правило, устройство псевдотерминала остаётся тем же и в minicom ничего делать не надо, достаточно только ввести логин и пароль и далее следовать этому руководству.

Теперь необходимо инициализировать раздел `/usr`. Для этого в терминале запускаем другой shell-скрипт, указав в качестве аргумента партицию диска, которую планируется использовать как `/usr`. В этом руководстве это `hd3`.
```bash
/etc/setup_usr /dev/hd3
```
Начнётся инициализация раздела `/usr`. Скрипт попросит вставить по очереди дискеты с `disk05` по `disk17`.

```bash
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
После копирования данных с дискет автоматически запустится распаковка архивов.

<spoiler title="Посмотреть вывод работы скрипта">

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

Так как мы только что инициализировали раздел `/usr`, то нет больше необходимости вставлять дискету `disk05` в начале загрузки операционной системы. Теперь можно автоматически монтировать партицию диска `hd3` как `/usr`. Для этого надо немного исправить `/etc/rc`:
```bash
mined /etc/rc
```
> Если редактируете файлы в minicom и подобных утилитах, то, возможно, при пролистывании в терминале будут некорректно отображаться документы. Редактировать файл можно в основной консоли эмулятора, где после его сохранения можно продолжить вводить команды в minicom. Или если вы знаете, как это исправить, напишите, пожалуйста, мне, и я включу это в руководство.

Комментируем (или удаляем) строки монтирования дискеты (а также приглашение вставки дискеты) и добавляем запись монтирования раздела жёсткого диска.
```bash
#/bin/getlf "Please insert /usr diskette in drive 0.  Then hit ENTER."
#/etc/mount /dev/fd0 /usr           	# mount the floppy disk
/etc/mount /dev/hd3 /usr            	# mount the hard disk
```
Опционально, устанавливаем более высокую скорость serial-порта:
```bash
# Initialize the first RS232 line to 9600 baud.
/usr/bin/stty 9600 </dev/tty1
```
> В редакторе mined сохраняем изменения комбинацией клавиш CTRL+W, а для выхода из редактора нажмите CTRL+X.
>
> Кроме mined в оригинальном Minix 1.5.10 есть и клон vi, и клон emacs elle, но на протяжении всего руководства буду использовать mined.

Вводим команду `sync`, проверяем, что у нас вставлена загрузочная дискета `disk02` и вновь перезагружаемся. После загрузки выбираем, как в прошлый раз, r -> h2 и нажимаем =. Такие действия необходимо выполнять при каждой загрузке операционной системы.

## Тестирование работоспособности Minix
Чтобы убедится, что операционная система установлена корректно, разработчики подготовили тестовые программы (предварительно необходимо их скомпилировать) и shell-скрипты. Для тестирования необходимо перейти в каталог и откомпилировать `*.c`. Рекомендуется компилировать как `root` (на последнем этапе для файлов устанавливаются права на выполнение):

```bash
cd /usr/src/test
make all
```
<spoiler title="Процесс компиляции тестовых программ">

```
cc -F -D_MINIX -D_POSIX_SOURCE -o test0 test0.c;            	chmem =8192  test0
test0: Stack+malloc area changed from 56042 to 8192 bytes.
cc -F -D_MINIX -D_POSIX_SOURCE -o test1 test1.c;            	chmem =8192  test1
test1: Stack+malloc area changed from 59024 to 8192 bytes.
cc -F -D_MINIX -D_POSIX_SOURCE -o test2 test2.c;            	chmem =8192  test2
test2: Stack+malloc area changed from 58086 to 8192 bytes.
cc -F -D_MINIX -D_POSIX_SOURCE -o test3 test3.c;            	chmem =8192  test3
test3: Stack+malloc area changed from 58816 to 8192 bytes.
cc -F -D_MINIX -D_POSIX_SOURCE -o test4 test4.c;            	chmem =8192  test4
test4: Stack+malloc area changed from 58982 to 8192 bytes.
cc -F -D_MINIX -D_POSIX_SOURCE -o test5 test5.c;            	chmem =8192  test5
test5: Stack+malloc area changed from 54974 to 8192 bytes.
cc -F -D_MINIX -D_POSIX_SOURCE -o test6 test6.c;            	chmem =8192  test6
test6: Stack+malloc area changed from 59156 to 8192 bytes.
cc -F -D_MINIX -D_POSIX_SOURCE -o test7 test7.c;            	chmem =8192  test7
test7: Stack+malloc area changed from 49378 to 8192 bytes.
cc -F -D_MINIX -D_POSIX_SOURCE -o test8 test8.c;            	chmem =8192  test8
test8: Stack+malloc area changed from 58098 to 8192 bytes.
cc -F -D_MINIX -D_POSIX_SOURCE -o test9 test9.c;            	chmem =8192  test9
test9: Stack+malloc area changed from 57486 to 8192 bytes.
cc -F -D_MINIX -D_POSIX_SOURCE -o test10 test10.c;  	chmem =8192  test10
test10: Stack+malloc area changed from 57522 to 8192 bytes.
cc -F -D_MINIX -D_POSIX_SOURCE -o test11 test11.c;  	chmem =8192  test11
test11: Stack+malloc area changed from 57490 to 8192 bytes.
cc -F -D_MINIX -D_POSIX_SOURCE -o test12 test12.c;  	chmem =8192  test12
test12: Stack+malloc area changed from 60678 to 8192 bytes.
cc -F -D_MINIX -D_POSIX_SOURCE -o test13 test13.c;  	chmem =8192  test13
test13: Stack+malloc area changed from 58574 to 8192 bytes.
cc -F -D_MINIX -D_POSIX_SOURCE -o test14 test14.c;  	chmem =20000 test14
test14: Stack+malloc area changed from 59476 to 20000 bytes.
cc -F -D_MINIX -D_POSIX_SOURCE -o test15 test15.c;  	chmem =8192  test15
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
cc -F -D_MINIX -D_POSIX_SOURCE -o test16 test16.c;  	chmem =8192  test16
test16: Stack+malloc area changed from 54988 to 8192 bytes.
cc -F -D_MINIX -D_POSIX_SOURCE -o test17 test17.c;  	chmem =8192  test17
test17: Stack+malloc area changed from 43274 to 8192 bytes.
cc -F -D_MINIX -D_POSIX_SOURCE -o test18 test18.c;  	chmem =8192  test18
test18: Stack+malloc area changed from 46508 to 8192 bytes.
cc -F -D_MINIX -D_POSIX_SOURCE -o test19 test19.c;  	chmem =8192  test19
test19: Stack+malloc area changed from 54990 to 8192 bytes.
cc -F -D_MINIX -D_POSIX_SOURCE -o test20 test20.c;  	chmem =65000 test20
```
</spoiler>

А для запуска самих тестов рекомендуется авторизоваться как обычный пользователь, а не `root`. Авторизуйтесь как `ast` с паролем `Wachtwoord`.
```bash
cd /usr/src/test
run
```

Если все тесты были успешно пройдены, то дополнительно запустите два тестовых shell-скрипта `sh1` и `sh2`.
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
> При запуске в minicom могут появиться фантомные ошибки, но после повторного запуска они обычно исчезают.

<spoiler title="Резервное копирование промежуточной точки">
На этом этапе можно поставить эмулятор паузу и сохранить образ жёсткого диска, настройки BIOS, а также конфигурационный файл самого эмулятора. Это очень поможет в будущем, если необходимо будет откатить изменения.

```bash
tar cvfJ backups/minix-1.5.10-install-hda.tar.xz disks/minix.img nvr/acc386.nvr 86box.cfg
```
</spoiler>

---

# Установка патчей от Брюса Эванса (Bruce Evans' 386 patches) ака Minix-386 <a name="minix-386"></a>
В предыдущей главе мы установили классическую 16-битную версию Minix 1.5.10, в том виде, в каком она изначально задумывалась автором. Но цель этого руководства — пройти шаги, сделанные Линусом Торвальдсом при написании  Linux (*ну ладно, ладно, не все шаги, сам Linux писать не будем :)*). Как упоминалось выше, Линус работал не в оригинальной, а в пропатченной версии Minix 1.5.10, также известной как Minix-386. Патчи были подготовлены Брюсом Эвансом, а Джон Налл (John Nall) написал [прекрасное руководство](https://github.com/olegslavkin/linux-0.01/raw/master/dist/minix-386/tutor.asc) по их применению.

Но прежде, чем мы начнём преображение, необходимо немного «проапгрейдить» наш виртуальный PC. При установке классического Minix был задействован дисковод 5,25 дюйма на 360 Кб. Только указав такой тип виртуального дисковода в настройках эмулятора и BIOS, мне удалось выполнить установку и написать это руководство. Но для загрузки 32-битной версии Minix (*а позже и для Linux*) понадобятся уже дискеты 5,25 дюйма на 1,2 Мб. Поэтому необходимо, убедиться, что в настройках эмулятора и в BIOS указан соответствующий тип дисковода.

![86box_floppy](https://habrastorage.org/webt/4w/py/fq/4wpyfqmjbllooyqxqzfk1hq8cv8.png)
![1_2M_FDD](https://habrastorage.org/webt/y0/mv/yw/y0mvywl-hvryhlyb1ate7zndmda.png)

> В сети есть [патч](https://usenetarchives.com/view.php?id=comp.os.minix&mid=PDc4MDZAbmlnZWwudWRlbC5FRFU%2B) позволяющий загрузиться из различных типов дискет, но я не проверял его.

Загружаемся как обычно с загрузочной дискеты `disk02`, не забываем при этом указать в качестве корневого раздела партицию `h2` при загрузке. Авторизуемся как `root`. Далее вместо загрузочной дискеты, в эмуляторе, вставляем дискету с патчами от Брюса Эванса [minix-386](https://github.com/olegslavkin/linux-0.01/raw/master/dist/minix-386/minix-386.img), создаем каталог `/usr/oz`, монтируем дискету и копируем все файлы.

> Файлы, содержащиеся на дискете, были взяты из [архива](http://www.oldlinux.org/Linux.old/study/linux-travel/minix-386/zhao.rar) с сайта oldlinux.org. Кроме патчей там есть другие полезные файлы.

```bash
mkdir /usr/oz
cd /usr/oz
/etc/mount /dev/at0 /user
cp /user/* /usr/oz
/etc/umount /dev/at0
sync
```

Подготавливаем загрузочную дискету. Вставляем дискету [shoelace](https://github.com/olegslavkin/linux-0.01/raw/master/dist/minix-386/shoelace.img) и форматируем её:
```bash
mkfs /dev/at0 1200
```
Переходим в каталог с архивами и распаковываем их:
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
Далее создаём папку для загрузчика и распаковываем его:
```bash
mkdir /usr/oz/shoelace
mv shl-1.0a.t.Z shoelace
cd shoelace
compress -d shl-1.0a.t.Z
tar xvf shl-1.0a.t
rm shl-1.0a.t shl-1.0a.t.Z
```
Создаём папку для компилятора bcc, распаковываем архивы с 16- и 32-битной версией и исходными кодами стандартной библиотеки Си:
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
Распаковываем архив с патчами minix-386, а также для удобства работы переименовываем директорию в mx386:
```bash
cd /usr/oz
tar xvf mx386_1.1.t
mv mx386_1.1 mx386
rm mx386_1.1.t
```
Распаковываем небольшой патч на патч minix-386:
```bash
cd /usr/oz
unshar < mx386_1.1.01
rm mx386_1.1.01
mv klib386.x* /usr/oz/mx386/kernel
```
Переходим в папку с патчами ядра и применяем:
```bash
cd /usr/oz/mx386/kernel
patch klib386.x klib386.x.cdif
```
Монтируем загрузочную дискету (*в дисковод всё ещё должна быть вставлена дискета shoelace*), создаём необходимые директории и копируем директории `dev` и `etc`:
```bash
/etc/mount /dev/at0 /user
cd /user
mkdir usr
mkdir user
cd /
cpdir -s dev /user/dev
cpdir -ms etc /user/etc
```
Удаляем три 16-битные версии программ:
```bash
cd /user/etc
rm mount umount update
```
Комментируем строку с монтированием диска как `/usr`:
```bash
mined /user/etc/rc
# comment
# /etc/mount /dev/hd3 /usr
```
В корне создаём папку `/local` и копируем в неё 16- и 32-битную версию компилятора.
> Использование пути `/local` обязательно. Если он вдруг не подходит, то необходимо будет его изменить в `bcc.c` и перекомпилировать компилятор.

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
Копируем патчи для ядра Minix в директорию с исходным кодом ядра, а также копируем патчи для заголовочных файлов:
```bash
cpdir -ms fs /usr/src/fs         # mods for fs
cpdir -ms kernel /usr/src/kernel # mods for kernel
cpdir -ms mm /usr/src/mm     	 # mods for mm
cpdir -ms tools /usr/src/tools   # mods for tools

cd /usr/oz/bcc/lib/fix1.5.10 	# move Bruce's changes
cp include.cdif /usr/include 	# to include

cp ansi.cdif /usr/src/lib/ansi   # to ansi
cp other.cdif /usr/src/lib/other # to other
cp posix.cdif /usr/src/lib/posix # and to posix
```
Применяем патчи заголовочных файлов:
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
Сохраняем (*не удаляем, он ещё будет нужен*) оригинальный бинарный make и компилируем без флага `-DMINIXPC`:
```bash
cd /usr/bin
mv make make_s
cd /usr/src/commands/make
mined Makefile # Оставить только "CFLAGS = -Dunix"
make_s
mv make /usr/bin
```
Добавляем в PATH путь до компиляторов bcc, а также переименовываем оригинальный компилятор Си (сс) и делаем симлинк:
```bash
PATH=/local/bin:$PATH
export PATH
cd /usr/bin
mv cc cc_old
cd /local/bin
ln bcc cc
```
Компилируем 16-битную версию библиотеки `libc.a` и `longlib.a`:
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
Компилируем 32-битную версию библиотеки:
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
Создаём директорию для компонентов ядра Minix:
```bash
cd /etc
mkdir system
```
Компилируем компоненты ядра Minix. Обратите внимание, что при редактировании makefile.cpp необходимо, чтобы все строки препроцессора cpp начинались с начала строки.
В процессе линковки могут появляться предупреждения `warning: _exit (или _unlock или _lock) redefined`. Не обращаем на них внимание ни сейчас, ни позже.
```bash
cd /usr/src/mm
rm -f *.s *.o
mined makefile.cpp   # be sure all "#" commands start in column 1
/usr/lib/cpp -P -DINTEL_32BITS makefile.cpp > makefile
make             	# generate /etc/system/mm

cd /usr/src/fs
rm -f *.s *.o
mined makefile.cpp   # again, be sure all "#" commands start in col 1
/usr/lib/cpp -P -DINTEL_32BITS makefile.cpp > makefile
make             	# generate /etc/system/fs
```
При редактировании `xx` удалите все комментарии, которые не относятся к синтаксису препроцессора `cpp`, а также лишние символы табуляции в таких выражениях как `#define O   	s`, `#if INTEL_32BITS`, `#else`, `#endif`.
```bash
cd /usr/src/kernel
cp makefile.cpp xx
mined xx          	# remove all of the comment lines
rm -f *.s *.o
sh config 386     	# set up proper files.
/usr/lib/cpp -P -DINTEL_32BITS xx > makefile
make              	# generate  /etc/system/kernel
```
Компилируем `init`. В процессе линковки также могут появиться предупреждения `warning: _exit (или _sbrk) redefined`, которые тоже игнорируем.
```bash
cd /usr/src/tools
cc -3 -c -D_POSIX_SOURCE -D_MINIX init.c
ld -3 -o /etc/system/init /usr/local/lib/i386/head.o \
   init.o /usr/local/lib/i386/libc.a
```
Компилируем загрузчик shoelace, но для этого временно возвращаем оригинальные make и cc.
```bash
cd /usr/bin
mv cc_old cc
mv make make_o
mv make_s make
PATH=/usr/bin:/bin
export PATH
cd /usr/oz/shoelace
mined shoe.c      	# Заменить <varargs.h> на "varargs.h"
make -f makefile.min
```
Создаём загрузочный сектор на дискете и копируем бинарные файлы загрузчика, его конфигурационные файлы и компоненты ядра Minix.
```bash
cd /usr/oz/shoelace
./laceup /dev/at0 5.25dshd
cd /etc/system
mkdir /user/etc/system
cp * /user/etc/system   	# copy kernel, fs, mm, init
cp /usr/oz/shoelace/config /user/etc/config
cp /usr/oz/shoelace/shoelace /user/shoelace
cp /usr/oz/shoelace/bootlace /user/etc/bootlace
cp /usr/oz/shoelace/disktab /user/etc/disktab
cp /usr/oz/shoelace/laceup /user/etc/laceup

mined /user/etc/config
# Закомментировать run    /etc/system/db
# Заменить на дискету
setdev rootdev /dev/at0
```
Возвращаем make и сс, а также переменную `PATH` в прежнее состояние.
```bash
cd /usr/bin
mv cc cc_old
mv make make_s
mv make_o make
PATH=/local/bin:$PATH
export PATH
```
Компилируем 32-битный sh:
```bash
cd /user
mkdir bin
cd /usr/src/commands/sh

rm -f *.s *.o
cc -3 -D_POSIX_SOURCE -o /user/bin/sh *.c
```
Компилируем другие, минимально необходимые программы:
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

Убеждаемся, что в дисковод по прежнему вставлена дискета с shoelace, и перезагружаем компьютер.

Добро пожаловать в Minix-386!
![minix-386](https://habrastorage.org/webt/fd/kh/mr/fdkhmrv3fdmlkmnb_jsdszpg9cc.png)

Не обращайте внимание, что часть программ `readclock`, `date`, `wtmp`, `printroot` и `stty`, задействованные иницилизирующем скриптом `/etc/rc`, не смогли запуститься, они всё ещё 16-битные. В следующей главе исправим это.
![minix-386-not-found](https://habrastorage.org/webt/gy/xk/nu/gyxknupcepkzdeqd6yqcnk15rx0.png)

<spoiler title="Резервное копирование промежуточной точки">

Ставим эмулятор на паузу и сохраняемся:

```bash
tar cvfJ backups/minix-386-1.5.10-stage1.tar.xz disks/minix.img dist/minix-386/shoelace.img nvr/acc386.nvr 86box.cfg
```
</spoiler>

---

# Компиляция стандартных утилит 1.5.10 под архитектуру i386 <a name="i386bin"></a>
После проверки, что мы успешно загрузились с новым ядром с дискеты, необходимо перекомпилировать утилиты. Для этого загружаем 16-битный Minix (используем дискету `disk02` и раздел жёсткого диска `h2`) и выполняем кросс-компиляцию 80386-версий бинарных утилит.

Чтобы упростить процесс я подготовил Makefile и вспомогательный sh-скрипт. Распаковываем архив с Makefile его и запускаем компиляцию:
```bash
cd /usr/oz
compress -d bin32.tar.Z
tar xvf bin32.tar && rm bin32.tar
/tmp/bin32.sh | tee problems.out 2>&1
```
Создаём директорию для 32-битной версии ядра и переносим туда скомпилированные на предыдущем этапе компоненты:
```bash
mkdir /etc/system3
cd /etc/system/
mv kernel fs mm init /etc/system3
```
Переносим бинарные файлы в `/bin`:
```bash
cd /etc
mv mount umount update /bin
```
> Да, с точки зрения Minix это, возможно не канон, но так можно одновременно иметь как 16-, так и 32-битные версии программ. Также это упростит переключение между 16- и 32-битным режимом. Да и я уже просто привык, что mount/umount находится в PATH.

Размонтируем дискету, если в дисководе вставлено что-то отличное от `shoelace`, поменяем на неё и примонтируйем. Меняем в конфигурационном файле загрузчика значение `rootdev` с дискеты (`at0`) на диск (`hd2`) и меняем пути для `mount` и `update`:
```bash
umount /dev/at0
mount /dev/at0 /user

mined /user/etc/config
# setdev rootdev /dev/hd2	<- заменить на раздел HDD

mined /etc/rc
# /bin/mount /dev/hd3 /usr	<- заменить на /bin/
# /bin/update  &          	<- заменить на /bin/

sync
```
Переименуем директории. Не спешите перезагружаться!
```bash
/local/bin/bin3
```
Скрипт, который мы только что выполнили, не переименовывает директорию `/usr/binX`. Сделайте это вручную:
```bash
/bin0/mv /usr/bin /usr/bin0
/bin0/mv /usr/bin3 /usr/bin
```

Вот теперь можно перезагрузиться, и добро пожаловать в Minix-386 (снова)!
![minix-386-again](https://habrastorage.org/webt/j7/kl/u3/j7klu3cww5klhkaqexhnonhqkbe.png)

<spoiler title="Резервное копирование промежуточной точки">
Ставим эмулятор на паузу и сохраняемся:

```bash
tar cvfJ backups/minix-386-1.5.10-stage2.tar.xz disks/minix.img dist/minix-386/shoelace.img nvr/acc386.nvr 86box.cfg
```
</spoiler>

<spoiler title="Возврат на 16-битную версию">

Если необходимо возвратиться на 16-ти битную версию, то нужно просто переименовывать пути до бинарных файлов, вставить дискету `disk02` и использовать раздел жёсткого диска `h2` как корневой.
```bash
/local/bin/bin0
/bin3/mv /usr/bin /usr/bin3
/bin3/mv /usr/bin0 /usr/bin
/bin3/sync
```

</spoiler>

<spoiler title="Утилиты, которых нет в версии 80386">

Части утилит нет в 32-битной версий Minix. Нет клона emacs [elle](https://www.unix.com/man-page/minix/9/elle/) (это файлы файлы `elle`, `ellec`), потому что в оригинальных дискетах нет их исходных кодов.

В bcc не компилируются cpdir и ttt, это известная проблема. Для cpdir есть исправление, а для ttt — неизвестно. Но ttt — это игра “Tic Tac Toe”, или «Крестики-Нолики», мне она была ни к чему.

Нет необходимости в утилитах ast и cc, потому что мы используем компилятор bcc. Нет исходных файлов для pc— The Minix [Pascal Compiler](https://www.krsaborio.net/unix-source-code/research/1987/1014-a.html), но, возможно, это просто симлинк на cc.

Также у меня не работает compress (и его симлинки uncompress и zcat), но позже с установкой gcc поставим работающий compress.

</spoiler>

---

# Установка патча для сопроцессора 387 <a name="fix387"></a>
Вставляем дискету с `shoelace` и для компиляции ядра временно мигрируем на 16-битную версию.
```bash
/local/bin/bin0
/bin3/mv /usr/bin /usr/bin3
/bin3/mv /usr/bin0 /usr/bin
/bin3/sync
```
Вставляем дискету `disk02` и перезагружаемся. После перегрузки вставляем дискету с [gcc-1.37.1](https://github.com/olegslavkin/linux-0.01/raw/master/dist/gcc-1.37.1-plains/awb-gcc-1.37.1.img). Копируем патч ядра, имитирующий наличие сопроцессора 387. Он является частью gcc-1.37.1 и, как я понял, переназначает второй бит регистра `CR0`, «говорящий» компилятору, что у нас нет сопроцессора 387. Этот патч обязателен, в противном случае в будущем не получится собрать ядро Linux, мы получим ошибку компиляции `fp stack overflow`. После применения патча необходимо пересобрать ядро (*достаточно только kernel*) minix-386:
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
Копируем ядро на загрузочную дискету. Размонтируем вставленную дискету, вставляем `shoelace`, монтируем её и копируем ядро:
```bash
/bin/umount /dev/at0
/bin/mount /dev/at0 /user
mv /etc/system/kernel /etc/system3
cp /etc/system3/kernel /user/etc/system
sync
```
Мигрируем обратно на minix-386:
```bash
/local/bin/bin3
/bin0/mv /usr/bin /usr/bin0
/bin0/mv /usr/bin3 /usr/bin
/bin0/sync
```
<spoiler title="Резервное копирование промежуточной точки">

Ставим эмулятор на паузу и сохраняем текущее состояние.

```bash
tar cvfJ backups/minix-386-1.5.10-stage3.tar.xz disks/minix.img dist/minix-386/shoelace.img nvr/acc386.nvr 86box.cfg
```
</spoiler>

---

# Установка компилятора GCC-1.37.1 от Alan W Black и Richard Tobin <a name="gccbin137"></a>
Как известно, ядро Linux было скомпилировано с помощью gcc. И в оригинале это была собственная пропатченная версия gcc 1.40 от Линуса с поддержкой опции `-mstring-insns` (*может, чего-то ещё*). Где сейчас можно найти именно эту версию компилятора, мне не известно. Возможно, [это](http://www.oldlinux.org/Linux.old/Linux-0.10/binaries/compilers/gccbin.tar.Z) та самая версия. В архиве файлы датированы 22 сентября 1991, очень-очень близко к тому времени. С другой стороны, на эти даты нельзя ориентироваться. Возможно, это gcc для сборки в самом Linux, а не в Minix.

Я пойду немного другим путём и буду использовать версию gcc-1.37.1 от Alan W Black и Richard Tobin, также известную как “awb-gcc from plains». Иногда в сети её называют просто “gcc from plains”. В природе существует и [gcc-1.40](https://www.cs.cmu.edu/~awb/pub/minix/gasdiff.tar.gz) для Minix-386, но его использовать не буду, потому что: а) патч не от Линуса Торвальдса, а от Энди Майкла (Andy Michael); б) есть только diff, надо его ещё и скомпилировать :)

Загружаемся с дискеты `shoelace`, затем меняем её на дискету c [gcc-1.37.1](https://github.com/olegslavkin/linux-0.01/raw/master/dist/gcc-1.37.1-plains/awb-gcc-1.37.1.img), монтируем её и копируем 16-битную версию утилиты compress (*в Minix использовалась [13-битная компресия](https://www.unix.com/man-page/minix/1/compress/)*):
```bash
mount /dev/at0 /user
cp /user/16bcompress /usr/bin
chmod 755 /usr/bin/16bcompress
```
Копируем бинарные файлы gcc во временную папку, распаковываем и устанавливаем их:
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
Устанавливаем заголовочные файлы:
```bash
cd /usr/tmp
tar xvf gccinc.tar
cd gccinc
mkdir /usr/local/lib/gcc/gcc-include
mv * /usr/local/lib/gcc/gcc-include
cd /usr/tmp
rm -fr gccinc*
```
Устанавливаем библиотеки Си:
```bash
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
Тестируем компилятор, пишем традиционный “Hello World”:
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
На выходе получим тоже традиционный a.out. Но если попробовать запустить его напрямую, то получим ошибку:
```bash
a.out
: not found
```
Всё дело в том, что gcc генерирует бинарный файл напрямую несовместимый с Minix. Есть два пути решения. Первый (популярный): сконвертировать в совместимый формат с помощью gcc2minix, который входил в комплект gccbin.
```bash
gcc2minix < a.out > test
chmod +x test
./test
Hello World
```
Второй вариант: использовать патч [gnutoo](https://www.cs.cmu.edu/~awb/pub/minix/gnutoo.tar.gz). У меня он не сработал, но, возможно, я что-то сделал неправильно.

<spoiler title="Резервное копирование промежуточной точки">

Ставим эмулятор на паузу и сохраняем текущее состояние.
```bash
tar cvfJ backups/minix-386-1.5.10-gcc1.37.1.tar.xz disks/minix.img dist/minix-386/shoelace.img nvr/acc386.nvr 86box.cfg
```
</spoiler>

---

# Компилируем и запускаем ядра Linux 0.01 <a name="linux-0.01"></a>
И вот, наконец-то, после всех этапов подготовки можно приступить к компиляции ядра Linux. Но для этого нужно ещё чуть-чуть подготовиться :). Помните, в самом начале, когда разбивали жесткий диск на разделы, у нас остался неиспользованный раздел `h4`? Его оставили как раз для Linux. Отформатируем раздел, а также подключим его в автомонтирование при запуске Minix-386:
```bash
mkdir /linux
mkfs /dev/hd4 8024
mined /etc/rc
# добавить можно сразу после строки монтирования /dev/hd3
# /bin/mount /dev/hd4 /linux          	# linux
/bin/mount /dev/hd4 /linux
```
Создадим необходимые каталоги:
```bash
cd /linux
mkdir usr
mkdir tmp
cd usr
mkdir src
```
Вставляем дискету с исходными кодами Linux [linux-src-0.01](https://github.com/olegslavkin/linux-0.01/raw/master/dist/linux/src.img) и монтируем дискету. Сам архив c исходными кодами [linux-0.01.tar.Z](http://www.oldlinux.org/Linux.old/Linux-0.01/sources/system/linux-0.01.tar.Z) взят с сайта oldlinux.org. Примечательно, что на официальном сайте ядра Linux имеется [tar.gz версия](https://mirrors.edge.kernel.org/pub/linux/kernel/Historic/linux-0.01.tar.gz) от октября 1993 (*ядро 0.01, я напомню, [«родилось» 17.09.1991](https://lkml.org/lkml/2021/9/17/1018)*). Это, скорее всего переупаковка в формат архива, поддерживаемого GNU-утилитами того времени.
```bash
/bin/mount /dev/at0 /user
cp /user/linux.tar.Z /linux/tmp
16bcompress -d /linux/tmp/linux.tar.Z
cd /linux/usr/src
tar xvf /linux/tmp/linux.tar
rm /linux/tmp/linux.tar
cd linux
```
Адаптация ядра под gcc-1.37.1:
```bash
mined Makefile

# Добавляем путь до gnulib:
LIBS	=lib/lib.a /usr/local/lib/gcc/gnulib

# У Линуса был патч gnutoo (или ему подобный), поэтому конвертации не было.
# Приводим к следующему виду.
# Не забывайте, что в Makefile отступ от начала строки отделяет символ табуляции!
tools/build: tools/build.c
	$(CC) $(CFLAGS) \
	-o tools/a.out tools/build.c
	gcc2minix < tools/a.out > tools/build
	chmod +x tools/build
	chmem +65000 tools/build

# Удаляем `-mstring-insns` из CFLAGS
mined fs/Makefile
mined kernel/Makefile
mined lib/Makefile
```
Адаптируем под наше «железо»: используем 5,25-дюймовые дискеты на 1,2 Мб вместо 3,5-дюймовых, задаём верхнюю границу оперативной памяти, а также указываем, что будем использовать раздел `h4` жёсткого диска, и его характеристики.

> Сейчас и чуть позже вы увидите, почему я сомневаюсь, что у Линуса был компьютер с 4 Мб оперативной памяти, скорее всего у него было 8Мб. Возможно, при покупке было действительно 4, но потом увеличил до 8. Как, возможно, и добавил второй жёсткий диск.

```bash
# Указываем, что будем использовать 1,2 Мб
mined boot/boot.s
| sectors = 18
sectors = 15

mined include/linux/config.h
/* #define LASU_HD */
/* #define LINUS_HD */
#define E86BOX_HD
...
#if 	defined(LINUS_HD)
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
#if 	defined(LINUS_HD)
#define ROOT_DEV 0x306
#elif   defined(LASU_HD)
#define ROOT_DEV 0x302
#elif   defined(E86BOX_HD)
#define ROOT_DEV  0x304
#else
#error "must define HD"
#endif

#if 	defined(LASU_HD)
#define HD_TYPE { 7,35,915,65536,920,0 }
#elif   defined(LINUS_HD)
#define HD_TYPE { 5,17,980,300,980,0 },{ 5,17,980,300,980,0 }
#elif   defined(E86BOX_HD)
#define HD_TYPE { 8,17,1024,65536,1024,0 }
#else
#error "must define a hard-disk type"
#endif
```
Добавляем в PATH пути до компиляторов и ассемблера, и наконец компилируем:
```bash
PATH=/usr/local/bin:/local/bin:/bin:/usr/bin
export PATH
make
```
Если компиляция пройдёт успешно, то в папке с ядром появится файл `Image`. Это и есть наше ядро Linux.
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
tools/build boot/boot tools/system > Image <---- это Linux!!!
Boot sector 452 bytes.
System 93184 bytes.
sync
```

<spoiler title="Но, возможно, у вас, как и у меня, компиляция может упасть с ошибкой">

```bash
gcc: installation problem, cannot exec /usr/local/lib/gcc/gcc-cc1: No more processes
```
Это происходит, как я понял, из-за малого размера оперативной памяти (напомню, мы используем 4 Мб). И тут есть два решения: а) в настройках эмулятора временно увеличить до 8 Мб и всё заработает как надо; или б) выполнить сборку в несколько этапов.
```bash
cd kernel && make
cd ../mm  && make
cd ../fs  && make
cd ../lib && make
cd .. 	&& make
```

</spoiler>

После успешной компиляции создаём необходимые директории и устройства на жёстком диске.
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
Вставляем дискету [bin](https://github.com/olegslavkin/linux-0.01/raw/master/dist/linux/bin.img) c готовыми бинарным [bash](http://www.oldlinux.org/Linux.old/gnu/bash/bash-1.05-linux.tar.gz) и [update](http://www.oldlinux.org/Linux.old/Linux-0.01/binaries/sbin/update.Z).

> bash не оригинальный, скомпилирован в 2004 году, скорее всего Jiong Zhao (автором сайта oldlinux.org). В оригинале должен использоваться [bash-1.08](https://ru.wikipedia.org/wiki/%D0%AF%D0%B4%D1%80%D0%BE_Linux#cite_note-minix-10), но мне не удалось найти ни бинарный, ни исходный код этой версии.

```bash
/bin/mount /dev/at0 /user
cp /user/bash /linux/bin/sh
cp /user/update /linux/bin/update
```
Вставляем чистую дискету [boot](https://github.com/olegslavkin/linux-0.01/raw/master/dist/linux/boot.img) и записываем на неё ядро.
```bash
/bin/umount /dev/at0
cd /linux/usr/src/linux

dd if=Image of=/dev/at0
183+0 records in
183+0 records out
```
Перезагружаем компьютер. И поздравляю, вы в Linux-0.01 с [захардкоженной](http://www.oldlinux.org/Linux.old/Linux-0.01/docs/RELNOTES-0.01) [финской](https://upload.wikimedia.org/wikipedia/commons/1/1c/IBM_model_M2_for_Sweden_and_Finland.jpg) раскладкой.

![linux-0.01](https://habrastorage.org/webt/nn/yy/qp/nnyyqp3ss4bk1plc0y4_gjspn-4.png)

Но, как и писал Линус, делать в этой версии ядра совершенно нечего, только любоваться. Голая оболочка bash, в которой нет ничего, кроме встроенных команд. Даже `ls` нельзя выполнить, но можно попробовать её имитировать с помощью `alias ls='echo *'`.

<spoiler title="Резервное копирование промежуточной точки">

Ставим эмулятор на паузу и сохраняем текущее состояние.
```bash
tar cvfJ backups/minix-386-1.5.10-linux-0.01.tar.xz disks/minix.img dist/minix-386/shoelace.img dist/linux/boot.img nvr/acc386.nvr 86box.cfg
```
</spoiler>

---

# Заключение
Кроме Linux 0.01 мы сделали три различные среды, в которых можно долго и увлекательно проводить время.

Во-первых, это оригинальная Minix 1.5.10, в которой можно изучить микроядро Minix, а книга Эндрю поможет в этом. За прошедшие годы сообщество создало и портировало немало интересных программ. Часть их них до сих пор можно найти в интернете. Часть сохранена на легендарном [nic.funet.fi](http://www.nic.funet.fi/pub/minix/).

Во-вторых, это Minix-386, для которой тоже сделали немало интересного. Например, была реализация GUI Mini-X (не X11 совместимая), виртуальные консоли (прямо как современный screen), реализация [IP-стека](http://www.nic.funet.fi/pub/minix/communications/tnet4.tar.Z), которого не было в Minix, но очень многие его просили, и многое другое.

И в-третьих, мы сделали среду с gcc и Linux, где можно самостоятельно скомпилировать и запустить другие версии ядра или попробовать портировать GNU-утилиты. К сожалению, последующие версии ядра 0.02 и 0.03 не сохранились до наших дней, а из [0.10](https://mirrors.edge.kernel.org/pub/linux/kernel/Historic/old-versions/tytso/linux-0.10.tar.gz) сохранилась только версия [Theodore Ts'o](https://en.wikipedia.org/wiki/Theodore_Ts%27o). Зато на версиях 0.11 и 0.12 можно [изучать](http://www.oldlinux.org/download/ECLK-5.0-WithCover.pdf) внутренне строение ядра Linux.

А ещё, всё тот же автор oldlinux.org Jiong Zhao [написал](http://www.oldlinux.org/Linux.old/bochs-images/linux-0.00-050613.zip) фейковую версию [0.00](http://gunkies.org/wiki/Linux_0.00). Как писал Линус: "Моя первая тестовая программа использовала один процесс для выдачи на экран буквы А, а другой – для выдачи буквы В. (Звучит тоскливо – я знаю.) Я запрограммировал это так, чтобы каждую секунду писалось несколько букв. С помощью прерывания по таймеру я сделал так, что сначала экран заполнялся ААААААА. Потом неожиданно буквы сменялись на ВВВВВВВВВ.". Однако у меня в 86Box она не заработала :(.

---

# P.S.
Если у кого-нибудь будет желание запустить всё на настоящем, а не виртуальном «железе», и у вас появятся вопросы, то мои контакты можно найти в профиле Хабра или на github.com.

# P.S.S
Пока писалась это руководство, выложили статью о [внутренностях Linux версии 0.01](https://habr.com/ru/articles/754322/). Рекомендую ознакомится с ней.
