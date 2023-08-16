terraform {
required_providers {
  azurerm = {
    source  = "hashicorp/azurerm"
    version = "3.69.0"
  }
}
}

provider "azurerm" {
  subscription_id = "d34bfa3c-395b-4a99-b78b-c1eb567f194e"
  client_id       = "f260542f-a9d1-4fa8-9576-0e41120870b0"
  tenant_id       = "9c8afe4e-d0ec-4897-9177-18276771306d"
  client_secret   = "wat8Q~rnYwl0NuMaYX3TMU2TVRwEAWDIKBkesbD0" 
  features {
    
  } 
  
}
resource "azurerm_resource_group" "suppi" {
  name     = "suppi"
  location = "EAST US"
  }


resource "azurerm_virtual_network" "qnet" {
    name                = "qnet"
    location            = "EAST US"
    resource_group_name = "suppi"
    address_space       = ["192.168.0.0/16"]
    depends_on = [ azurerm_resource_group.suppi ]

}

resource "azurerm_subnet" "subnet2" {
    name                 = "subnet2"
    resource_group_name  = "suppi"
    virtual_network_name = "vnet"
    address_prefixes     = ["192.168.255.224/27"]
    depends_on = [ azurerm_virtual_network.qnet ]
}

resource "azurerm_public_ip" "custom-public-ip" {
    count               = 2
    name                = "custom-public-ip${count.index}"
    location            = "EAST US"
    resource_group_name = "suppi"
    allocation_method   = "Dynamic"
    depends_on = [ azurerm_resource_group.suppi ]

}

resource "azurerm_network_interface" "custom-network-interface" {
    count                = 2
    name                 = "custom-network-interface${count.index}"
    location             = "EAST US"
    resource_group_name  = "suppi"
    enable_ip_forwarding = true

    ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet2.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.custom-public-ip[count.index].id
    }
    depends_on = [ azurerm_virtual_network.qnet ]
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "custom-security-group" {
    name                = "custom-security-group"
    location            = "EAST US"
    resource_group_name = "suppi"

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "HTTP"
        priority                   = 999
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "8080"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
    depends_on = [ azurerm_subnet.subnet2 ]

}

resource "azurerm_subnet_network_security_group_association" "mgit-association" {
    subnet_id                 = azurerm_subnet.subnet2.id
    network_security_group_id = azurerm_network_security_group.custom-security-group.id
    depends_on = [ azurerm_network_security_group.custom-security-group ]
}

resource "azurerm_virtual_machine" "suppi-vm" {
    count                 = 2
    name                  = "suppi-vm${count.index}"
    location              = "EAST US"
    resource_group_name   = "suppi"
    network_interface_ids = [element(azurerm_network_interface.custom-network-interface.*.id, count.index)]
    vm_size               = "Standard_B2s"
    delete_os_disk_on_termination = true


    storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

    storage_os_disk {
    name              = "myosdisk${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
    }

    os_profile {
    computer_name  = "suppi"
    admin_username = "azureuser"
    admin_password = "Supraja1398"
    }

    os_profile_linux_config {
    disable_password_authentication = false
    }

}


