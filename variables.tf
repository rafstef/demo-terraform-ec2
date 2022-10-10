locals {
    env = {
        DEV ="dev"
        BUGFIXING = "bugfixing"
        PREPROD = "preprod"
        PROD = "prod"
    }
    resource_prefix = {
        DEV ="microservicies-infra"
        BUGFIXING = "microservicies-infra"
        PREPROD = "microservicies-infra"
        PROD = "microservicies-infra"
    }
    frontend_instance_count = {
        DEV = "1"
        BUGFIXING = "2"
        PREPROD = "2"
        PROD = "2"
    }
    backend_instance_count = {
        DEV = "1"
        BUGFIXING = "2"
        PREPROD = "2"
        PROD = "2"
    }
}

