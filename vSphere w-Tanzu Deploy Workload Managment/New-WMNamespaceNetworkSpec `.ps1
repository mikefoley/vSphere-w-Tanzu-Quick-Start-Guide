$script = {New-WMNamespaceNetworkSpec `
          -Name "network-25" `
          -Gateway "192.168.25.1" `
          -Subnet "255.255.255.0" `
          -AddressRanges "192.168.25.2-192.168.25.126" `
          -DistributedPortGroup "Workload25"
}
