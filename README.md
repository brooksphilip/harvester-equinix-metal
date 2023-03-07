
# Harvester Equinix Metal Terraform
This terraform is used to deploy harvester onto Equinix Metal. It can deploy a single node or a three node cluster. 

It deploys a single node by default. 

To deploy a 3 node cluster change "build_cluster" to true. 

### Deploy

```bash
cp terrform.tfvars.tmpl terraform.tfvars
```

Fill in details in terraform.tfvars

```bash
terraform apply
```

