#!/bin/bash
# Необходимые функции для работы скрипта
checkif()
{
local AMSURE
if [ -n "$1" ] ; then
   read -p "$1 (y/n): " AMSURE
else
   read AMSURE
fi
echo "" 1>&2
if [ "$AMSURE" = "y" ] ; then
   return 0
else
   return 1
fi
}

sayWait() 
{ 
   local AMSURE 
   [ -n "$1" ] && echo "$@" 1>&2 
   read -p "(нажмите любую клавишу для продолжения)" AMSURE 
   echo "" 1>&2 
}

input() 
{
   local a1

   if [ -n "$1" ] ; then
      read -p "$1" cRes
   else
      read cRes
   fi

   # Проверка допустимых выборов
   while [ "$2" = "${2#*$cRes}" ] ; do
      echo -n "Неверное значение, введите правильное: "
      read cRes
   done
}

# Принимает параметры [имя настройки],[замена],[путь]
SettingsPatch() 
{ 
    local infile=$3
    local outfile=$3".tmp"
    sed -r "s/<String Name=\"$1\">(.*)<\/String>/<String Name=\"$1\">$2<\/String>/g" $infile > $outfile
    mv $outfile $infile 
}

# Функция позваляет спрашивать и записывать введеные данные в файл
inputSetting() 
{
   local a1

   if [ -n "$1" ] ; then
      read -p "$1" cRes
   else
      read cRes
   fi

   # Проверка допустимых выборов
   if [ "$cRes" != "" ] ; then
      SettingsPatch "$3" "$cRes" "$4"
      SetArr=$cRes
   else
      SettingsPatch "$3" "$2" "$4"
      SetArr=$2
   fi
}

# Функция позваляет спрашивать и записывать введеные регистрационые данные в файл
inputRegUser() 
{
   local a1

   if [ -n "$1" ] ; then
      read -p "$1" cRes
   else
      read cRes
   fi

   # Проверка допустимых выборов
   if [ "$cRes" != "" ] ; then
      SetArr=$cRes
   else
      SetArr=$2
   fi
}


# Непосредственно тело скрипта
echo "========================================="
echo "  Скрипт установки и настройки PtokaX"
echo "========================================="
checkif "Ты уверен, что хочешь запустить это?" || exit

cat <<'EOF'
Выбери версию PtokaX которую хотите установить: 
-----------------------------------------------
   1) PtokaX 0.5.0.0
   2) PtokaX 0.4.2.0
   3) PtokaX 0.4.1.2
   4) PtokaX 0.4.1.1
   5) PtokaX 0.4.1.0
EOF
input "Введите индекс версии: " "12345"
clear

echo "========================================="
echo "1. Устанавливаем необходимые программы..."
echo "========================================="
# Создаем файл log.txt
echo "Логирование вывода скрипта установки ptokax: " > log.txt
chmod 666 log.txt

# Спрашиваем root пароль чтобы в дальнейшем его знать и выполнять команды
echo -n "Введите пароль суперпользователя (root): "
read rootpas

echo -n "Начало установки требуемых программ...              "
case $cRes in
1) echo $rootpas | sudo -S apt-get install -y g++ make liblua5.2 liblua5.2-dev zlib1g zlib1g-dbg zlib1g-dev psutils wget unzip >> log.txt 2>&1 | exit ;;
2) echo $rootpas | sudo -S apt-get install -y g++ make liblua5.1 liblua5.1-dev zlib1g zlib1g-dbg zlib1g-dev psutils wget unzip >> log.txt 2>&1 | exit;;
3) echo $rootpas | sudo -S apt-get install -y g++ make liblua5.1 liblua5.1-dev zlib1g zlib1g-dbg zlib1g-dev psutils wget unzip >> log.txt 2>&1 | exit;;
4) echo $rootpas | sudo -S apt-get install -y g++ make liblua5.1 liblua5.1-dev zlib1g zlib1g-dbg zlib1g-dev psutils wget unzip >> log.txt 2>&1 | exit;;
5) echo $rootpas | sudo -S apt-get install -y g++ make liblua5.1 liblua5.1-dev zlib1g zlib1g-dbg zlib1g-dev psutils wget unzip >> log.txt 2>&1 | exit;;
esac
echo "OK"

echo -n "Создаем папку для установки...                      "
# проверяем наличие директории
dirName="ptokax"
directory="./ptokax"
if [ -d $directory ]; then
echo "\nОбратим внимание что директория ptokax существует"
   while [ -d "./"$dirName ] ; do
      echo -n "Введите желаемое имя директории: "
      read dirName
   done
   mkdir $dirName
   chmod 755 $dirName
   echo "Директория $dirName успешно создана!"
