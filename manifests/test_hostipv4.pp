#
#    TDC: Test-driven configuration
#
#    define for testing presence of a host via ipv4
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
# @summary create tests to check whether host is up via ipv4
#
# @example Basic usage
#   define { 'tdc::test_hostipv4':
#        host   => ['host.example.com'],
#   }
#
# @param host Array of hosts to be tested
# @param nagiosout outputfile for this test
# @param nagioscheck name of check to be performed
# @param pingwarning waring level for ping
# @param pingcritical critical level for ping
# @param tdctitle name of test (should not be changed)
define tdc::test_hostipv4 (
  Array   $host         = [],
  String  $nagiosout    = "${tdc::nagiosdir}/tdc-${facts['networking']['fqdn']}-${title}-hostipv4",
  String  $nagioscheck  = '/usr/lib/nagios/plugins/check_ping',
  String  $pingwarning  = '1000,20%',
  String  $pingcritical = '1500,60%',
  String  $tdctitle = $title,
) {
#) inherits tdc {

  Exec {
    path    => ['/usr/bin', '/usr/sbin', '/bin'],
  }

  concat { "${tdc::checkrootdir}/${tdc::checkconfigdir}/tdc_${title}-hostipv4.cfg":
    owner => 'root',
    group => 'root',
    mode  => '0644',
  }

  concat::fragment { "${tdc::checkrootdir}/${tdc::checkconfigdir}/tdc_${title}-hostipv4.cfg header":
    target  => "${tdc::checkrootdir}/${tdc::checkconfigdir}/tdc_${title}-hostipv4.cfg",
    content => epp('tdc/tdc_config_header.epp', { 'type' => 'test for hostipv4', 'cmn' => $title }),
    order   => '00',
  }

  generate ('/bin/bash', '-c', "${tdc::generator} ${nagiosout} service no dummy")
  generate ('/bin/bash', '-c', "${tdc::generator} ${nagiosout} hostgroup no dummy ${facts['networking']['fqdn']}")

  # create the tests from the process array
  $host.each | $f, $fff | {
    concat::fragment { "${fff} ${f}":
      target  => "${tdc::checkrootdir}/${tdc::checkconfigdir}/tdc_${title}-hostipv4.cfg",
      content => "command[check_tdc_${title}-${f}-${facts['networking']['fqdn']}-hostipv4]=${nagioscheck}
        -H ${fff} -4 -w ${pingwarning} -c ${pingcritical}\n",
      notify  => Service[$tdc::nrpeservice],
    }
    generate ('/bin/bash', '-c',
    "${tdc::generator} ${nagiosout} service yes check_tdc_${title}-${f}-${facts['networking']['fqdn']}-hostipv4")
    generate ('/bin/bash', '-c',
    "${tdc::generator} ${nagiosout} hostgroup yes check_tdc_${title}-${f}-${facts['networking']['fqdn']}-hostipv4 ${facts['networking']['fqdn']}")
  }

#III we don't need hosts yet:
# generate ("/bin/bash", "-c", "${tdc::generator} ${tdc::nagiosdir}/tdc-$fqdn-${title}-hostipv4 host no $fqdn")
}
