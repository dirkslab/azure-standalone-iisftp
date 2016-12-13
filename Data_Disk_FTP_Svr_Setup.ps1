<# Custom Script for Windows #>

# Prep Data Disks

$PoolCount = Get-PhysicalDisk -CanPool $True;
$DiskCount = $PoolCount.count;
$PhysicalDisks = Get-StorageSubSystem -FriendlyName "Storage Spaces*" | Get-PhysicalDisk -CanPool $True;
New-StoragePool -FriendlyName "DataPool" -StorageSubsystemFriendlyName "Storage Spaces*" -PhysicalDisks $PhysicalDisks |New-VirtualDisk -FriendlyName "Virtual Data Disk 01" -Interleave 65536 -NumberOfColumns $DiskCount -ResiliencySettingName simple –UseMaximumSize |Initialize-Disk -PartitionStyle GPT -PassThru |New-Partition -AssignDriveLetter -UseMaximumSize |Format-Volume -FileSystem NTFS -NewFileSystemLabel "Data Volume" -AllocationUnitSize 65536 -Confirm:$false;



# Setup FTP Server
$ftpsitename = "ftpmedia"
$PhysicalPath = "f:\ftproot"
$ftpusergroup = "ftpusergroup"
#$domainNameLabel = "pspftp" ##this would be the domainNameLabel used when setting up PublicIpAddress
$ftpsvradmin = "ftpadmin"
$UserPassword = "Thereshegoes@81" ##remember to change this password! Not sure if this is a good idea?
#$ip=[System.Net.Dns]::GetHostAddresses("$domainNameLabel.northeurope.cloudapp.azure.com")| Select-Object -ExpandProperty IPAddressToString

## Install webserver and web management tools
Install-WindowsFeature -Name Web-Server, Web-FTP-Server, Web-Mgmt-Tools -ErrorAction SilentlyContinue;


## NEEDED FOR IIS CMDLETS
Import-Module WebAdministration -ErrorAction SilentlyContinue;

## Create FTP Admin User
$Computer = $env:COMPUTERNAME;
$ADSI = [ADSI]("WinNT://$Computer");
$User = $ADSI.Create('User', "$ftpsvradmin");
$User.SetPassword($UserPassword);
$User.SetInfo();
$User.description = "ftp_Admin_User";
$User.SetInfo();

## Create FTP access Group
$Computer = $env:COMPUTERNAME;
$ADSI = [ADSI]("WinNT://$Computer");
$Group = $ADSI.Create('Group', "$ftpusergroup");
$Group.SetInfo();
$Group.description = "ftp_user_group";
$group.SetInfo()

##Create root directory if it does not exist
md $PhysicalPath -ErrorAction SilentlyContinue;
$acl = Get-ACL -Path $PhysicalPath;
$acl.SetAccessRuleProtection($True, $True);
Set-Acl -Path $PhysicalPath -AclObject $acl;
icacls "$PhysicalPath" "/grant" "IUSR:(OI)(CI)(R)" "/T";
icacls "$PhysicalPath" "/grant" "IUSR:(OI)(CI)(W)" "/T";
icacls "$PhysicalPath" "/grant" "$ftpusergroup`:(OI)(CI)(W)" "/T";
icacls "$PhysicalPath" "/grant" "$ftpusergroup`:(OI)(CI)(R)" "/T";
icacls "$PhysicalPath" "/remove:g" "Users" "/T";
##    CREATE FTP SITE AND SET C:\inetpub\ftproot AS HOME DIRECTORY
New-WebFtpSite -Name $ftpsitename -Force -PhysicalPath $PhysicalPath -Port 21;

## set authentication on FTP server
Set-ItemProperty "IIS:\Sites\$ftpsitename" -Name 'ftpServer.security.authentication.basicAuthentication.enabled' -Value $true;
Set-ItemProperty "IIS:\Sites\$ftpsitename" -Name 'ftpServer.security.authentication.anonymousAuthentication.enabled' -Value $false;

Set-ItemProperty "IIS:\Sites\$ftpsitename" -Name 'ftpServer.security.ssl.controlChannelPolicy' -Value 0;
Set-ItemProperty "IIS:\Sites\$ftpsitename" -Name 'ftpServer.security.ssl.dataChannelPolicy' -Value 0


## FTP Allow user and group access
Set-WebConfiguration "/system.ftpServer/security/authorization" -value @{accessType="Allow";users="$ftpsvradmin";roles="$ftpusergroup";permissions='Read, Write'} -PSPath "iis:\" -location "ftpmedia";

# FTP Passv and ports set
# Change the lower and upper dataChannel ports
    $firewallSupport = Get-WebConfiguration "system.ftpServer/firewallSupport";
    $firewallSupport.lowDataChannelPort = 60000;
    $firewallSupport.highDataChannelPort = 60025;
    $firewallSupport | Set-WebConfiguration "system.ftpServer/firewallSupport";

## configure inbound firewall rule for passive connections
New-NetFirewallRule -DisplayName "ftp_passive_ports" -Action Allow -Direction Inbound -InterfaceType Any -Service ftpsvc;
Set-NetFirewallSetting -EnableStatefulFtp false;

## restart IIS site
Restart-WebItem 'IIS:\sites\ftpmedia'