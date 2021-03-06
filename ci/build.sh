#!/bin/bash

#参数
FTP_HOST=$2
FTP_USER=$3
FTP_PSWD=$4

git fetch --unshallow
COUNT=$(git rev-list --count HEAD)
FILE=$COUNT-$5-$6.7z
DATE=$(date +"%Y/%m/%d %H:%M:%S")


#INFO
echo -e "*** Trigger build ***"


#下载SM
echo -e "Download sourcemod ..."
wget "http://www.sourcemod.net/latest.php?version=$1&os=linux" -q -O sourcemod.tar.gz
tar -xzf sourcemod.tar.gz


#建立include文件夹
mkdir include
mkdir include/MagicGirl


#下载MG头文件
echo -e "Download MagicGirl.NET.inc ..."
wget "https://github.com/PuellaMagi/Core/raw/master/Game/include/MagicGirl.NET.inc" -q -O include/MagicGirl.NET.inc
echo -e "Download vars.inc ..."
wget "https://github.com/PuellaMagi/Core/raw/master/Game/include/MagicGirl/vars.inc" -q -O include/MagicGirl/vars.inc


#下载System2头文件
echo -e "Download system2.inc ..."
wget "https://github.com/dordnung/System2/raw/v2.6/system2.inc" -q -O include/system2.inc


#设置文件为可执行
echo -e "Set compiler env ..."
chmod +x addons/sourcemod/scripting/spcomp


#更改版本信息
echo -e "Prepare compile ..."
for file in autoupdater.sp
do
  sed -i "s%<commit_count>%$COUNT%g" $file > output.txt
  sed -i "s%<commit_branch>%$5%g" $file > output.txt
  sed -i "s%<commit_date>%$DATE%g" $file > output.txt
  rm output.txt
done


#建立文件夹以准备拷贝文件
mkdir addons/sourcemod/scripting/updater


#拷贝文件到编译器文件夹
echo -e "Copy scripts to compiler folder ..."
cp -r updater/* addons/sourcemod/scripting/updater
cp -r include/* addons/sourcemod/scripting/include


#建立输出文件夹
echo -e "Check build folder ..."
mkdir build


#编译
cp autoupdater.sp addons/sourcemod/scripting
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/autoupdater.sp -o"build/autoupdater.smx"
if [ ! -f "build/autoupdater.smx" ]; then
    echo "Compile failed!"
    exit 1;
fi


#移动文件
echo -e "Move files to build folder ..."
mv updater build
mv autoupdater.sp build
mv LICENSE build


#打包
echo -e "Compress file ..."
cd build
7z a $FILE -t7z -mx9 LICENSE updater autoupdater.sp autoupdater.smx >nul


#上传
echo -e "Upload file ..."
lftp -c "open -u $FTP_USER,$FTP_PSWD $FTP_HOST; put -O /Updater/$1/ $FILE"


#RAW
if [ "$1" = "1.8" ]; then
    echo "Upload RAW..."
    lftp -c "open -u $FTP_USER,$FTP_PSWD $FTP_HOST; put -O /Updater/Raw/ autoupdater.smx"
fi