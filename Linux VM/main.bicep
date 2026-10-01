// Malá Linux VM jako sandbox pro učení.
// Public IP je volitelná (enablePublicIp) – dá se po skončení práce odebrat redeployem s false.

targetScope = 'resourceGroup'

@description('Region nasazení.')
param location string = resourceGroup().location

@description('Prefix pro názvy všech prostředků.')
param namePrefix string = 'sandbox'

@description('Velikost VM. B1s = 1 vCPU / 1 GB RAM, nejlevnější rozumná volba.')
param vmSize string = 'Standard_B1s'

@description('Uživatelské jméno admina.')
param adminUsername string = 'azureuser'

@description('Veřejný SSH klíč (obsah souboru ~/.ssh/id_ed25519.pub nebo id_rsa.pub).')
@secure()
param sshPublicKey string

@description('Vytvořit a připojit public IP? Pro odebrání redeployni s false.')
param enablePublicIp bool = true

@description('Zdrojová IP/CIDR, ze které je povolen SSH (např. 203.0.113.10/32). Nenechávej * .')
param sshSourceAddressPrefix string

@description('Čas automatického vypnutí VM (HHmm), prázdné = vypnuto.')
param autoShutdownTime string = '2200'

@description('Časová zóna pro auto-shutdown.')
param autoShutdownTimeZone string = 'Central Europe Standard Time'

@description('Velikost OS disku v GB.')
param osDiskSizeGB int = 30

var vmName = '${namePrefix}-vm'
var vnetName = '${namePrefix}-vnet'
var subnetName = 'default'
var nsgName = '${namePrefix}-nsg'
var pipName = '${namePrefix}-pip'
var nicName = '${namePrefix}-nic'

resource nsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-SSH'
        properties: {
          priority: 1000
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: sshSourceAddressPrefix
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.10.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.10.1.0/24'
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
  }
}

resource pip 'Microsoft.Network/publicIPAddresses@2024-05-01' = if (enablePublicIp) {
  name: pipName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: vnet.properties.subnets[0].id
          }
          publicIPAddress: enablePublicIp ? { id: pip.id } : null
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: sshPublicKey
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'ubuntu-24_04-lts'
        sku: 'server'
        version: 'latest'
      }
      osDisk: {
        name: '${vmName}-osdisk'
        createOption: 'FromImage'
        diskSizeGB: osDiskSizeGB
        deleteOption: 'Delete'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
          properties: {
            deleteOption: 'Delete'
          }
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true // managed storage – umožní Serial Console i bez public IP
      }
    }
  }
}

resource autoShutdown 'Microsoft.DevTestLab/schedules@2018-09-15' = if (!empty(autoShutdownTime)) {
  name: 'shutdown-computevm-${vmName}'
  location: location
  properties: {
    status: 'Enabled'
    taskType: 'ComputeVmShutdownTask'
    dailyRecurrence: {
      time: autoShutdownTime
    }
    timeZoneId: autoShutdownTimeZone
    targetResourceId: vm.id
  }
}

output vmName string = vm.name
output privateIp string = nic.properties.ipConfigurations[0].properties.privateIPAddress
output publicIp string = enablePublicIp ? pip!.properties.ipAddress : ''
output sshCommand string = enablePublicIp ? 'ssh ${adminUsername}@${pip!.properties.ipAddress}' : 'Public IP vypnuta – použij Serial Console.'
