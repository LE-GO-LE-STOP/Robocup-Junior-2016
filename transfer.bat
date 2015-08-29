@echo off
set /p ev3_ip="Please enter the IP of the brick: "
winscp /script=transfer.txt
exit