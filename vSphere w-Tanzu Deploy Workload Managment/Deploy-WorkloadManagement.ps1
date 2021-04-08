#Connect to vCenter. Edit values as appropriate.
$vc = "192.168.111.109"
$vc_user = "administrator@vsphere.local"
$vc_password = "VMware1!"
Connect-VIServer -User $vc_user -Password $vc_password -Server $vc
$Cluster = Get-Cluster  -Name "cluster"
$datacenter = Get-Datacenter "datacenter"
$datastore = Get-Datastore -Name  "vsanDatastore"
$vmhosts = Get-VMHost
$tkgcl = "tkg-cl"
$ntpservers = @("time.vmware.com")
$ManagementVirtualNetwork = get-virtualnetwork "VM Network"
#
$HAProxyVMname = "haproxy-demo"
$AdvancedSettingName = "guestinfo.dataplaneapi.cacert"
$Base64cert = get-vm $HAProxyVMname |Get-AdvancedSetting -Name $AdvancedSettingName
while ([string]::IsNullOrEmpty($Base64cert.Value)) {
            Write-Host "Waiting for CA Cert Generation... This may take a under 5-10 minutes as the VM needs to boot and generate the CA Cert (if you haven't provided one already)."
        $Base64cert = get-vm $HAProxyVMname |Get-AdvancedSetting -Name $AdvancedSettingName
        Start-sleep -seconds 2
    }
    Write-Host "CA Cert Found... Converting from BASE64"
    $cert = [Text.Encoding]::Utf8.GetString([Convert]::FromBase64String($Base64cert.Value))
#
Write-Host "Enabling Workload Management"
Get-Cluster $Cluster | Enable-WMCluster `
       -SizeHint Tiny `
       -ManagementVirtualNetwork $ManagementVirtualNetwork `
       -ManagementNetworkMode StaticRange `
       -ManagementNetworkGateway "192.168.111.1" `
       -ManagementNetworkSubnetMask "255.255.255.0" `
       -ManagementNetworkStartIPAddress "192.168.111.201" `
       -ManagementNetworkAddressRangeSize 5 `
       -MasterDnsServerIPAddress @("192.168.111.1") `
       -MasterNtpServer @("time.vmware.com") `
       -ServiceCIDR "10.96.0.0/24" `
       -EphemeralStoragePolicy "kubernetes-demo-storage" `
       -ImageStoragePolicy "kubernetes-demo-storage" `
       -MasterStoragePolicy "kubernetes-demo-storage" `
       -ContentLibrary $tkgcl `
       -HAProxyName $HAProxyVMname `
       -HAProxyAddressRanges "192.168.24.208-192.168.24.222" `
       -HAProxyUsername "admin" `
       -HAProxyPassword "vmware" `
       -HAProxyDataPlaneAddresses "192.168.111.200:5556" `
       -HAProxyServerCertificateChain $cert `
       -WorkerDnsServer "192.168.111.1" `
       -PrimaryWorkloadNetworkSpecification ( New-WMNamespaceNetworkSpec `
          -Name "network-1" `
          -Gateway "192.168.24.1" `
          -Subnet "255.255.255.0" `
          -AddressRanges "192.168.24.2-192.168.24.126" `
          -DistributedPortGroup "Workload24" `
       )
