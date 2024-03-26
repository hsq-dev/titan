#!/bin/bash
# ��ʼ������

type=""
code=""
nfsurl=""
folder=""
already_install_NFS=2
containers=4 # Ĭ����������Ϊ4
storage=2048 # �����������ƴ�С
meson_gaga_code=""
meson_cdn_code=""

# titan������������
DAEMON_CRON_SCRIPT_PATH="/usr/local/bin/check_titan_daemon.sh"
TITAN_EDGE_BIN_URL="https://zeenyun-temp.oss-cn-shanghai.aliyuncs.com/titan_v0.1.13.tar.gz"

# weason_gaga������������
MESON_GAGA_BIN_URL="https://assets.coreservice.io/public/package/60/app-market-gaga-pro/1.0.4/app-market-gaga-pro-1_0_4.tar.gz"
MESON_CDN_BIN_URL="https://staticassets.meson.network/public/meson_cdn/v3.1.20/meson_cdn-linux-amd64.tar.gz"
show_help() {
    cat << EOF

################################### ������Ϣ ###################################

Usage: ${0##*/} [OPTIONS]

OPTIONS:
    --type TYPE              ��װģʽ��1 �����5������ģʽ��2 ��������+4������ģʽ��
    --code CODE              Titan-Edge ���루�����
    --nfsurl NFSURL          NFS URL�����ڹ��أ���ѡ���
    --already_install_NFS    �Ƿ��Ѿ���װNFS��1:�ǣ�2����
    --containers CONTAINERS  ��Ҫ���������������Ĭ��Ϊ 4��
    --storage STORAGE        ��Ҫ����Ĵ洢�ռ��С��
    --meson_gaga_code        ��Ҫ��װ��mesonGagaCode(����д����װ)       
    --meson_cdn_code         ��Ҫ��װ��weasonCdnCode(����д����װ)                           
    -h / --help              ��ʾ�˰�����Ϣ���˳���

ע��:
    - NFS��Ҫ�洢�ռ�����Ϊ2T��Ŀǰ��֪���ٷ�֧�����Ķ��٣���
    - NFS��ǰ����Ŀ¼Ϊ��/mnt/titan��

��Դ����:
    - ΢�ţ�checkHeart666
    - ����⣨��ӭ���ޣ��� https://github.com/qingjiuzys/titan-start
    - titanע�����ӣ�https://test1.titannet.io/intiveRegister?code=wLFnFN
    - mesonע�����ӣ�https://dashboard.gaganode.com/register?referral_code=qpkofealpfaomjb
    - titan������https://titannet.io/
    - titan�洢����https://storage.titannet.io/
    - titan���Խڵ����̨��https://test1.titannet.io/
    - titan�����ĵ���https://titannet.gitbook.io/titan-network-cn

################################################################################
EOF
}

# ���������в���
while [ "$#" -gt 0 ]; do
    case "$1" in
        --type=*) type="${1#*=}" ;;
        --code=*) code="${1#*=}" ;;
        --already_install_NFS=*) already_install_NFS="${1#*=}" ;;
        --nfsurl=*) nfsurl="${1#*=}"  ;; # ����ṩ��nfsurl��������������Ϊ5
        --containers=*) containers="${1#*=}" ;;
        --storage=*) storage="${1#*=}" ;;
        --meson_gaga_code=*) meson_gaga_code="${1#*=}" ;;
        --meson_cdn_code=*) meson_cdn_code="${1#*=}" ;;
        -h|--help) show_help; exit 0 ;;
        *) echo "δ֪����: $1" ; show_help; exit 1 ;;
    esac
    shift
done

###################################��������#################################

# ��鲢��װNFS�ͻ���
install_nfs_client() {
    echo "******************���NFS�ͻ�����******************"
    if ! command -v mount.nfs &> /dev/null; then
        echo "******************NFS�ͻ���δ��װ����ʼ��װ...******************"
        if [ -f /etc/lsb-release ]; then
            # ���ڻ���Debian��ϵͳ
            apt-get update && apt-get install -y nfs-common
        elif [ -f /etc/redhat-release ]; then
            # ���ڻ���RHEL��ϵͳ
            yum install -y nfs-utils
        else
         echo "******************��֧�ֵ�Linux���а�******************"
            exit 1
        fi
    else
        echo "******************NFS�ͻ����Ѱ�װ******************"
    fi
}

