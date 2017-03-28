# setup security group
aws ec2 create-security-group \
   --group-name jupyter \
   --description 'sc for running jupyter notebook server'
aws ec2 authorize-security-group-ingress \
   --group-name jupyter \
   --protocol tcp \
   --port 22 \
   --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress \
   --group-name jupyter \
   --protocol tcp \
   --port 2376 \
   --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress \
   --group-name jupyter \
   --protocol tcp \
   --port 8888 \
   --cidr 0.0.0.0/0

# build docker instance
docker-machine -D create --driver amazonec2 \
--amazonec2-instance-type p2.xlarge \
--amazonec2-ami ami-2c57433b \
--amazonec2-device-name "/dev/sda1" \
--amazonec2-root-size "60" \
--amazonec2-volume-type "gp2" \
--amazonec2-region us-east-1 \
--amazonec2-zone c \
--amazonec2-retries 50 \
--amazonec2-security-group jupyter \
--amazonec2-vpc-id $AWS_VPC_ID \
--amazonec2-access-key $AWS_ACCESS_KEY_ID \
--amazonec2-secret-key $AWS_SECRET_ACCESS_KEY \
awsgpusd

# the create usually fails and docker doesn't load correctly
docker-machine stop awsgpusd
docker-machine start awsgpusd
docker-machine regenerate-certs awsgpusd

# check on instance
docker-machine ip awsgpusd
docker-machine inspect awsgpusd

# SSH into the machine
docker-machine ssh awsgpusd

# Install official NVIDIA driver package
sudo apt-key adv --fetch-keys http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/7fa2af80.pub
sudo sh -c 'echo "deb http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64 /" > /etc/apt/sources.list.d/cuda.list'
sudo apt-get update && sudo apt-get install -y --no-install-recommends cuda-drivers

# bc the daemon doesn't start
sudo nohup docker daemon -H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock &

# Install nvidia-docker and nvidia-docker-plugin
wget -P /tmp https://github.com/NVIDIA/nvidia-docker/releases/download/v1.0.1/nvidia-docker_1.0.1-1_amd64.deb
sudo dpkg -i /tmp/nvidia-docker*.deb && rm /tmp/nvidia-docker*.deb
sudo nvidia-docker run --rm nvidia/cuda nvidia-smi

# set env
eval `docker-machine env awsgpusd`
setenv NV_HOST "ssh://ubuntu@`docker-machine ip awsgpusd`:"
ssh-add ~/.docker/machine/machines/awsgpusd/id_rsa

# load local data
docker-machine scp -r . awsgpusd:

# build image
docker build -t kcavagnolo/docker_udsd:latest -f Dockerfile .

# push to repo
docker login
docker push kcavagnolo/docker_udsd:latest

# setup notebook
nvidia-docker run \
  -it --rm \
  -p 8888:8888 \
  -v /home/ubuntu:/notebooks \
  -w /notebooks \
  -e PASSWORD='abc123' \
  kcavagnolo/docker_udsd

# clean-up
docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)

# close and kill instance
docker rmi $(docker images -a -q)
docker-machine stop awsgpusd
docker-machine rm -f awsgpusd

#### nvidia docker on AWS ####
# problem is launching from osx with nvidia-docker which cannot run on osx
https://github.com/NVIDIA/nvidia-docker/wiki/Deploy-on-Amazon-EC2
https://github.com/NVIDIA/nvidia-docker/issues/171

# works from osx command line
docker run --device=/dev/nvidiactl --device=/dev/nvidia-uvm --device=/dev/nvidia0 -it --rm -p 8888:8888 -v /home/ubuntu:/notebooks -w /notebooks -e PASSWORD='abc123' kcavagnolo/docker_udsd

# maybe all-in-one solution?
sudo xhost +
sudo nvidia-docker run --env="DISPLAY" --volume="$HOME/.Xauthority:/root/.Xauthority:rw" -env="QT_X11_NO_MITSHM=1" -v /dev/video0:/dev/video0 -v /tmp/.X11-unix:/tmp/.X11-unix:ro -it -p 8888:8888 -p 6006:6006 -v ~/sharefolder:/sharefolder gtarobotics/udacity-sdc bash
