#!/usr/bin/env bash

if [[ -x $(which icuinfo) ]]; then
    echo System ICU version: $(icuinfo | grep -o '"version">[^<]\+' | grep -o '[^"><]\+$')
else
    echo 'System ICU not installed'
fi

if [[ "$1" == '' ]]; then
    echo ''
    echo 'Usage:'
    echo ''
    echo '1) bash icu-install.sh versions'
    echo ''
    echo '2) bash icu-install.sh install <version>'
fi

if [[ "$1" == 'versions' ]]; then
    echo ''
    echo 'Available ICU versions'
    wget -O - https://icu.unicode.org/download 2>/dev/null | grep -P -o '(?<=http://site.icu-project.org/download/)\d+#TOC-ICU4C-Download.+;&gt;\K[\d.]+'
fi

if [[ "$2" != "" && "$1" == 'install' ]]; then
    which g++ || sudo apt install -y g++

    ICU_VERSION=$2
    ICU_SRC_FILE="icu4c-$(echo $ICU_VERSION | sed -e 's/\./_/')-src.tgz"
    echo "Trying to install ICU version: $ICU_VERSION"
    if [[ ! -e "$ICU_SRC_FILE" ]]; then
        wget "https://github.com/unicode-org/icu/releases/download/release-$(echo $ICU_VERSION | sed -e 's/\./-/')/$ICU_SRC_FILE"
    fi
    if [[ ! -e "$ICU_SRC_FILE" ]]; then
        exit 1;
    fi

    ICU_SRC_FOLDER="icu-release-$(echo $ICU_VERSION | sed -e 's/\./-/')"
    tar zxvf "$ICU_SRC_FILE"
    which g++ || sudo apt install -y g++

    if [[ ! -e "/opt/icu$ICU_VERSION" ]]; then
        pushd icu/source
            sudo mkdir "/opt/icu$ICU_VERSION"
            ./configure --prefix="/opt/icu$ICU_VERSION" && make -j2 && sudo make install
            ls -alh /opt/icu$ICU_VERSION/lib/
            sudo cp -r /opt/icu$ICU_VERSION/lib/* /usr/local/lib
        popd
    else
        echo "ICU already installed at (/opt/icu$ICU_VERSION)"
    fi

    rm -f "$ICU_SRC_FILE"
fi