# ��鲢��װCron����
install_cron() {
   echo "******************���cron����������******************"
    if ! command -v crontab &> /dev/null; then
        echo "******************Cron����δ��װ����ʼ��װ******************"
        if [ -f /etc/lsb-release ]; then
            # ���ڻ���Debian��ϵͳ
            apt-get update -y && apt-get install -y cron
        elif [ -f /etc/redhat-release ]; then
            # ���ڻ���RHEL��ϵͳ
            yum install -y cronie
        else
            echo "******************��֧�ֵ�Linux���а�******************"
            exit 1
        fi
        systemctl enable cron
        systemctl start cron
        echo "******************Cron����װ���******************"
    else
        echo "******************Cron�����Ѱ�װ******************"
    fi
}

# ��̬������ע����Docker������Cron����
setup_cron_job() {
    local script_path="/usr/local/bin/check_titan.sh"
    # ������鲢����Docker�����Ľű�
    cat > $script_path << EOF
#!/bin/bash
container_count=$containers
for i in \$(seq 1 \$container_count); do
    container_name="titan-edge0\$i"
    if [ "\$(docker inspect -f '{{.State.Running}}' \$container_name 2>/dev/null)" != "true" ]; then
        echo "\$container_name is not running. Starting \$container_name..."
        docker start \$container_name
    fi
done
EOF
    # ����ű�ִ��Ȩ��
    chmod +x $script_path
    # ���Cron����ÿ5����ִ��һ��
    (crontab -l 2>/dev/null; echo "*/5 * * * * $script_path") | crontab -
}

setup_host_daemon_job() {
    local script_path = $DAEMON_CRON_SCRIPT_PATH

    # ������鲢����titan-edge�������̵Ľű�
    cat > $script_path << 'EOF'
#!/bin/bash

# ���titan-edge���������Ƿ���������
if pgrep -af "titan-edge daemon start" | grep -v "init" >/dev/null; then
    echo "titan-edge ����������������."
else
    echo "titan-edge ��������δ����. ��������..."
    nohup titan-edge daemon start > /var/log/edge.log 2>&1 &
fi
EOF
    # ����ű�ִ��Ȩ��
    chmod +x $script_path
    # ���Cron����ÿ5����ִ��һ��
    (crontab -l 2>/dev/null; echo "*/5 * * * * $script_path") | crontab -
}


# ����NFS
mount_nfs() {
    if [ -n "$nfsurl" ]; then
        echo "***************����NFS����$nfsurl �� /mnt/titan"
        mkdir -p /mnt/titan
        mount -t nfs -o vers=4,minorversion=0,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport "$nfsurl":/ /mnt/titan
        if [ $? -eq 0 ]; then
            echo "******************NFS�������******************"
            folder="/mnt/titan"
        else
            echo "******************NFS����ʧ��******************"
            exit 1
        fi
    fi
}
# ���ô洢�ռ�����
set_storage(){
    for i in $(seq 1 $containers)
    do
        echo "******************�����޸�����$titan-edge0$i�Ĵ洢����******************"
        sed -i "s/#StorageGB = 64/StorageGB = $storage/" "/${folder}/storage-$i/config.toml"
        echo "******************��������$titan-edge0$i��Ӧ���µĴ洢����******************"
        docker restart titan-edge0$i
    done
}


# �������16λ�ַ����ĺ���
generate_random_string() {
    cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1
}


# �����洢Ŀ¼
create_storage_directories() {
    echo "******************Docker�洢Ŀ¼������******************"
     mkdir -p "${folder}/data"
    for i in $(seq 1 $containers)
    do
        mkdir -p "${folder}/storage-${i}"
    done
    echo "******************Docker�洢Ŀ¼�������******************"
}

# ����������
run_containers() {
    echo "******************��������dockerʵ��******************"
    for i in $(seq 1 $containers)
    do
    #-v "${folder}/data:/root/.titanedge/storage/assets"
        docker run --name titan-edge0$i -d -v "${folder}/storage-$i:/root/.titanedge" nezha123/titan-edge
    done
    echo "******************����Dockerʵ���������******************"
}

