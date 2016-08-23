# IDOLServer
configuration files for IDOL

1. configuration files
the *.cfg files have to be copied to the correspondant IDOLServer repository of the local virtual machine

2. grammar files
to generate a new grammar
* copy experis.xml file to C:\HewlettPackardEnterprise\IDOLServer\eduction\grammar
* modify the file and launch compile.bat
* the above script copies experis.ecr to C:\HewlettPackardEnterprise\IDOLServer\cfs\grammars
* you have to modify cfs.cfg if you have added new entities to your dictionnary

3.lua script
somme sample scripts are available for integration tests purpose
* EnrichDocument.lua (parses metadata from the alternative to the IDOL system and adds them as new fields and new content in indexed documents)
* EnrichDocument2.lua (empty skeleton that sends one user generated metadata)
* EnrichDocument3.lua (parses all metadata of a predetermined field computed by IDOL)
* EnrichDocument4.lua (parses the metadata of the first EDK_* field computed by Eduction)
* EnrichDocument5.lua (parses the metadata of all EDK_* fields computed by Eduction)

4.additional metadata csv files
these files are stored in C:\HewlettPackardEnterprise\IDOLServer\cfs\scripts, they contain additional metadata provided by the alternative to the IDOL system