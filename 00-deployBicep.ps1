#kicks off the bicep deployment of 2 EntraID only joined session hosts with HP, App group and, Workspace into an existing VNET.

$SubscriptionId = 'a2.......6f'           # your Azure subscription ID
$tenantId = '47f......aab0'               # your Azure Entra ID tenant ID
$resourceGroup = "rg-myAVD"               # please change me!
$locationHostPool = "westeurope"
$vnetName = "vnet-1"                      #Change to a vnet that exists in your azure subscription
$subnetHostPool = "subnet-1"              #Change to a subnet in vnet-1 that exists in your azure subscription
$administratorAccountPassword = "....."     # please change me!
$administratorAccountUsername = "avdadmin"  # please change me!
$hostpoolName = "hp-1"                      # please change me!


az login --use-device-code --tenant $tenantId
az account set --subscription $SubscriptionId  
az group create --name $resourceGroup --location $locationHostPool

$principalID = $(az ad group show --group 'AVD Users' --query objectId --out tsv)   #Change to a that exists in your Azure AD

if ($null -eq $principalID) {
  Write-Host "You need to create a group called 'AVD Users' in the Azure AD and assign the users to it. Then run this script again." -ForegroundColor red
  break
}

$subnetID = $(az network vnet subnet list --resource-group $resourceGroup --vnet-name $vnetName --query "[?name=='$($subnetHostPool)'].id" --out tsv)
if ($null -eq $subnetID) {
  Write-Host "You need to create a subnet called 'subnet-1' in the vnet called 'vnet-1'. Then run this script again." -ForegroundColor red
  break
}

az deployment group create  `
  --name $("avd_" + ([datetime]::Now).ToString('dd-MM-yy_HH_mm')) `
  --template-file "$((Get-Location).Path)\00-avdcomplete.bicep" `
  --resource-group $resourceGroup `
  --parameters location=$locationHostPool `
  administratorAccountPassword=$administratorAccountPassword  `
  administratorAccountUsername=$administratorAccountUsername `
  subnet_id=$subnetID `
  hostpoolName=$hostpoolName `
  hostPoolRG=$resourceGroup `
  principalID=$principalID `
  workspaceName="$hostpoolName-WS" `
  workspaceFriendlyName="Cloud Workspace hosting $hostpoolName" `
  currentDate=$(([datetime]::Now).ToString('dd-MM_HH_mm')) tagValues=$('{\"CreatedBy\": \"bfrank\",\"deploymentDate\": \"'+ $(([datetime]::Now).ToString('dd-MM-yyyy_HH_mm')) + '\",\"Service\": \"AVD\",\"Environment\": \"PoC\"}')


#az bicep build --file "$((Get-Location).Path)\avdcomplete.bicep" --outfile "$((Get-Location).Path)\build.json"

#$username=$(az account show --query user.name --output tsv)
#$vm=$(az vm show --resource-group $resourceGroup --name hostpool-1-vm0 --query id -o tsv)
#az role assignment create --role "Virtual Machine Administrator Login" --assignee $username --scope $vm


