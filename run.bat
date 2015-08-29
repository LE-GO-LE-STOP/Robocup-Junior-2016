@echo off
set /p ev3_ip="Please enter the IP of the brick: "
"C:\Program Files (x86)\PuTTY\putty.exe" -ssh %ev3_ip% -l legolestop -pw legolestop -m run.txt