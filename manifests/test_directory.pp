#
#    TDC: Test-driven configuration
#
#    class for testing presence of a list of directories
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
# @summary create tests for a list of directories
#
# @example Basic usage
#   class { 'tdc::test_directory':
#        directory   => ['/etc', '/tmp'],
#   }
#
# @param directory
#   Array of directories to be tested
#

class tdc::test_directory (
  Array   $directory      = [],
  String  $nagiosout      = "${::tdc::nagiosdir}/tdc-${::fqdn}-${::tdc::caller_module_name}-directory",
  String  $nagioscheck    = "${::tdc::checkrootdir}/${::tdc::checkscriptdir}/check_tdc_directory",
) inherits tdc {

  Exec {
    path    => ['/usr/bin', '/usr/sbin', '/bin'],
  }

  concat{ "${::tdc::checkrootdir}/${::tdc::checkconfigdir}/tdc_${::tdc::caller_module_name}-directory.cfg":
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    notify => Service[$::tdc::nrpeservice],
  }

  concat::fragment{ "${::tdc::checkrootdir}/${::tdc::checkconfigdir}/tdc_${::tdc::caller_module_name}-directory.cfg header":
      target  => "${::tdc::checkrootdir}/${::tdc::checkconfigdir}/tdc_${::tdc::caller_module_name}-directory.cfg",
      content => epp('tdc/tdc_config_header.epp', {'type' => 'test for directories', 'cmn' => $::tdc::caller_module_name}),
      order   => '00',
  }

  generate ('/bin/bash',
            '-c',
            "${::tdc::generator} ${nagiosout} service no dummy")
  generate ('/bin/bash',
            '-c',
            "${::tdc::generator} ${nagiosout} hostgroup no dummy ${::fqdn}")

  # create the tests from the directory array
  $directory.each | $f, $ddd | {
    concat::fragment { "${ddd} ${f}":
      target  => "${::tdc::checkrootdir}/${::tdc::checkconfigdir}/tdc_${::tdc::caller_module_name}-directory.cfg",
      content => "command[check_tdc_${::tdc::caller_module_name}-${f}-${::fqdn}-directory]=${nagioscheck} ${ddd}\n",
    }
    generate ('/bin/bash',
              '-c',
              "${::tdc::generator} ${nagiosout} service yes check_tdc_${::tdc::caller_module_name}-${f}-${::fqdn}-directory")
    generate ('/bin/bash',
              '-c',
              "${::tdc::generator} ${nagiosout} hostgroup yes check_tdc_${::tdc::caller_module_name}-${f}-${::fqdn}-directory ${::fqdn}")
  }

  file{ "${::tdc::checkrootdir}/${::tdc::checkscriptdir}/check_tdc_directory":
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      path    => "${::tdc::checkrootdir}/${::tdc::checkscriptdir}/check_tdc_directory",
      content => epp('tdc/check_tdc_directory.epp'),
  }

#III we don't need hosts yet:
#  generate ("/bin/bash", "-c", "${::tdc::generator} ${nagiosout} host no ${::fqdn}")
}
