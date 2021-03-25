

# create an environment for t2t
#conda create -n t2t python=3.7
#cond activate t2t
#conda install -c anaconda cudatoolkit=10.0 cudnn=7   
#pip install tensor2tensor==1.15.7 tensorflow_gpu==1.15 tensorflow=1.15
#python -c 'import tensorflow as tf; print(tf.test.is_gpu_available())'

conda create -n t2t python=3.6
cond activate t2t
conda install -c anaconda cudatoolkit=9.0 cudnn=7   
pip install tensor2tensor==1.7 tensorflow_gpu==1.10
python -c 'import tensorflow as tf; print(tf.test.is_gpu_available())'



conda deactivate

#create an evironemnt for fairseq
conda create -n fairseq pythpn=3.7
conda actiavte fairseq
pip install fairseq==0.10.2 sentencepiece==0.1.95 sacremoses


# create an environment for rtg
# conda create -n rtg python=3.7
# pip install rtg[big]


