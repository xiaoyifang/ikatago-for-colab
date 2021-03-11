#!/bin/bash

KATAGO_BACKEND=$1
WEIGHT_FILE="40b"
GPU_NAME=`nvidia-smi -q | grep "Product Name" | cut -d":" -f2 | tr -cd '[:alnum:]._-'`
#GPU_NAME=TeslaT4

detect_auto_backend () {
  if [[ "$GPU_NAME" =~ .*"TeslaT4".* ]]
  then
    KATAGO_BACKEND="OPENCL"
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


if [ "$KATAGO_BACKEND" == "AUTO" ]
then
  detect_auto_backend
fi


echo "Using GPU: " $GPU_NAME
echo "Using Katago Backend: " $KATAGO_BACKEND
echo "Using Katago Weight: " $WEIGHT_FILE



#apt install --yes libzip4 1>/dev/null

#libzip5
apt-get install gcc cmake -y
wget https://libzip.org/download/libzip-1.5.2.tar.gz -O  /content/libzip-1.5.2.tar.gz
tar -zxvf  /content/libzip-1.5.2.tar.gz -C /content/
cd /content/libzip-1.5.2
cmake /content/libzip-1.5.2/
make && make install
ln -s /usr/local/lib/libzip.so.5 /usr/lib

cd /content/work
WEIGHT_URL="https://media.katagotraining.org/uploaded/networks/models/kata1/kata1-b40c256-s6809346304-d1651897329.bin.gz"
echo "Using Weight URL: " $WEIGHT_URL

#download the binarires
if [ "$KATAGO_BACKEND" == "CUDA" ]
then
wget  https://github.com/lightvector/KataGo/releases/download/v1.8.0/katago-v1.8.0-cuda11.1-linux-x64.zip -O katago.zip
else
wget  https://github.com/lightvector/KataGo/releases/download/v1.8.0/katago-v1.8.0-opencl-linux-x64.zip -O katago.zip
fi

unzip -qq  katago.zip
mv katago ./data/bins/katago
chmod +x ./data/bins/katago
#wget --quiet https://github.com/kinfkong/ikatago-for-colab/releases/download/$RELEASE_VERSION/katago-$KATAGO_BACKEND -O ./data/bins/katago


#download the weights
wget --quiet $WEIGHT_URL -O "./data/weights/"$WEIGHT_FILE".bin.gz" 



