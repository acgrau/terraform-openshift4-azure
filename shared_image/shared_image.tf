locals {
  installer_workspace     = "${path.root}/installer-files/"
  openshift_installer_url = "${var.openshift_installer_url}/${var.openshift_version}/"
  major_version           = join(".", slice(split(".", var.openshift_version), 0, 2))
  ocp_v4_10_plus          = substr(local.major_version, 2, 2) >= 10 ? true : false
  rhcos_image             = local.ocp_v4_10_plus ?  data.external.vhd_location[0].result["VHD_URL"] : lookup(lookup(jsondecode(data.http.images[0].body), "azure"), "url")
}

data "http" "images" {
  count = local.ocp_v4_10_plus ? 0 : 1
  url = "https://raw.githubusercontent.com/openshift/installer/release-${local.major_version}/data/data/rhcos.json"
  request_headers = {
    Accept = "application/json"
  }
}

resource "null_resource" "env_setup" {
  count = local.ocp_v4_10_plus ? 1 : 0

  provisioner "local-exec" {
    command = "${path.module}/scripts/env_setup.sh"
    interpreter = ["/bin/bash"]
    environment = {
      INSTALLER_WORKSPACE = local.installer_workspace
      OPENSHIFT_INSTALLER_URL = local.openshift_installer_url
      OPENSHIFT_VERSION = var.openshift_version
    }
  }
}

data "external" "vhd_location" {
  count = local.ocp_v4_10_plus ? 1 : 0
  program = ["bash", "${path.module}/scripts/get_vhd_path.sh"]

  query = {
    installer_workspace = var.installer_workspace
  }

  depends_on = [
    null_resource.env_setup
  ]
}

resource "null_resource" "disk_create" {
  triggers = {
    installer_workspace   = var.installer_workspace
    subscription_id       = var.subscription_id
    tenant_id             = var.tenant_id
    client_id             = var.client_id
    client_secret         = var.client_secret
    resource_group_name   = var.cluster_resource_group_name
    openshift_version     = var.openshift_version
    bash_debug            = var.bash_debug
    cluster_unique_string = var.cluster_unique_string
    proxy_eval            = var.proxy_eval
  }

  provisioner "local-exec" {
    when = create
    command = "${path.module}/scripts/disk_create.sh"
    interpreter = ["/bin/bash"]
    environment = {
      INSTALLER_WORKSPACE = self.triggers.installer_workspace
      SUBSCRIPTION_ID     = self.triggers.subscription_id
      TENANT_ID           = self.triggers.tenant_id
      CLIENT_ID           = self.triggers.client_id
      CLIENT_SECRET       = self.triggers.client_secret
      RESOURCE_GROUP_NAME = self.triggers.resource_group_name
      OPENSHIFT_VERSION   = self.triggers.openshift_version
      REGION              = var.region
      RHCOS_IMAGE_URL     = local.rhcos_image
      BASH_DEBUG          = self.triggers.bash_debug
      CLUSTER_ID          = self.triggers.cluster_unique_string
      PROXY_EVAL          = self.triggers.proxy_eval
    }
  }

  provisioner "local-exec" {
    when    = destroy
    command = "${path.module}/scripts/disk_delete.sh"
    interpreter = ["/bin/bash"]
    environment = {
      INSTALLER_WORKSPACE = self.triggers.installer_workspace
      SUBSCRIPTION_ID     = self.triggers.subscription_id
      TENANT_ID           = self.triggers.tenant_id
      CLIENT_ID           = self.triggers.client_id
      CLIENT_SECRET       = self.triggers.client_secret
      RESOURCE_GROUP_NAME = self.triggers.resource_group_name
      OPENSHIFT_VERSION   = self.triggers.openshift_version
      BASH_DEBUG          = self.triggers.bash_debug
      CLUSTER_ID          = self.triggers.cluster_unique_string      
    }
  }
}

data "azurerm_managed_disk" "rhcos_disk" {
  name                = "coreos-${var.openshift_version}-${var.cluster_unique_string}-vhd"
  resource_group_name = var.cluster_resource_group_name
  depends_on = [
    null_resource.disk_create
  ]  
}

resource "azurerm_image" "cluster" {
  name                = "${var.cluster_name}-${var.cluster_unique_string}"
  resource_group_name = var.cluster_resource_group_name
  location            = var.region

  os_disk {
    os_type  = "Linux"
    os_state = "Generalized"
    managed_disk_id = data.azurerm_managed_disk.rhcos_disk.id
  }

  depends_on = [
    data.azurerm_managed_disk.rhcos_disk
  ]  
}
