KERNEL_MODULES_DIR=/etc/modprobe.d
BIN_DIR=/usr/local/bin
SERVICE_DIR=/lib/systemd/system
CARGO_DIR=/home/pi/.cargo/bin
LIBRESPOT_SRC_DIR=${PWD}/librespot
LIBRESPOT_BIN_DIR=${LIBRESPOT_SRC_DIR}/target/release

setup: \
	disable-onboard-soundcard \
	kernel-4-5-compatibility \
	configure-alsa \
	install-cargo \
	install-librespot \
	install-librespot-service \
	install-journal-watch \
	install-journal-watch-service \
	disable-wifi-power-management \
	enable-noroot-logins \
	cleanup

disable-onboard-soundcard:
	sudo touch ${KERNEL_MODULES_DIR}/blacklist-onboard-soundcard.conf
	echo 'blacklist snd_bcm2835' | sudo tee ${KERNEL_MODULES_DIR}/blacklist-onboard-soundcard.conf

kernel-4-5-compatibility:
	echo "\n" | sudo tee -a /boot/config.txt
	echo "force_eeprom_read=0\n" | sudo tee -a /boot/config.txt
	echo "dtoverlay=hifiberry-dacplus" | sudo tee -a /boot/config.txt

configure-alsa:
	sudo cp -f `pwd`/asound.conf /etc/.

install-cargo:
	curl https://sh.rustup.rs -sSf | sh

install-librespot:
	sudo apt-get install -y build-essential libasound2-dev libssl-dev
	
	git clone -b dev https://github.com/librespot-org/librespot.git

	${CARGO_DIR}/cargo build --manifest-path=${LIBRESPOT_SRC_DIR}/Cargo.toml --release --features alsa-backend
	sudo cp -f ${LIBRESPOT_BIN_DIR}/librespot ${BIN_DIR}/.

install-librespot-service:
	sudo cp -f `pwd`/librespot.service ${SERVICE_DIR}/librespot.service
	sudo chmod 644 ${SERVICE_DIR}/librespot.service
	sudo systemctl daemon-reload
	sudo systemctl restart librespot
	sudo systemctl enable librespot

install-journal-watch:
	sudo cp -f `pwd`/journal-watch.sh ${BIN_DIR}/.
	sudo chmod a+x ${BIN_DIR}/journal-watch.sh

install-journal-watch-service:
	sudo cp -f `pwd`/journal-watch.service ${SERVICE_DIR}/.
	sudo chmod 644 ${SERVICE_DIR}/journal-watch.service
	sudo systemctl daemon-reload
	sudo systemctl restart journal-watch
	sudo systemctl enable journal-watch

disable-wifi-power-management:
	# Writes the appropriate line in `/etc/rc.local`, right before the line `exit 0`
	sudo sed -i "/exit 0/i\/sbin/iw wlan0 set power_save off" /etc/rc.local

enable-noroot-logins:
	# Comments out the line `auth requisite pam_nologin.so` from `/etc/pam.d/login`,
	# thus allowing no-root logins during boot
	sudo sed -i '/pam_nologin/s/^#\?/#/'  /etc/pam.d/login

cleanup:
	rm -rf ${LIBRESPOT_SRC_DIR}
