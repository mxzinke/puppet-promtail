# @summary Creates a service defintion for promtail
#
# Creates a service defintion for promtail
#
# @api private
class promtail::service {
  $service_to_notify = $facts['kernel'] ? {
    'Linux'   => Systemd::Unit_file['promtail.service'],
    'windows' => Service['promtail'],
    default   => undef
  }

  case $facts['kernel'] {
    'Linux': {
      systemd::unit_file { 'promtail.service':
        source => 'puppet:///modules/promtail/promtail.service',
        notify => Service['promtail'],
      }

      service { 'promtail':
        ensure  => $promtail::service_ensure,
        enable  => $promtail::service_enable,
        require => Systemd::Unit_file['promtail.service'],
      }
    }
    'windows': {
      exec { 'install_service':
        command  => "New-Service -Name promtail -StartupType Automatic -BinaryPathName \"${promtail::install::binary_link_path} --config.file ${promtail::config::config_file}\"",
        provider => powershell,
        unless   => 'Get-Service promtail',
      }

      service { 'promtail':
        ensure  => $promtail::service_ensure,
        enable  => $promtail::service_enable,
        start   => "${promtail::install::binary_link_path} --config.file ${promtail::config::config_file}",
        require => Exec['install_service']
      }
    }
    default: { fail("${facts['kernel']} is not supported") }
  }
}
