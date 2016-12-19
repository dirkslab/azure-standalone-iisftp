# azure-standalone-iisftp ARM Template

Standalone azure iisftp server. Using Azure Resource Manager.

Unsecure with no ssl setup.
No user isolation.
One loacation for users to upload data, images or whatever the requirement might be.
In this specific case the server will be for uploading raw hd images and video, before it gets downloaded by editors. If this concept makes it to production it will be to replace filezilla server. 
There will be one ftp user group and users will be created and added to this group to access the ftp folder.
Obviously you should consider you security requirement levels and adjust scripts and templates to fit your specific case.

# some knowns
Have to restart the azure vm after installation and setup complete. Have not worked out how to avoid this
Must run iisreset after adding new users to ftpusergroup, otherwise they do not have access to the home directory.
Adjust the parameters in ps1 script as required. The ftpadmin password currently in clear text, you would want to change password or disble account/remove account if not needed.
