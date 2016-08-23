@echo off
title compile experis grammar
echo compile experis grammar

cd C:\HewlettPackardEnterprise\IDOLServer\eduction\bin
edktool c C:\HewlettPackardEnterprise\IDOLServer\eduction\grammar\experis.xml
edktool l C:\HewlettPackardEnterprise\IDOLServer\eduction\grammar\experis.ecr
cp C:\HewlettPackardEnterprise\IDOLServer\eduction\grammar\experis.ecr C:\HewlettPackardEnterprise\IDOLServer\cfs\grammars 

pause