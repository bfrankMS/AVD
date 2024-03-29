//creates a hostpool, 2 session hosts (entra id only joined), application group, role assignment, and workspace

param currentDate string = utcNow('dd-MM-yyyy_HH_mm')
param location string = resourceGroup().location

@secure()
param administratorAccountPassword string
param administratorAccountUsername string
//param domain string
//param ouPath string
param subnet_id string
param hostpoolName string = 'HP1'
param hostPoolRG string = resourceGroup().name

param principalID string
param workspaceName string = '${hostpoolName}-WS'
param workspaceFriendlyName string = 'Cloud Workspace for ${hostpoolName}'

param tagValues object = {
  CreatedBy: 'BICEPDeployment'
  deploymentDate: currentDate
  Environment: 'PoC'
  Service: 'AVD'
}

module hostpool 'bicepmodules/hostpool.bicep' = {
  name: 'hostpool${currentDate}'
  params: {
    tagValues: tagValues
    location: location
    hostpoolName: hostpoolName
  }
}

module hostpoolvms 'bicepmodules/hostpoolgalleryvm.bicep' = {
  name: 'hostpoolgalleryvm${currentDate}'
  dependsOn: [
    hostpool
  ]
  params:{
    tagValues: tagValues
    location: location
    administratorAccountPassword: administratorAccountPassword
    administratorAccountUsername: administratorAccountUsername
    //domain: domain
    hostpoolName: hostpoolName
    hostpoolToken: hostpool.outputs.registrationInfoToken
    //ouPath: ouPath
    subnet_id: subnet_id
    vmPrefix: '${hostpoolName}-vm'
    vmInstanceSuffixes: [
      0
      1
    ] 
  }
  
}

module appgroup 'bicepmodules/applicationgroup.bicep' = {
  name: 'appgoup${currentDate}'
  dependsOn: [
    hostpool
  ]
  params: {
    hostPoolName: hostpoolName
    hostPoolRG: hostPoolRG
    location: location
    tagValues: tagValues
  }
}

module appgrouprole 'bicepmodules/appgrouproleassignment.bicep' = {
  name: 'appgrouprole${currentDate}'
  dependsOn: [
    appgroup
  ]

  params: {
    appGroupName: appgroup.outputs.applicationGroupName
    principalID: principalID
  }
}

module vmgrouprole 'bicepmodules/vmroleassignment.bicep' = {
  name: 'vmgrouprole${currentDate}'
  dependsOn: [
    hostpoolvms
  ]

  params: {
    vms: hostpoolvms.outputs.vmNames
    principalID: principalID
  }
}
module workspace 'bicepmodules/workspace.bicep' = {
  name: 'workspace${currentDate}'
  dependsOn:[
    appgrouprole
  ]
  
  params: {
    applicationGroups: array(appgroup.outputs.applicationGroupID)
    tagValues: tagValues
    location: location
    workspaceName: workspaceName
    workspaceFriendlyName: workspaceFriendlyName
  }
}
