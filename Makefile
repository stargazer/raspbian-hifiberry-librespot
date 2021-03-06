KERNEL_MODULES_DIR=/etc/modprobe.d
BIN_DIR=/usr/local/bin
SERVICE_DIR=/lib/systemd/system
CARGO_DIR=/home/pi/.cargo/bin
LIBRESPOT_SRC_DIR=${PWD}/librespot
LIBRESPOT_BIN_DIR=${LIBRESPOT_SRC_DIR}/target/release

setup: \
	disable-onboard-soundcard \
	configure-alsa \
	install-cargo \
	install-librespot \
	install-librespot-service \
	install-journal-watch \
	install-journal-watch-service \
	cleanup

disable-onboard-soundcard:
	sudo touch ${KERNEL_MODULES_DIR}/blacklist-onboard-soundcard.conf
	echo 'blacklist snd_bcm2835' | sudo tee ${KERNEL_MODULES_DIR}/blacklist-onboard-soundcard.conf

configure-alsa:
	sudo cp -f `pwd`/asound.conf /etc/.

install-cargo:
	curl https://sh.rustup.rs -sSf | sh

install-librespot:
	sudo apt-get install -y build-essential libasound2-dev
	git clone https://github.com/librespot-org/librespot.git
	${CARGO_DIR}/cargo build --manifest-path=${LIBRESPOT_SRC_DIR}/Cargo.toml --release
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

cleanup:
	rm -rf ${LIBRESPOT_SRC_DIR}
