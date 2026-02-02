import templates.azure

oxr: any = option("params").oxr

stage: str = oxr.spec.stage
applicationname: str = oxr.spec.applicationname

_rg = azure.create_resourcegroup(applicationname, stage)

items: any = [_rg]