# ��װca-certificates�����豸
setup_and_bind() {
    for i in $(seq 1 $containers)
    do
      # echo "******************���ڸ�dockerʵ������CA֤��******************"
      # docker exec -i titan-edge0$i bash -c "apt-get update && apt-get install -y ca-certificates"
      # echo "******************dockerʵ��$titan-edge0$i����CA֤�����******************"
      # sleep 2
       echo "******************���ڰ󶨸��������******************"
        docker exec -i titan-edge0$i bash -c "titan-edge bind --hash=$code https://api-test1.container1.titannet.io/api/v2/device/binding"
        echo "******************�������������******************"
    done
        echo "******************��װ����ɣ����Ժ��¼����̨�鿴�ڵ�******************"
}

# ����Ƿ�ʹ��NFS 
check_use_nfs(){
    # ����nfsurl�������û���Ŀ¼
    if [ -n "$nfsurl" ] || [ "$already_install_NFS" -eq 1 ]; then
        random_str=$(generate_random_string)
        folder="/mnt/titan/$random_str"
        install_nfs_client
        mount_nfs
    else
        folder="/mnt"
    fi
}


# ������װ����
titan_host_install(){
    wget -c $TITAN_EDGE_BIN_URL -O - | sudo tar -xz -C /usr/local/bin --strip-components=1 
    nohup titan-edge daemon start --init --url https://test-locator.titannet.io:5000/rpc/v0 > edge.log 2>&1 &
    sleep 10 
    # ����titan-edge daemon���̵�PID
    pid=$(ps aux | grep "titan-edge daemon start" | grep -v grep | awk '{print $2}')
    # ����ҵ���PID������ɱ������
    if [ ! -z "$pid" ]; then
           echo "ɱ������IDΪ $pid �Ľ���."
           kill $pid
            # �������Ƿ�ɱ�������û�У�ʹ��kill -9
           if kill -0 $pid > /dev/null 2>&1; then
               echo "���� $pid û����Ӧ����ʹ��kill -9."
               kill -9 $pid
           fi
    else
            echo "û���ҵ� titan-edge daemon ����."
        fi
    nohup titan-edge daemon start --init> edge.log 2>&1 &
    echo "................��30����а���"
    sleep 30 
    titan-edge bind --hash=$code  https://api-test1.container1.titannet.io/api/v2/device/binding 
    echo "**********************���������******************8"
    setup_host_daemon_job
}

#��麯��
check_install(){
    # ����Ƿ�Ϊroot�û�
    if [ "$(id -u)" != "0" ]; then
       echo "�ýű���Ҫ��rootȨ������" 1>&2
       exit 1
    fi
    local running_containers
    running_containers=$(docker ps -q | wc -l) # ��ȡ��ǰ���е���������
    if [ "$running_containers" -gt 2 ]; then
        echo "��ǰ���е�Docker��������Ϊ $running_containers������2���Ѿ��˳�..."
        exit 1
    else
        echo "��ǰ���е�Docker��������Ϊ $running_containers��ִ�а�װ����"
        main_install
    fi    
}
install_docker(){
     if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
            "debian"|"ubuntu")
                echo "******************��Debian/Ubuntu�ϰ�װDocker******************"
                sudo apt-get update
                sudo apt-get install -y docker
                ;;
            "centos"|"rhel"|"fedora"|"opencloudos")
                echo "******************��CentOS/RHEL/Fedora/OpenCloudOS�ϰ�װDocker******************"
                sudo yum install -y docker
                ;;
            *)
                echo "******************��֧�ֵ�Linux���а�: $ID******************"
                exit  1
                ;;
        esac
    else
        echo "�޷�ȷ������ϵͳ����"
        exit  1
    fi
    # ���Docker�Ƿ�װ�ɹ�
    if command -v docker &> /dev/null; then
        echo "******************Docker��װ�ɹ�******************"
    else
        echo "******************Docker��װʧ��******************"
        exit  1
    fi
}

