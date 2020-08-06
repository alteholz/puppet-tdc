#
#    TDC: Test-driven configuration
#
#    class for testing configuration of a software
#
#    Copyright (C) 2020  Thorsten Alteholz
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation in version 2 of the License.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
#
# @summary create tests for a list of files
#
# @example Basic usage
#   define { 'tdc::test_config':
#        command   => '/usr/sbin/apache2ctl -t',
#   }
#   define { 'tdc::test_config':
#        type      => 'apache2',
#   }
#
# @param command
#   Command to execute
# @param type
#   Type of check; using internal commands
#

define tdc::test_config (
  String  $command     = '',
  String  $type        = 'undef',
  String  $nagiosout   = "${tdc::nagiosdir}/tdc-${::fqdn}-${title}-config",
  String  $nagioscheck = "${tdc::checkrootdir}/${tdc::checkscriptdir}/check_tdc_config",
) {
#) inherits tdc {

  Exec {
    path    => ['/usr/bin', '/usr/sbin', '/bin'],
  }

  case $type {
	'apache2', 'apache': { $doit = '/usr/sbin/apache2ctl -t' }
	'default': {$doit = $command }
  }
  if $doit == '' {$doit = '/bin/false' }

  concat{ "${::tdc::checkrootdir}/${::tdc::checkconfigdir}/tdc_${title}-config.cfg":
    owner => 'root',
    group => 'root',
    mode  => '0644',
  }

  concat::fragment{ "${::tdc::checkrootdir}/${::tdc::checkconfigdir}/tdc_${title}-config.cfg header":
      target  => "${::tdc::checkrootdir}/${::tdc::checkconfigdir}/tdc_${title}-config.cfg",
      content => epp('tdc/tdc_config_header.epp', {'type' => 'test for config', 'cmn' => $title}),
      order   => '00',
  }

  concat::fragment{ "${::tdc::checkrootdir}/${::tdc::checkconfigdir}/tdc_${title}-config.cfg 1":
    target  => "${::tdc::checkrootdir}/${::tdc::checkconfigdir}/tdc_${title}-config.cfg",
    content => "command[check_tdc_${$title}-${::fqdn}-config]=${nagioscheck} '${doit}'\n",
    notify  => Service[$::tdc::nrpeservice],
  }
  generate ('/bin/bash', '-c',
            "${::tdc::generator} ${nagiosout} service no check_tdc_${title}-${::fqdn}-config")
  generate ('/bin/bash', '-c',
            "${::tdc::generator} ${nagiosout} hostgroup no check_tdc_${title}-${::fqdn}-config ${::fqdn}")

if !defined(File["${tdc::checkrootdir}/${tdc::checkscriptdir}/check_tdc_config"]) {
  file{ "${::tdc::checkrootdir}/${::tdc::checkscriptdir}/check_tdc_config":
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      path    => "${::tdc::checkrootdir}/${::tdc::checkscriptdir}/check_tdc_config",
      content => epp('tdc/check_tdc_config.epp'),
  }
}

#III we don't need hosts yet:
# generate ("/bin/bash", "-c", "${::tdc::generator} ${::tdc::nagiosdir}/tdc-$fqdn-${title}-config host no $fqdn")
}
