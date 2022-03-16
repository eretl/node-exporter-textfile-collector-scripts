#!/bin/bash
#
# Description: Expose metrics from apt updates and packages versions.
#
# Author: Ben Kochie <superq@gmail.com>
# Edit: Lukas Eret

upgrades="$(/usr/bin/apt-get --just-print dist-upgrade \
  | /usr/bin/awk -F'[()]' \
      '/^Inst/ { sub("^[^ ]+ ", "", $2); gsub(" ","",$2);
                 sub("\\[", " ", $2); sub("\\]", "", $2); print $2 }' \
  | /usr/bin/sort \
  | /usr/bin/uniq -c \
  | awk '{ gsub(/\\\\/, "\\\\", $2); gsub(/"/, "\\\"", $2);
           gsub(/\[/, "", $3); gsub(/\]/, "", $3);
           print "apt_upgrades_pending{origin=\"" $2 "\",arch=\"" $NF "\"} " $1}'
)"

autoremove="$(/usr/bin/apt-get --just-print autoremove \
  | /usr/bin/awk '/^Remv/{a++}END{printf "apt_autoremove_pending %d", a}'
)"

echo '# HELP apt_upgrades_pending Apt package pending updates by origin.'
echo '# TYPE apt_upgrades_pending gauge'
if [[ -n "${upgrades}" ]] ; then
  echo "${upgrades}"
else
  echo 'apt_upgrades_pending{origin="",arch=""} 0'
fi

echo '# HELP apt_autoremove_pending Apt package pending autoremove.'
echo '# TYPE apt_autoremove_pending gauge'
echo "${autoremove}"

echo '# HELP node_reboot_required Node reboot is required for software updates.'
echo '# TYPE node_reboot_required gauge'
if [[ -f '/run/reboot-required' ]] ; then
  echo 'node_reboot_required 1'
else
  echo 'node_reboot_required 0'
fi

echo '# TYPE apt_versions gauge'
apt-show-versions -v | while read package; do
        package_name="$(echo "$package" | cut -d ':' -f1)"
        package_version="$(echo "$package" | cut -d ' ' -f2)"
        echo "apt_versions{name=\"$package_name\",version=\"$package_version\"} 1"
done

echo '# TYPE kernel_version gauge'
echo "kernel_version{version=\"$(uname -r)\"} 1"

echo '# TYPE os_version gauge'
echo "os_version{version=\"$(lsb_release -s -r)\", codename=\"$(lsb_release -s -c)\", distro=\"$(lsb_release -i -s)\"} 1"