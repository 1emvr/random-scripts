adb -s emulator-5554 push ./frida-server /data/local/tmp/frida-server
adb -s emulator-5554 shell "chmod 755 /data/local/tmp/frida-server"
adb -s emulator-5554 shell "pkill -f frida-server || kill \$(pidof frida-server) 2>/dev/null || true"

adb -s emulator-5554 root
adb -s emulator-5554 shell "id -u"
adb -s emulator-5554 shell "nohup /data/local/tmp/frida-server >/data/local/tmp/frida-server.log 2>&1 &"

adb -s emulator-5554 shell "ps -A | grep frida || ps | grep frida || toybox ps | grep frida"
adb -s emulator-5554 shell "tail -n 80 /data/local/tmp/frida-server.log || echo '<no frida-server.log>'"
frida-ps -U

