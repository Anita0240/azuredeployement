# 1. Resource Group
resource "azurerm_resource_group" "ai_rg" {
  name     = "ai-deployment-rg"
  location = "Central India"
}

# 2. Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "ai-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.ai_rg.location
  resource_group_name = azurerm_resource_group.ai_rg.name
}

# 3. Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.ai_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}


resource "azurerm_public_ip" "pip" {
  name                = "ai-vm-ip"
  location            = azurerm_resource_group.ai_rg.location
  resource_group_name = azurerm_resource_group.ai_rg.name
  allocation_method   = "Static" # Static taaki IP baar baar change na ho
}

# 5. Network Security Group (Firewall)
resource "azurerm_network_security_group" "nsg" {
  name                = "ai-vm-nsg"
  location            = azurerm_resource_group.ai_rg.location
  resource_group_name = azurerm_resource_group.ai_rg.name

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
}

# 6. Ubuntu Virtual Machine
resource "azurerm_linux_virtual_machine" "ai_vm" {
  name                = "ai-server"
  resource_group_name = azurerm_resource_group.ai_rg.name
  location            = azurerm_resource_group.ai_rg.location
  size                = "Standard_B1s" # Sasta aur chota VM (Testing ke liye best)
  admin_username      = "azureuser"
  network_interface_ids = [azurerm_network_interface.nic.id]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub") 
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

# (NIC definition yahan missing hai, but aapko nic resource bhi add karni hogi)
resource "azurerm_network_interface" "nic" {
  name                = "ai-nic"
  location            = azurerm_resource_group.ai_rg.location
  resource_group_name = azurerm_resource_group.ai_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}