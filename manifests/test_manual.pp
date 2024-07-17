#
#    TDC: Test-driven configuration
#
#    define for manual testing of nrpe stuff
#
#    Copyright (C) 2021-2024  Thorsten Alteholz
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
# @summary create manual tests
#
# @example Basic usage
#   define { 'tdc::test_manual':
#        manual   => ['check_debian_version'],
#   }
#
# @param manual Array of manual tests
# @param nagiosout outputfile for this test
# @param nagioscheckprefix name of prefix for check to be performed
# @param tdctitle name of test (should not be changed)
define tdc::test_manual (
  Array   $manual            = [],
  String  $nagiosout         = "${tdc::nagiosdir}/tdc-${facts['networking']['fqdn']}-${title}-manual",
  String  $nagioscheckprefix = '/usr/local/nagios/plugins',
  String  $tdctitle          = $title,
) {
#) inherits tdc {

  Exec {
    path    => ['/usr/bin', '/usr/sbin', '/bin'],
  }

  concat { "${tdc::checkrootdir}/${tdc::checkconfigdir}/tdc_${title}-manual.cfg":
    owner => 'root',
    group => 'root',
    mode  => '0644',
  }

  concat::fragment { "${tdc::checkrootdir}/${tdc::checkconfigdir}/tdc_${title}-manual.cfg header":
    target  => "${tdc::checkrootdir}/${tdc::checkconfigdir}/tdc_${title}-manual.cfg",
    content => epp('tdc/tdc_config_header.epp', { 'type' => 'manual test', 'cmn' => $title }),
    order   => '00',
  }

  generate ('/bin/bash', '-c', "${tdc::generator} ${nagiosout} service no dummy")
  generate ('/bin/bash', '-c', "${tdc::generator} ${nagiosout} hostgroup no dummy ${facts['networking']['fqdn']}")

  # create the tests from the manual array
  $lfqdn=$facts['networking']['fqdn']
  $manual.each | $f, $fff | {
    concat::fragment { "${fff} ${f}":
      target  => "${tdc::checkrootdir}/${tdc::checkconfigdir}/tdc_${title}-manual.cfg",
      content => "command[check_tdc_${title}-${f}-${lfqdn}-manual]=${nagioscheckprefix}/${fff} \n",
      notify  => Service[$tdc::nrpeservice],
    }
    generate ('/bin/bash', '-c', "${tdc::generator} ${nagiosout} service yes check_tdc_${title}-${f}-${lfqdn}-manual ${fff}")
    generate ('/bin/bash', '-c', "${tdc::generator} ${nagiosout} hostgroup yes check_tdc_${title}-${f}-${lfqdn}-manual ${lfqdn}")
  }

#III we don't need hosts yet:
# generate ("/bin/bash", "-c", "${tdc::generator} ${tdc::nagiosdir}/tdc-$fqdn-${title}-manual host no $fqdn")
}
