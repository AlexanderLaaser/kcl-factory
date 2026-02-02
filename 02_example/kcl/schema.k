schema baseenv:
    name: str
    value: str

schema secretenv:
    name: str
    keyvaultName: str

schema request:
    cpu: str
    memory: str

schema limit:
    cpu: str
    memory: str

schema resources:
    requests: request
    limits: limit

schema microservice:
    name: str
    imageUrl: str
    targetPort?: int
    port?: int
    baseenvs?: [baseenv]
    secretenvs?: [secretenv]
    resources: resources

