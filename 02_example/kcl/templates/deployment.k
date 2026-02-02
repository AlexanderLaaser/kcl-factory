import schema

create_deployment: (str, str, schema.microservice) -> any = lambda applicationname, stage, microservice -> any {
    _baseenvs: [schema.baseenv] = microservice.baseenvs if ("baseenvs" in microservice and microservice.baseenvs != Undefined) else []

    _secrets: [schema.secretenv] = microservice.secretenvs if ("secretenvs" in microservice and microservice.secretenvs != Undefined) else []
    _secretenvs: [any] = [{name = s.name, valueFrom = {
        secretKeyRef = {name = "secret-${applicationname}-${stage}", key = s.keyvaultName}
    }} for s in _secrets]

    {
        apiVersion = "apps/v1"
        kind = "Deployment"
        metadata = {
            name = "${microservice.name}-deployment"
            namespace = applicationname
            labels = {
                app = microservice.name
                "app.kubernetes.io/part-of" = applicationname
                "app.kubernetes.io/managed-by" = "crossplane"
            }
            annotations = {
                "krm.kcl.dev/composition-resource-name" = "${microservice.name}-deployment"
            }
        }
        spec = {
            selector.matchLabels.app = microservice.name
            template = {
                metadata.labels.app = microservice.name
                spec = {
                    serviceAccountName = "sa-${applicationname}"
                    securityContext = {
                        runAsNonRoot = True
                        runAsUser = 1000
                    }
                    containers = [{
                        name = microservice.name
                        image = microservice.imageUrl
                        if microservice.targetPort != Undefined:
                            ports = [{containerPort = microservice.targetPort}]
                        securityContext = {
                            allowPrivilegeEscalation = False
                            capabilities.drop = ["ALL"]
                        }
                        env = _baseenvs + _secretenvs
                        resources = {
                            requests = {
                                memory = microservice.resources.requests.memory
                                cpu = microservice.resources.requests.cpu
                            }
                            limits = {
                                memory = microservice.resources.limits.memory
                                cpu = microservice.resources.limits.cpu
                            }
                        }
                    }]
                }
            }
        }
    }
}
