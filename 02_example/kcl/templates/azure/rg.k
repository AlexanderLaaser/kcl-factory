create_resourcegroup: (str, str) -> any = lambda applicationname, stage -> any {
    {
        apiVersion = "azure.m.upbound.io/v1beta1"
        kind = "ResourceGroup"
        metadata = {
            name = "rg-${applicationname}-${stage}"
            namespace = applicationname
            labels = {
                "application" = "${applicationname}"
            }
        }
        spec = {
            providerConfigRef = {
                name = "azure-providerconfig"
                kind = "ClusterProviderConfig"
            }
            forProvider = {
                location = "westeurope"
                tags = {
                    provisioner = "crossplane"
                    application = applicationname
                }
            }
        }
    }
}
