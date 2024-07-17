#
#    TDC: Test-driven configuration
#
#    define for testing groupship of a list of files
#
#    Copyright (C) 2020-2024  Thorsten Alteholz
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
#   define { 'tdc::test_file_group':
#        file   => [
#			{
#				file => '/usr/sbin/ntpd',
#				group => 'root',
#			},
#   }
#
# @param file Array of files to be tested
# @param nagiosout outputfile for this test
# @param nagioscheck name of check to be performed
# @param tdctitle name of test (should not be changed)
define tdc::test_file_group (
  Array   $file        = [],
  String  $nagiosout   = "${tdc::nagiosdir}/tdc-${facts['networking']['fqdn']}-${title}-file-group",
  String  $nagioscheck = "${tdc::checkrootdir}/${tdc::checkscriptdir}/check_tdc_file_group",
  String  $tdctitle = $title,
) {
#) inherits tdc {

  Exec {
    path    => ['/usr/bin', '/usr/sbin', '/bin'],
  }

  concat { "${tdc::checkrootdir}/${tdc::checkconfigdir}/tdc_${title}-file-group.cfg":
    owner => 'root',
    group => 'root',
    mode  => '0644',
  }

  concat::fragment { "${tdc::checkrootdir}/${tdc::checkconfigdir}/tdc_${title}-file-group.cfg header":
    target  => "${tdc::checkrootdir}/${tdc::checkconfigdir}/tdc_${title}-file-group.cfg",
    content => epp('tdc/tdc_config_header.epp', { 'type' => 'test for files', 'cmn' => $title }),
    order   => '00',
  }

  generate ('/bin/bash', '-c', "${tdc::generator} ${nagiosout} service no dummy")
  generate ('/bin/bash', '-c', "${tdc::generator} ${nagiosout} hostgroup no dummy ${facts['networking']['fqdn']}")

  # create the tests from the file array
  $lfqdn=$facts['networking']['fqdn']
  $file.each | $f, $fff | {
    concat::fragment { "${fff} ${f}":
      target  => "${tdc::checkrootdir}/${tdc::checkconfigdir}/tdc_${title}-file-group.cfg",
      content => "command[check_tdc_${title}-${f}-${lfqdn}-file-group]=${nagioscheck} ${fff['file']} ${fff['group']}\n",
      notify  => Service[$tdc::nrpeservice],
    }
    generate ('/bin/bash', '-c', "${tdc::generator} ${nagiosout} service yes check_tdc_${title}-${f}-${lfqdn}-file-group")
    generate ('/bin/bash', '-c', "${tdc::generator} ${nagiosout} hostgroup yes check_tdc_${title}-${f}-${lfqdn}-file-group ${lfqdn}")
  }

  if !defined(File["${tdc::checkrootdir}/${tdc::checkscriptdir}/check_tdc_file_group"]) {
    file { "${tdc::checkrootdir}/${tdc::checkscriptdir}/check_tdc_file_group":
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      path    => "${tdc::checkrootdir}/${tdc::checkscriptdir}/check_tdc_file_group",
      content => epp('tdc/check_tdc_file_group.epp'),
    }
  }

#III we don't need hosts yet:
# generate ("/bin/bash", "-c", "${tdc::generator} ${tdc::nagiosdir}/tdc-$fqdn-${title}-file-group host no $fqdn")
}
