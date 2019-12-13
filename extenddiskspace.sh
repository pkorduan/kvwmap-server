#!/bin/bash
# Bricht ab, wenn nutzer nicht root ist und nicht in docker gruppe
fail_unless_root() {
  dcm_user=$(id -nu)
  dcm_user_group=$(id -nG)
  # Wenn ausführender Nutzer nicht root ist
  if [ "${dcm_user}" != "root" ]; then
    echo "Nutzer ${dcm_user} ist nicht berechtigt das Script dcm auszuführen."
    echo "Führen Sie das Script als root aus."
    exit 1
  else
    echo 'Nutzer root ist berechtigt zum Ausführen des Scriptes.'
  fi
}
fail_unless_root
/sbin/lvextend -l +97248 /dev/vg00/home
/sbin/resize2fs /dev/vg00/home
dcm rm all
service docker stop
mv /var/lib/docker /home/gisadmin/docker
mv /home/gisadmin/docker/docker /home/gisadmin/docker/lib
ln -s /home/gisadmin/docker/lib /var/lib/docker
service docker start
dcm run all
df -h