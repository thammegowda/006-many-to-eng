#!/usr/bin/env bash
# Author : Thamme Gowda
# Date: Feb 20, 2021


# step 1: git clone and go in
[[ -d flores ]] || git clone https://github.com/facebookresearch/flores.git
[[ -d flores ]] &&  cd flores

# Step 2
[[ -f download-data.sh ]] || { echo "ERROR: download-data.sh not found in $PWD. Exiting.."; exit 2;  }
bash download-data.sh


# Step 3: prepare
bash prepare-neen.sh
bash prepare-sien.sh
