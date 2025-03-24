Download packer

Run packer init
Run packer build is-vm-packer.pkr.hcl 

To create the SP

```
az ad sp create-for-rbac --name "app-iam-rnd-compute-gallery-contributor" --role "Contributor" --scopes /subscriptions/49d8698e-7ee0-4233-86aa-7335a542d379/resourceGroups/is-azure-marketplace-poc --query "{ client_id: appId, client_secret: password, tenant_id: tenant }"
```


Create shared image gallery
```
az sig image-definition create --resource-group is-azure-marketplace-poc --location eastus2 --gallery-name acgisazuremarketplace --gallery-image-definition imgdfnisazuremarketplace --os-type Linux --publisher Canonical --offer 0001-com-ubuntu-server-jammy --sku 22_04-lts-gen2 --architecture x64 --os-state Generalized

--eula https://wso2.com/licenses/eula/3.4 --privacy-statement-uri https://wso2.com/privacy-policy/ 
```