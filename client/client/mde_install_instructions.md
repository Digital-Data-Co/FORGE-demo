
yum-config-manager –-add-repo=https://packages.microsoft.com/config/rhel/9/prod.repo
rpm –import http://packages.microsoft.com/keys/microsoft.asc
yum -y install mdatp
 
Copy MicrosoftDefenderATPOnboardingLinuxServer.py


python3 MicrosoftDefenderATPOnboardingLinuxServer.py

Configure MDE
1. Copy MicrosoftDefenderATPOnboardingLinuxServer.py to your system.
2. Verify that the endpoint is not already associated with an organization using the command "mdatp health –field org_i"
3. Onboard system by running command: python3 MicrosoftDefenderATPOnboardingLinuxServer.py
4. Verify that the endpoint is now associated with an organization using the mdatp health –field org_id. You should now have your organization ID displayed and it should match your organization ID in the MDE portal (Settings -> Microsoft 365 Defender). Verify the health status of Defender using the command mdatp health –field healthy. The response you will receive on a healthy endpoint is “true”.
 
5. Edit /etc/opt/microsoft/mdatp/managed/mdatp_managed.json, replace the default value with your provided tag: (via email to otp_support@us.navy.mil)
"key": "GROUP",
"value": " USN_XNET_ECH2_PLA_UIC_FQDN”