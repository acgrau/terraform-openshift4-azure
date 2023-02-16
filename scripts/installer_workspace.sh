#!/bin/bash
# if  [[ "${PROXY_EVAL}" == "true" ]]; then 
#     export no_proxy=mirror.openshift.com;
# fi

set -e

function install_openshift_installer() {
  if [[ ! -f ${INSTALLER_WORKSPACE}openshift-install ]]; then
    case $(uname -s) in
      Darwin)
        wget -r -l1 -np -nd -q '${OPENSHIFT_INSTALLER_URL}/${OPENSHIFT_VERSION}/' -P ${INSTALLER_WORKSPACE} -A 'openshift-install-mac-4*.tar.gz'
        tar zxvf ${INSTALLER_WORKSPACE}/openshift-install-mac-4*.tar.gz -C ${INSTALLER_WORKSPACE}
        ;;
      Linux)
        curl -SL  ${OPENSHIFT_INSTALLER_URL}/${OPENSHIFT_VERSION}/openshift-install-linux-${OPENSHIFT_VERSION}.tar.gz -o ${INSTALLER_WORKSPACE}openshift-install-linux-${OPENSHIFT_VERSION}.tar.gz 
        tar zxvf ${INSTALLER_WORKSPACE}openshift-install-linux-4*.tar.gz -C ${INSTALLER_WORKSPACE}
        ;;
      *)
        exit 1;;
    esac
    chmod u+x ${INSTALLER_WORKSPACE}openshift-install
    rm -f ${INSTALLER_WORKSPACE}*.tar.gz ${INSTALLER_WORKSPACE}README.md
  fi
}

function install_openshift_client() {
  if [[ ! -f ${INSTALLER_WORKSPACE}oc ]]; then
    case $(uname -s) in
      Darwin)
        wget -r -l1 -np -nd -q '${OPENSHIFT_INSTALLER_URL}/${OPENSHIFT_VERSION}/' -P ${INSTALLER_WORKSPACE} -A 'openshift-client-mac-4*.tar.gz'
        tar zxvf ${INSTALLER_WORKSPACE}/openshift-client-mac-4*.tar.gz -C ${INSTALLER_WORKSPACE}
        ;;
      Linux)
        curl -SL ${OPENSHIFT_INSTALLER_URL}/${OPENSHIFT_VERSION}/openshift-client-linux-${OPENSHIFT_VERSION}.tar.gz -o ${INSTALLER_WORKSPACE}openshift-client-linux-${OPENSHIFT_VERSION}.tar.gz
        tar zxvf ${INSTALLER_WORKSPACE}openshift-client-linux-4*.tar.gz -C ${INSTALLER_WORKSPACE}
        ;;
      *)
        exit 1;;
    esac
    chmod u+x ${INSTALLER_WORKSPACE}oc
    chmod u+x ${INSTALLER_WORKSPACE}kubectl
    rm -f ${INSTALLER_WORKSPACE}*.tar.gz ${INSTALLER_WORKSPACE}README.md
  fi
}

function install_jq() {
  if [[ ! -f ${INSTALLER_WORKSPACE}jq ]]; then
    case $(uname -s) in
      Darwin)
        curl -sSL https://github.com/stedolan/jq/releases/download/jq-1.6/jq-osx-amd64 -o ${INSTALLER_WORKSPACE}jq
        ;;
      Linux)
        curl -sSL https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 -o ${INSTALLER_WORKSPACE}jq
        ;;
      *)
        exit 1;;
    esac
    chmod u+x ${INSTALLER_WORKSPACE}jq
  fi
}

function install_azcopy() {
  if [[ ! -f ${INSTALLER_WORKSPACE}azcopy ]]; then
    case $(uname -s) in
      Darwin)
        curl -L https://aka.ms/downloadazcopy-v10-mac  -o ${INSTALLER_WORKSPACE}/downloadazcopy-v10-mac.zip
        unzip -j -d ${INSTALLER_WORKSPACE} ${INSTALLER_WORKSPACE}/downloadazcopy-v10-mac.zip */azcopy
        rm -f ${INSTALLER_WORKSPACE}/downloadazcopy-v10-mac.zip
        ;;
      Linux)
        curl -L https://aka.ms/downloadazcopy-v10-linux -o ${INSTALLER_WORKSPACE}/downloadazcopy-v10-linux
        tar zxvf ${INSTALLER_WORKSPACE}downloadazcopy-v10-linux -C ${INSTALLER_WORKSPACE} --wildcards *azcopy --strip-components 1
        rm -f ${INSTALLER_WORKSPACE}downloadazcopy-v10-linux      
        ;;
      *)
        exit 1;;
    esac
    chmod u+x ${INSTALLER_WORKSPACE}azcopy
  fi
}

test -e ${INSTALLER_WORKSPACE} || mkdir -p ${INSTALLER_WORKSPACE}

install_openshift_installer
if [[ $? -ne 0 ]]; then exit 1; fi

install_openshift_client
if [[ $? -ne 0 ]]; then exit 1; fi

install_jq
if [[ $? -ne 0 ]]; then exit 1; fi

install_azcopy
if [[ $? -ne 0 ]]; then exit 1; fi

exit 0