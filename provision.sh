#!/bin/bash

VAULT_FILE=$WT_ANSIBLE_VAULT_FILE
MYSQL_ROOT_PASS=

function parse_yaml {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}


show_help() {
cat <<EOF
Usage: ${0##*/} [-fm MYSQL_ROOT_PASS] [-t|s ANSIBLE_TAGS] [-p ANSIBLE_VAULT_FILE] [ENVIRONMENT] 
      -f                    First run, use when provisioning new servers.
      -m MYSQL_ROOT_PASS    For first run you need to provide new mysql root password.
      -p ANSIBLE_VAULT_FILE Path to ansible vault password. This can also be provided with WT_ANSIBLE_VAULT_FILE environment variable.
      -t ANSIBLE_TAGS       Ansible tags to be provisioned.
      -s ANSIBLE_TAGS       Ansible tags to be skipped when provisioning.
         ENVIRONMENT        Environment to be provisioned.
EOF

}
self_update() {
  if command -v md5sum >/dev/null 2>&1; then
    MD5COMMAND="md5sum"
  else
    MD5COMMAND="md5 -r"
  fi

  SELF=$(basename $0)
  UPDATEURL="https://raw.githubusercontent.com/wunderkraut/WunderTools/$GITBRANCH/provision.sh"
  MD5SELF=$($MD5COMMAND $0 | awk '{print $1}')
  MD5LATEST=$(curl -s $UPDATEURL | $MD5COMMAND | awk '{print $1}')
  if [[ "$MD5SELF" != "$MD5LATEST" ]]; then
    read -p "There is update for this script available. Update now ([y]es / [n]o)?" -n 1 -r;
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      cd $ROOT
      curl -s -o $SELF $UPDATEURL
      echo "Update complete, please rerun any command you were running previously."
      echo "See CHANGELOG for more info."
      echo "Also remember to add updated script to git."
      exit
    fi
  fi
  # Clone and update virtual environment configurations
  if [ ! -d "$ROOT/ansible" ]; then
    git clone  -b $ansible_branch $ansible_remote $ROOT/ansible
    if [ -n "$ansible_revision" ]; then
      cd $ROOT/ansible
      git reset --hard $ansible_revision
      cd $ROOT
    fi
  else
    if [ -z "$ansible_revision" ]; then
      cd $ROOT/ansible
      git pull
      git checkout $ansible_branch
      cd $ROOT
    fi
  fi


}
pushd `dirname $0` > /dev/null
ROOT=`pwd -P`
popd > /dev/null
# Parse project config
PROJECTCONF=$ROOT/conf/project.yml
echo $PROJECTCONF
eval $(parse_yaml $PROJECTCONF)

if [ -z "$wundertools_branch" ]; then
  GITBRANCH="master"
else
  GITBRANCH=$wundertools_branch
fi


self_update

OPTIND=1
ANSIBLE_TAGS=""
EXTRA_OPTS=""

while getopts ":hfp:m:t:s:" opt; do
    case "$opt" in
    h)
        show_help
        exit 0
        ;;
    p)  VAULT_FILE=$OPTARG
        ;;
    f)  FIRST_RUN=1
        ;;
    m)  MYSQL_ROOT_PASS=$OPTARG
        ;;
    t)  ANSIBLE_TAGS=$OPTARG
        ;;
    s)  ANSIBLE_SKIP_TAGS=$OPTARG
        ;;
    *)  EXTRA_OPTS="$EXTRA_OPTS -$OPTARG"
    esac
done

shift "$((OPTIND-1))"
ENVIRONMENT=$1

if [ -z $ENVIRONMENT ]; then
  show_help
  exit 1
fi

if [ -z $VAULT_FILE ]; then
  echo "Vault password file missing."
  echo "You can provide the path to the file with -p option."
  echo "Alternatively you can set WT_ANSIBLE_VAULT_FILE environment variable."
  exit 1
fi

pushd `dirname $0` > /dev/null
ROOT=`pwd -P`
popd > /dev/null

PLAYBOOKPATH=$ROOT/conf/$ENVIRONMENT.yml
if [ "$ENVIRONMENT" == "vagrant" ]; then
  INVENTORY=$ROOT/.vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory
  VAGRANT_CREDENTIALS="--private-key=.vagrant/machines/default/virtualbox/private_key -u vagrant"
else
  INVENTORY=$ROOT/conf/server.inventory
fi
EXTRA_VARS=$ROOT/conf/variables.yml


if [ $FIRST_RUN ]; then
  if [ -z $MYSQL_ROOT_PASS ]; then
    echo "Mysql root password missing. You need to provide password using -m flag."
    exit 1
  else
    ansible-playbook $EXTRA_OPTS $PLAYBOOKPATH -c ssh -i $INVENTORY -e "@$EXTRA_VARS"  -e "change_db_root_password=True mariadb_root_password=$MYSQL_ROOT_PASS" --ask-pass --vault-password-file=$VAULT_FILE $ANSIBLE_TAGS
  fi
else
  if [ $ANSIBLE_TAGS ]; then
    ansible-playbook $EXTRA_OPTS $VAGRANT_CREDENTIALS $PLAYBOOKPATH -c ssh -i $INVENTORY -e "@$EXTRA_VARS" --vault-password-file=$VAULT_FILE --tags "$ANSIBLE_TAGS"
  elif [ $ANSIBLE_SKIP_TAGS ]; then
    ansible-playbook $EXTRA_OPTS $VAGRANT_CREDENTIALS $PLAYBOOKPATH -c ssh -i $INVENTORY -e "@$EXTRA_VARS" --vault-password-file=$VAULT_FILE --skip-tags "$ANSIBLE_SKIP_TAGS"
  else
   ansible-playbook $EXTRA_OPTS $VAGRANT_CREDENTIALS $PLAYBOOKPATH -c ssh -i $INVENTORY -e "@$EXTRA_VARS" --vault-password-file=$VAULT_FILE
  fi
fi