else
mkdir $dirName
chmod 755 $dirName
echo "OK"
fi

# Переходим в рабочую папку
cd $dirName/

echo -n "Скачиваем необходимые файлы"
# Скачиваем исходники tinyxml
wget --output-document=tinyxml.zip http://sourceforge.net/projects/tinyxml/files/latest/download >> ../log.txt 2>&1
echo -n "."
# Скачиваем исходники ptokax в зависимости от выбраной версии
case $cRes in
1) wget --output-document=ptokax.tgz http://www.czdc.org/PtokaX/0.5.0.0-nix-src.tgz >> ../log.txt 2>&1;;
2) wget --output-document=ptokax.tgz http://www.czdc.org/PtokaX/0.4.2.0-nix-src.tgz >> ../log.txt 2>&1;;
3) wget --output-document=ptokax.tgz http://www.czdc.org/PtokaX/0.4.1.2-nix-src.tgz >> ../log.txt 2>&1;;
4) wget --output-document=ptokax.tgz http://www.czdc.org/PtokaX/0.4.1.1-posix-src.tgz >> ../log.txt 2>&1;;
5) wget --output-document=ptokax.tgz http://www.czdc.org/PtokaX/0.4.1.0-posix-src.tgz >> ../log.txt 2>&1;;
esac
echo -n "."
# Скачиваем скрипт для запуски хаба
wget --output-document=ptokax https://raw.github.com/DEN007/ptokax-install-source/master/init.d/ptokax >> ../log.txt 2>&1
echo -n "."
echo "                      OK"

