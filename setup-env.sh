#!/bin/bash

KATAGO_BACKEND=$1
WEIGHT_FILE=$2
RELEASE_VERSION=1.4.1
GPU_NAME=`nvidia-smi -q | grep "Product Name" | cut -d":" -f2 | tr -cd '[:alnum:]._-'`
#GPU_NAME=TeslaT4

detect_auto_backend () {
  if [[ "$GPU_NAME" =~ .*"TeslaT4".* ]]
  then
    KATAGO_BACKEND="CUDA"
  elif [[ "$GPU_NAME" =~ .*"TeslaP100".* ]]
  then
    KATAGO_BACKEND="CUDA"
  elif [[ "$GPU_NAME" =~ .*"TeslaV100".* ]]
  then
    KATAGO_BACKEND="CUDA"
  else
    KATAGO_BACKEND="OPENCL"
  fi
}

detect_auto_weight () {
  if [ "$GPU_NAME" == "TeslaK80" ]
  then
    WEIGHT_FILE="20b"
  elif [ "$GPU_NAME" == "TeslaP4" ]
  then
    WEIGHT_FILE="20b"
  else
    WEIGHT_FILE="40b"
  fi
}

if [ "$KATAGO_BACKEND" == "AUTO" ]
then
  detect_auto_backend
fi

if [ "$WEIGHT_FILE" == "AUTO" ]
then
  detect_auto_weight
fi

echo "Using GPU: " $GPU_NAME
echo "Using Katago Backend: " $KATAGO_BACKEND
echo "Using Katago Weight: " $WEIGHT_FILE



#apt install --yes libzip4 1>/dev/null

#libzip5
apt-get install gcc cmake -y
wget https://libzip.org/download/libzip-1.5.2.tar.gz -O  /content/libzip-1.5.2.tar.gz
tar -zxvf  /content/libzip-1.5.2.tar.gz -C /content/

cmake /content/libzip-1.5.2/
make && make install
ln -s /usr/local/lib/libzip.so.5 /usr/lib

cd /content

if [ ! -d work ]
then
    wget  https://github.com/kinfkong/ikatago-for-colab/releases/download/$RELEASE_VERSION/work.zip -O work.zip
    unzip -qq work.zip
fi

cd /content/work
WEIGHT_URL=`grep "^$WEIGHT_FILE " ./weight_urls.txt | cut -d ' ' -f2`
echo "Using Weight URL: " $WEIGHT_URL

#download the binarires
if [ "$KATAGO_BACKEND" == "CUDA" ]
then
wget  https://github.com/lightvector/KataGo/releases/download/v1.7.0/katago-v1.7.0-gpu-cuda10.2-linux-x64.zip -O katago1.7.zip
else
wget  https://github.com/lightvector/KataGo/releases/download/v1.7.0/katago-v1.7.0-gpu-opencl-linux-x64.zip -O katago1.7.zip
fi

unzip -qq  katago1.7.zip
mv katago ./data/bins/katago
chmod +x ./data/bins/katago
#wget --quiet https://github.com/kinfkong/ikatago-for-colab/releases/download/$RELEASE_VERSION/katago-$KATAGO_BACKEND -O ./data/bins/katago

mkdir -p /root/.katago/
cp -r ./opencltuning /root/.katago/

#download the weights
wget --quiet $WEIGHT_URL -O "./data/weights/"$WEIGHT_FILE".bin.gz" 

chmod +x ./change-config.sh
./change-config.sh $WEIGHT_FILE "./data/weights/"$WEIGHT_FILE".bin.gz"

chmod +x ./ikatago-server
