import templates
import schema

oxr = option("params").oxr
applicationname: str = oxr.spec.applicationname
stage: str = oxr.spec.stage
microservices: [schema.microservice] = oxr.spec.microservices

_deployments = [templates.create_deployment(applicationname, stage, microservice) for microservice in microservices]
_services = [templates.create_service(applicationname, microservice) for microservice in microservices]
items = _deployments + _services
