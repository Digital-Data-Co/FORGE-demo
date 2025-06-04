vram-osa-proxy

These files support our reverse proxy in the OSA environment which is running OpenShift 4. This configuration successfully works to send traffic from the user browser -> Nginx reverse proxy -> VRAM application.

vram-proxy.tar.gz.rename
    This contains artifactory-prod.csa.spawar.navy.mil:8082/score/nginx:1.25.2 which is the Nginx image used to reverse proxy to the application. Remove ".rename" from the filename, that's just so it will sync to OneDrive.

proxy-dc.yaml
    Contains the DeploymentConfig for the Nginx image

nginx-conf-cm.yaml
    Contains nginx.conf that will be mounted into the image

nginx.conf
    Make any Nginx global changes here

nginx-conf-integ-cm.yaml
    Contains the individual server configs that will be mounted into the image. In this example, that would be vram-stage.conf.

vram-stage.conf
    Use this server config to handle the reverse proxy config. The upstream hostnames in upstream.conf have been merged into this file so upstream.conf is no longer needed. This file needs the most review for hostnames, filenames, etc.


One more thing this config will need for your testing with the self-signed cert is the self-signed CA. Mount the self-signed CA (in vram-ca.txt, extension changed for OneDrive) somewhere and make sure ssl_client_certificate is referencing it.