# ��ʼ��docker
init_docker(){
        # ��װ����
        echo "******************����ϵͳ����װ��Ҫ������******************"
        if [ -f /etc/lsb-release ]; then
            # ���ڻ���Debian��ϵͳ
            apt-get update && apt-get install -y \
            apt-transport-https \
            ca-certificates \
            curl \
            software-properties-common
        elif [ -f /etc/redhat-release ]; then
            # ���ڻ���RHEL��ϵͳ
            yum update -y && yum install -y \
            yum-utils \
            device-mapper-persistent-data \
            lvm2
        else
            echo "*****************��һ��֧�ֵ���ǿ�ư�װDocker*****************" 
        fi
        # ��װDocker
        echo "******************���ڰ�װDocker...******************"
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        if [ $? -eq 0 ]; then
            echo "******************Docker��װ�ɹ�******************"
        else
            echo "******************Docker��װʧ�ܣ�����������ʽ��װdocker��******************" 1>&2
            install_docker
        fi
    # ������ʹDocker��������
    systemctl start docker
    systemctl enable docker
    # ��ȡָ����Docker����
    docker pull docker.io/nezha123/titan-edge
    echo "******************Docker��װ�ű�ִ�����******************"
}

#��װ����
main_install(){
    init_docker
    check_use_nfs
    case $type in
        1)
            echo "******************��ѡ���˰�װ5������***********************"
            containers=5 
            sleep 2
            ;;
       2)
            echo "******************��ѡ����������װ+4������*******************"
            sleep 2
            echo ""
            echo "******************����׼����װ��������************************"
            titan_host_install
            echo "******************������װ���*****************************"
            ;;

        *)
            echo "******************��Ĭ�ϰ�װ5������***********************"
            containers=5 
            sleep 2
            ;;
    esac
echo "******************��������dockerӳ��Ŀ¼��******************"
create_storage_directories
echo "******************��������dockerӳ��Ŀ¼���******************"
sleep 5
echo "******************����׼����������******************"
run_containers
echo "******************�����������******************"
sleep 20
echo "******************���������洢���ƴ�С******************"
set_storage
echo "******************�����������ƴ洢��С���******************"
sleep 5
echo "******************������ݰ���******************"
setup_and_bind
echo "******************������ݰ����******************"
sleep 10
echo "******************����׼�����������ػ�����******************"
setup_cron_job
echo "******************�����ػ������������******************"
sleep 5
echo "******************����titan����װ���******************"
}


#��鰲װmeson_gaga
check_meson_gaga_install(){
    if [ -n "$meson_gaga_code" ]; then
        echo "******************���ڰ�װmeson->gaga******************"
        curl -o apphub-linux-amd64.tar.gz $MESON_GAGA_BIN_URL && tar -zxf apphub-linux-amd64.tar.gz && rm -f apphub-linux-amd64.tar.gz
        sudo ./apphub-linux-amd64/apphub service remove && sudo ./apphub-linux-amd64/apphub service install
        sleep 20
        sudo ./apphub-linux-amd64/apphub service start
        sleep 30 
        ./apphub-linux-amd64/apphub status
        sleep 20
        sudo ./apphub-linux-amd64/apps/gaganode/gaganode config set --token=$meson_gaga_code
        ./apphub-linux-amd64/apphub restart
        echo "******************meson->gaga��װ����******************"
       else
        echo "******************δѡ��װmeson_gaga_code******************"
    fi

}
#��鰲װmeson_cdn
check_meson_cdn_install(){
    if [ -n "$meson_cdn_code" ]; then
        echo "******************���ڰ�װmeson->cdn******************"
        wget  $MESON_CDN_BIN_URL -O meson_cdn-linux-amd64.tar.gz -O meson_cdn-linux-amd64.tar.gz&& tar -zxf meson_cdn-linux-amd64.tar.gz && rm -f meson_cdn-linux-amd64.tar.gz && cd ./meson_cdn-linux-amd64 && sudo ./service install meson_cdn
        sleep 20
        sudo ./meson_cdn config set --token=$meson_cdn_code --https_port=443 --cache.size=30        ./apphub status
        sleep 20
        sudo ./service start meson_cdn
        echo "******************meson->CDN��װ����******************"
       else
        echo "******************δѡ��װmeson_cdn******************"
    fi

}

###################################�����������#################################
check_install
echo "******************��鰲װmeson->gaga��******************"
check_meson_gaga_install
echo "******************���а�װ�������********************"

echo "******************��鰲װmeson->cdn��******************"
check_meson_cdn_install
echo "******************���а�װ�������********************"
