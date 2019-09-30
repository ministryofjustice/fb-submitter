# not used
ALL_ENVS = {
  dev: {
    name: 'Development',
    internal_service_port: 3000,
    # we're still using internal http until Cloud Platforms
    # come up with a platform solution
    protocol: 'http://',
    url_root: 'apps.cloud-platform-live-0.k8s.integration.dsd.io'
  },
  staging: {
    name: 'Staging',
    internal_service_port: 3000,
    protocol: 'http://',
    url_root: 'apps.cloud-platform-live-0.k8s.integration.dsd.io'
  },
  production: {
    name: 'Production',
    internal_service_port: 3000,
    protocol: 'http://',
    url_root: 'apps.cloud-platform-live-0.k8s.integration.dsd.io'
  }
}.freeze

Rails.configuration.x.service_environments = ALL_ENVS