# Распаковываем скаченные файлы и раскидываем их по нужным папкам
echo -n "Распаковываем необходимые файлы"
tar -xf ptokax.tgz >> ../log.txt 2>&1
echo -n "."
unzip tinyxml.zip >> ../log.txt 2>&1
echo -n "."
mv -n tinyxml/* PtokaX/tinyxml/
mkdir PtokaX/initd/
echo -n "."
mv ptokax PtokaX/initd/
echo "                  OK"

# Собираем tinyxml из исходников
echo -n "Собираем tinyxml (Около минуты)...                  "
cd PtokaX/tinyxml/
make >> ../../../log.txt 2>&1
echo "OK"

# Патчим makefile для возможности установки и обновления 
echo -n "Пачим makefile ptokax...                            "
cd ../
line='  '
echo " ">>makefile
echo "#*******************************************************************************">>makefile
echo "# Install">>makefile
echo "#*******************************************************************************">>makefile
echo "install:">>makefile
echo "$line- mv PtokaX ptokax">>makefile
echo "$line- mkdir /etc/ptokax">>makefile
echo "$line"'- cp $(CURDIR)/ptokax /usr/sbin/'>>makefile
echo "$line"'- cp -r $(CURDIR)/cfg /etc/ptokax/'>>makefile
echo "$line"'- cp -r $(CURDIR)/language /etc/ptokax/'>>makefile
echo "$line"'- cp $(CURDIR)/initd/ptokax /etc/init.d/'>>makefile
echo "$line- chmod +rx /etc/init.d/ptokax">>makefile
echo "$line- update-rc.d ptokax defaults">>makefile
echo "#*******************************************************************************">>makefile
echo "# ReInstall">>makefile
echo "#*******************************************************************************">>makefile
echo "reinstall:">>makefile
echo "$line- killall -9 ptokax">>makefile
echo "$line- update-rc.d -f ptokax remove">>makefile
echo "$line- rm -r /etc/ptokax">>makefile
echo "$line- rm /etc/init.d/ptokax">>makefile
echo "$line- rm /usr/sbin/ptokax">>makefile
echo "$line- mv PtokaX ptokax">>makefile
echo "$line- mkdir /etc/ptokax">>makefile
echo "$line"'- cp $(CURDIR)/ptokax /usr/sbin/'>>makefile
echo "$line"'- cp -r $(CURDIR)/cfg /etc/ptokax/'>>makefile
echo "$line"'- cp -r $(CURDIR)/language /etc/ptokax/'>>makefile
echo "$line"'- cp $(CURDIR)/initd/ptokax /etc/init.d/'>>makefile
echo "$line- chmod +rx /etc/init.d/ptokax">>makefile
echo "$line- update-rc.d ptokax defaults">>makefile
echo "#*******************************************************************************">>makefile
echo "# Upgrade">>makefile
echo "#*******************************************************************************">>makefile
echo "upgrade:">>makefile
echo "$line- mv PtokaX ptokax">>makefile
echo "$line"'- cp $(CURDIR)/ptokax /usr/sbin/'>>makefile
echo "#*******************************************************************************">>makefile
echo "# UnInstall">>makefile
echo "#*******************************************************************************">>makefile
echo "uninstall:">>makefile
echo "$line- killall -9 ptokax">>makefile
echo "$line- update-rc.d -f ptokax remove">>makefile
echo "$line- rm -r /etc/ptokax">>makefile
echo "$line- rm /etc/init.d/ptokax">>makefile
echo "$line- rm /usr/sbin/ptokax">>makefile
echo "OK"

# Собираем непосредственно Ptokax
echo -n "Собираем PtokaX (Это продолжительный процесс)...    "
make >> ../../log.txt 2>&1
echo "OK"

# Проверяем собрался ли бинарник
echo -n "Проверяем существует ли бинарник PtokaX...          "
if [ -f "PtokaX" ]; then
echo "ОК"
else
echo " "
echo "Произошла какая-то ошибка бинарник не собрался, посмотрите log.txt файл"
sayWait
exit
fi

# Прибераемся
echo -n "Немного убираемся за собой"
rm -r tinyxml/
rm -r obj/
rm -r core/
mv cfg.example/ cfg/
cd ../
echo -n "."
rm -r tinyxml/
rm ptokax.tgz
rm tinyxml.zip
mv PtokaX/ PtokaX1/
echo -n "."
cd PtokaX1/
mv * ../
cd ../
echo -n "."
rm -r PtokaX1/
echo "                       OK"
sayWait
clear

# Выбераем дальнейшии действии над собраным бинарником
echo "========================================="
echo "    2. Установка & обновление PtokaX"
echo "========================================="

cat <<'EOF'
Что будем делать с собраным бинарником PtokaX: 
-----------------------------------------------
   1) Установим PtokaX в систему (настройки собьются)
   2) Обновим только бинарник PtokaX
   3) Переустановим PtokaX
   4) Удалить ранее установленый PtokaX из системы
   5) Выйти
EOF
input "Введите индекс действия: " "12345"

echo -n "Выполнение операций с PtokaX...                     "
case $cRes in
1) echo $rootpas | sudo -S make install >> ../log.txt 2>&1 | exit;;
2) echo $rootpas | sudo -S make upgrade >> ../log.txt 2>&1 | exit;;
3) echo $rootpas | sudo -S make reinstall >> ../log.txt 2>&1 | exit;;
4) echo $rootpas | sudo -S make uninstall >> ../log.txt 2>&1 | exit
echo "OK"
sayWait
exit;;
5) exit;;
esac
echo "OK"
sayWait
clear

# Производит предварительную настройку хаба, 
# принимает параметр 2 нужно запустить вункцию из функции
settingsHub ()
{
# Выполним предварительную настройку PtokaX
echo "========================================="
echo "     3. Базовая настройка PtokaX"
echo "========================================="
if [ $1 = 2 ] ; then
echo " "
else
checkif "Произвести предварительную настройку, иначе выйти?" || exit

# Запускаем сервер чтобы создались файлы с настройками
echo -n "Пробуем запустить сервер PtokaX."
echo $rootpas | sudo -S /etc/init.d/ptokax start >> ../log.txt 2>&1 | exit
echo -n "."
sleep 3
echo -n "."
echo $rootpas | sudo -S /etc/init.d/ptokax stop >> ../log.txt 2>&1 | exit
echo "                  OK"
# Правим конфиги
# создаем копию файла с которой будим дальше работать
SettingFilename=Settings.xml.edit
echo $rootpas | sudo -S cp /etc/ptokax/cfg/Settings.xml $SettingFilename >> ../log.txt 2>&1 | exit
echo $rootpas | sudo -S chmod 666 $SettingFilename >> ../log.txt 2>&1 | exit
fi
echo "======Приступаем к настройке хаба.======="
echo " "
inputSetting "Введите название хаба (по умолчанию Мой хаб): " "Мой хаб" "HubName" $SettingFilename
SetArray[0]=$SetArr
inputSetting "Введите ник админа (по умолчанию Админ): " "Админ" "AdminNick" $SettingFilename
SetArray[1]=$SetArr
inputSetting "Введите адрес хаба (по умолчанию localhost): " "localhost" "HubAddress" $SettingFilename
SetArray[2]=$SetArr
inputSetting "Введите порт хаба (по умолчанию 411): " "411" "TCPPorts" $SettingFilename
SetArray[3]=$SetArr
inputSetting "Введите язык хаба (по умолчанию Russian): " "Russian" "Language" $SettingFilename
SetArray[4]=$SetArr
clear
echo "========================================="
echo "     3. Базовая настройка PtokaX"
echo "========================================="
echo " "
echo "=======Проверим введеные данные!========="
echo " "
echo 'Вы ввели в качестве "Название хаба": '${SetArray[0]}
echo 'Вы ввели в качестве "Ника админа":   '${SetArray[1]}
echo 'Вы ввели в качестве "Адреса хаба":   '${SetArray[2]}
echo 'Вы ввели в качестве "Порта хаба":    '${SetArray[3]}
echo 'Вы ввели в качестве "Языка хаба":    '${SetArray[4]}
echo " "
cat <<'EOF'
Выберите действие: 
-----------------------------------------------
   1) Сохранить настройки в файл
   2) Ввести еще раз
   3) Выйти
EOF
input "Введите индекс действия: " "123"

echo -n "Выполнение операции сохранения настроек PtokaX...   "
case $cRes in
1) echo $rootpas | sudo -S mv $SettingFilename /etc/ptokax/cfg/Settings.xml >> ../log.txt 2>&1 | exit;;
2) clear
settingsHub "2";;
3) exit;;
esac
sleep 1
echo "OK"
sayWait
clear
}
# Сообственоо запускаем эту функцию)
settingsHub "0"

# Выполним установку скрипта PXControl
echo "========================================="
echo "   4. Установка удаленного управления"
echo "========================================="
echo " "
checkif "Выполним установку скрипта PXControl, иначе выйти?" || exit

# Скачиваем скрипт PXControl
echo -n "Скачиваем скрипт PXControl."
wget --output-document=PXControl_Server.lua https://raw.github.com/DEN007/ptokax-install-source/master/lua/PXControl_Server.lua >> ../log.txt 2>&1
echo -n "."
echo $rootpas | sudo -S mv PXControl_Server.lua /etc/ptokax/scripts/ >> ../log.txt 2>&1 | exit
echo -n "."
echo $rootpas | sudo -S chmod 666 /etc/ptokax/scripts/PXControl_Server.lua >> ../log.txt 2>&1 | exit
echo "                       OK"

# Включаем скрипт в настройках PtokaX
echo -n "Включаем скрипт в настройках PtokaX..."
echo '<?xml version="1.0" encoding="windows-1252" standalone="yes" ?>'>Scripts.xml
echo "<Scripts>">>Scripts.xml
echo "    <Script>">>Scripts.xml
echo "        <Name>PXControl_Server.lua</Name>">>Scripts.xml
echo "        <Enabled>1</Enabled>">>Scripts.xml
echo "    </Script>">>Scripts.xml
echo "</Scripts>">>Scripts.xml
echo $rootpas | sudo -S mv Scripts.xml /etc/ptokax/cfg/Scripts.xml >> ../log.txt 2>&1 | exit
echo $rootpas | sudo -S chmod 666 /etc/ptokax/cfg/Scripts.xml >> ../log.txt 2>&1 | exit
echo "              OK"

# Установим библиотеку LuaFileSystem
echo -n "Устанавливаем библиотеку LuaFileSystem...           "
echo $rootpas | sudo -S apt-get install -y liblua5.1-filesystem0 liblua5.1-filesystem-dev >> ../log.txt 2>&1 | exit
echo "OK"

# Регистрируем пользователя для PXControl
echo " "
echo "==Регистрируем пользователя для PXControl=="
echo " "

# Генерируем случайный пароль
MATRIX="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
LENGTH="8"
while [ "${n:=1}" -le "$LENGTH" ]
do
        PASS="$PASS${MATRIX:$(($RANDOM%${#MATRIX})):1}"
        let n+=1
done

inputRegUser "Введите логин админа (по умолчанию RemoteAdmin): " "RemoteAdmin"
AdminNic=$SetArr
inputRegUser "Введите пароль админа (по умолчанию $PASS):  " "$PASS"
AdminPas=$SetArr
echo '<?xml version="1.0" encoding="windows-1252" standalone="yes" ?>'>RegisteredUsers.xml
echo "<RegisteredUsers>">>RegisteredUsers.xml
echo "    <RegisteredUser>">>RegisteredUsers.xml
echo "        <Nick>$AdminNic</Nick>">>RegisteredUsers.xml
echo "        <Password>$AdminPas</Password>">>RegisteredUsers.xml
echo "        <Profile>0</Profile>">>RegisteredUsers.xml
echo "    </RegisteredUser>">>RegisteredUsers.xml
echo "</RegisteredUsers>">>RegisteredUsers.xml
echo $rootpas | sudo -S mv RegisteredUsers.xml /etc/ptokax/cfg/RegisteredUsers.xml >> ../log.txt 2>&1 | exit
echo $rootpas | sudo -S chmod 666 /etc/ptokax/cfg/RegisteredUsers.xml >> ../log.txt 2>&1 | exit
echo "Пользователь успешно добавлен в базу PtokaX...      OK"
echo -n "Создание файла с логином и паролем...               "
echo "===================================================">../Настройки_хаба.txt
echo "        Настройки для подключения к ${SetArray[0]}">>../Настройки_хаба.txt
echo "===================================================">>../Настройки_хаба.txt
echo "">>../Настройки_хаба.txt
echo "Адрес хаба: dchhub://${SetArray[2]}:${SetArray[3]}">>../Настройки_хаба.txt
echo "">>../Настройки_хаба.txt
echo "              Настройка для RXControl">>../Настройки_хаба.txt
echo "">>../Настройки_хаба.txt
echo "Логин:        $AdminNic">>../Настройки_хаба.txt
echo "Пароль:       $AdminPas">>../Настройки_хаба.txt
echo "OK"
sayWait
clear

# Запускаем сервер чтобы создались файлы с настройками
echo "========================================="
echo "       5. Завершающая стадия"
echo "========================================="
echo " "
echo -n "Запускаем PtokaX...                                 "
echo $rootpas | sudo -S /etc/init.d/ptokax start >> ../log.txt 2>&1 | exit
echo "OK"
echo -n "Пробуем подключится к хабу...                       "
wget --output-document=test.txt "http://${SetArray[2]}:${SetArray[3]}" >> ../log.txt 2>&1
checkHub=`grep -c "PtokaX" test.txt` >> ../log.txt 2>&1
rm test.txt >> ../log.txt 2>&1
#Проверяем, что хаб откликается
if [ $checkHub = 1 ]
then
  echo "OK"
  statusHub=1
else
  echo "FAIL"
  statusHub=0
fi

# Удаляем папку
checkifVar=1
echo " "
checkif "Временную папку с откомпилированым PtokaX, удаляем?" || checkifVar=0
   if [ "$checkifVar" = "1" ] ; then
      cd ../ >/dev/null 2>&1
      rm -r $dirName/ >> log.txt 2>&1
      echo "Удалено"
      dirCheck="1"
   else
      echo "Оставили"
   fi
# удаляем лог
checkifVar=1
checkif "Все это время весь вывод терминала логировался в log.txt, удаляем?" || checkifVar=0
   if [ "$checkifVar" = "1" ] ; then
   if [ "$dirCheck" = "1" ] ; then
      rm log.txt >/dev/null 2>&1
      echo "Удалено"
   else
      cd ../ >/dev/null 2>&1
      rm log.txt >/dev/null 2>&1
      echo "Удалено"
   fi
   else
      echo "Оставили"
   fi

# Проверяем запущен ли хаб
if [ "statusHub" = 1 ] ; then
checkifVar=1
checkif "Хаб все еще запущен и работает, выключить его?" || checkifVar=0
   if [ "$checkifVar" = "1" ] ; then
      echo $rootpas | sudo -S /etc/init.d/ptokax stop >/dev/null 2>&1 | exit
      echo "Хаб остановлен!"
   else
      echo "Хаб продолжает работать!"
   fi
else
checkifVar=1
checkif "Хаб не получилось запустить ранее, попробывать сейчас?" || checkifVar=0
   if [ "$checkifVar" = "1" ] ; then
      echo $rootpas | sudo -S /etc/init.d/ptokax start >/dev/null 2>&1 | exit
      echo "Хаб возможно запустился!"
   else
      echo "Хаб не включали!"
   fi
fi
sayWait
clear

# Запускаем сервер чтобы создались файлы с настройками
echo "========================================="
echo "       Все успешно установилось"
echo "========================================="
echo " "
echo "  Для запуска хаба используйте команду: "
echo "       /etc/init.d/ptokax start"
echo " "
echo " Для остановки хаба используйте команду"
echo "       /etc/init.d/ptokax stop"
echo " "
echo " Для перезапуска хаба используйте команду"
echo "       /etc/init.d/ptokax restart"
echo " "
echo "Постустановочные настройки сохранены в "
echo '        файле "Настройки_хаба.txt"'
echo "он находится в той же папке, с которой "
echo "          был запущен скрипт."
echo ""
echo ""
echo "             Лицензия: GPL v3"
echo "https://github.com/DEN007/ptokax-install-source"
echo "        (c) develop by den007 2013"
echo "             den007@smol-hub.net    "
echo "========================================="
sayWait
clear
