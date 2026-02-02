import schema

create_service: (str, schema.microservice) -> any = lambda applicationname, microservice -> any {
    {
        apiVersion = "v1"
        kind = "Service"
        metadata = {
            name = "${microservice.name}"
            namespace = applicationname
            labels = {
                app = microservice.name
                "app.kubernetes.io/managed-by" = "crossplane"
            }
            annotations = {
                "krm.kcl.dev/composition-resource-name" = "${microservice.name}-service"
            }
        }
        spec = {
            selector.app = microservice.name
            if microservice.port != Undefined and microservice.targetPort != Undefined:
                ports = [{
                    port = microservice.port
                    targetPort = microservice.targetPort
                    protocol = "TCP"
                }]
            type = "ClusterIP"
        }
    }
}
