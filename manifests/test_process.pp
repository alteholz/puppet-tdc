#
#    TDC: Test-driven configuration
#
#    define for testing presence of a list of running processes
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
# @summary create tests for a list of processes
#
# @example Basic usage
#   define { 'tdc::test_process':
#        process   => ['tayga'],
#   }
#
# @param process Array of processes to be tested
# @param nagiosout outputfile for this test
# @param nagioscheck name of check to be performed
# @param minprocs minimal number of processes that should be available
# @param maxprocs maximal number of processes that should be available
# @param tdctitle name of test (should not be changed)
define tdc::test_process (
  Array   $process     = [],
  String  $nagiosout   = "${tdc::nagiosdir}/tdc-${facts['networking']['fqdn']}-${title}-process",
  String  $nagioscheck = '/usr/lib/nagios/plugins/check_procs',
  Integer $minprocs    = 1,
  Integer $maxprocs    = 1,
  String  $tdctitle = $title,
) {
#) inherits tdc {

  Exec {
    path    => ['/usr/bin', '/usr/sbin', '/bin'],
  }

  concat { "${tdc::checkrootdir}/${tdc::checkconfigdir}/tdc_${title}-process.cfg":
    owner => 'root',
    group => 'root',
    mode  => '0644',
  }

  concat::fragment { "${tdc::checkrootdir}/${tdc::checkconfigdir}/tdc_${title}-process.cfg header":
    target  => "${tdc::checkrootdir}/${tdc::checkconfigdir}/tdc_${title}-process.cfg",
    content => epp('tdc/tdc_config_header.epp', { 'type' => 'test for process', 'cmn' => $title }),
    order   => '00',
  }

  generate ('/bin/bash', '-c', "${tdc::generator} ${nagiosout} service no dummy")
  generate ('/bin/bash', '-c', "${tdc::generator} ${nagiosout} hostgroup no dummy ${facts['networking']['fqdn']}")

  # create the tests from the process array
  $process.each | $f, $fff | {
    concat::fragment { "${fff} ${f}":
      target  => "${tdc::checkrootdir}/${tdc::checkconfigdir}/tdc_${title}-process.cfg",
      content => "command[check_tdc_${title}-${f}-${facts['networking']['fqdn']}-process]=${nagioscheck}
        -C ${fff} -c ${minprocs}:${maxprocs}\n",
      notify  => Service[$tdc::nrpeservice],
    }
    generate ('/bin/bash', '-c',
    "${tdc::generator} ${nagiosout} service yes check_tdc_${title}-${f}-${facts['networking']['fqdn']}-process")
    generate ('/bin/bash', '-c',
    "${tdc::generator} ${nagiosout} hostgroup yes check_tdc_${title}-${f}-${facts['networking']['fqdn']}-process ${facts['networking']['fqdn']}")
  }

#III we don't need hosts yet:
# generate ("/bin/bash", "-c", "${tdc::generator} ${tdc::nagiosdir}/tdc-$fqdn-${title}-process host no $fqdn")
}
