# azure-standalone-iisftp
Standalone azure iisftp server.
Unsecure with no ssl setup.
No user isolation.
One loacation for users to upload data, images or whatever the requirement might be. In this specific case the server will be for uploading raw hd images and video, before it gets downloaded by editors. If this concept makes it to production it will be to replace filezilla server. 
There will be one ftp user group and users will be created and added to this group to access the ftp folder.
Obviously you would want to consider you security requirement levels and adjust scripts and templates to fit your specific case.

# Requirements
For the NAT setup to work:
Must have your subscription ID you are deploying to.
Azure Resource Group Name, must be the same in the Parameters Template (azuredeploy.parameters.json) as the Azure Resource Group you create or deploy to.
