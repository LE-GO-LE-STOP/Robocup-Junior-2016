@echo off
set /p ev3_ip="Please enter the IP of the brick: "
putty -ssh %ev3_ip% -l legolestop -pw legolestop -m run.txt