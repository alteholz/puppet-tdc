#
#    TDC: Test-driven configuration
#
#    define for testing permissions of a list of files
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
#   define { 'tdc::test_file_permission':
#        file   => [
#			{
#				file => '/usr/sbin/ntpd',
#				permission => '755',
#			},
#   }
#
# @param file
#   Array of files to be tested
#

define tdc::test_file_permission (
  Array   $file        = [],
  String  $nagiosout   = "${tdc::nagiosdir}/tdc-${facts['networking']['fqdn']}-${title}-file-permission",
  String  $nagioscheck = "${tdc::checkrootdir}/${tdc::checkscriptdir}/check_tdc_file_permission",
  String  $tdctitle = $title,
) {
#) inherits tdc {

  Exec {
    path    => ['/usr/bin', '/usr/sbin', '/bin'],
  }

  concat{ "${tdc::checkrootdir}/${tdc::checkconfigdir}/tdc_${title}-file-permission.cfg":
    owner => 'root',
    group => 'root',
    mode  => '0644',
  }

  concat::fragment{ "${tdc::checkrootdir}/${tdc::checkconfigdir}/tdc_${title}-file-permission.cfg header":
      target  => "${tdc::checkrootdir}/${tdc::checkconfigdir}/tdc_${title}-file-permission.cfg",
      content => epp('tdc/tdc_config_header.epp', {'type' => 'test for files', 'cmn' => $title}),
      order   => '00',
  }

  generate ('/bin/bash', '-c',
            "${tdc::generator} ${nagiosout} service no dummy")
  generate ('/bin/bash', '-c',
            "${tdc::generator} ${nagiosout} hostgroup no dummy ${facts['networking']['fqdn']}")

  # create the tests from the file array
  $file.each | $f, $fff | {
    concat::fragment { "${fff} ${f}":
      target  => "${tdc::checkrootdir}/${tdc::checkconfigdir}/tdc_${title}-file-permission.cfg",
      content => "command[check_tdc_${title}-${f}-${facts['networking']['fqdn']}-file-permission]=${nagioscheck} ${fff['file']} ${fff['permission']}\n",
      notify  => Service[$tdc::nrpeservice],
    }
    generate ('/bin/bash', '-c',
              "${tdc::generator} ${nagiosout} service yes check_tdc_${title}-${f}-${facts['networking']['fqdn']}-file-permission")
    generate ('/bin/bash', '-c',
              "${tdc::generator} ${nagiosout} hostgroup yes check_tdc_${title}-${f}-${facts['networking']['fqdn']}-file-permission ${facts['networking']['fqdn']}")
  }

if !defined(File["${tdc::checkrootdir}/${tdc::checkscriptdir}/check_tdc_file_permission"]) {
  file{ "${tdc::checkrootdir}/${tdc::checkscriptdir}/check_tdc_file_permission":
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      path    => "${tdc::checkrootdir}/${tdc::checkscriptdir}/check_tdc_file_permission",
      content => epp('tdc/check_tdc_file_permission.epp'),
  }
}

#III we don't need hosts yet:
# generate ("/bin/bash", "-c", "${tdc::generator} ${tdc::nagiosdir}/tdc-$fqdn-${title}-file-permission host no $fqdn")
}
