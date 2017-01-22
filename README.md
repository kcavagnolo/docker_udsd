# Docker UDSD

# AWS provision
docker-machine -D create --driver amazonec2 \
   --amazonec2-instance-type p2.xlarge \
   --amazonec2-region us-east-1 \
   --amazonec2-zone c \
   --amazonec2-retries 50 \
   --amazonec2-vpc-id $AWS_VPC_ID \
   --amazonec2-access-key $AWS_ACCESS_KEY_ID \
   --amazonec2-secret-key $AWS_SECRET_ACCESS_KEY \
   awsgpusd

# get env setup
docker-machine restart awsgpusd
docker-machine regenerate-certs awsgpusd
docker-machine env awsgpusd
eval `docker-machine env awsgpusd`

# get machine ip
docker-machine ip awsgpusd

# setup anaconda
docker pull continuumio/anaconda3

# load local nb
docker-machine scp -r . awsgpusd:

# run notebook
docker run \
-it --rm \
-v /home/ubuntu:/notebooks \
-w /notebooks \
-p 8888:8888 \
continuumio/anaconda3 /bin/bash \
-c " \
/opt/conda/bin/conda install jupyter -y --quiet && \
/opt/conda/bin/conda config --add channels menpo && \
/opt/conda/bin/conda install opencv3 -y --quiet && \
/opt/conda/bin/jupyter notebook --ip='*' --no-browser --notebook-dir=/notebooks"