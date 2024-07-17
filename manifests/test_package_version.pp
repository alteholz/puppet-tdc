#
#    TDC: Test-driven configuration
#
#    define for testing version of a package
#
#    Copyright (C) 2024  Thorsten Alteholz
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
# @summary create tests for a list of packages
#
# @example Basic usage
#   define { 'tdc::test_file':
#        file   => ['/usr/sbin/ntpd', '/etc/ntp.conf'],
#   }
#
# @param packages Array of packages to be tested
# @param versions Array of versions to be tested
# @param nagiosout outputfile for this test
# @param nagioscheck name of check to be performed
# @param tdctitle name of test (should not be changed)
define tdc::test_package_version (
  Array   $packages    = [],
  Array   $versions    = [],
  String  $nagiosout   = "${tdc::nagiosdir}/tdc-${facts['networking']['fqdn']}-${title}-package_version",
  String  $nagioscheck = "${tdc::checkrootdir}/${tdc::checkscriptdir}/check_tdc_package_version",
  String  $tdctitle = $title,
) {
#) inherits tdc {

  include tdc

  Exec {
    path    => ['/usr/bin', '/usr/sbin', '/bin'],
  }

  concat { "${tdc::checkrootdir}/${tdc::checkconfigdir}/tdc_${title}-package_version.cfg":
    owner => 'root',
    group => 'root',
    mode  => '0644',
  }

  concat::fragment { "${tdc::checkrootdir}/${tdc::checkconfigdir}/tdc_${title}-package_version.cfg header":
    target  => "${tdc::checkrootdir}/${tdc::checkconfigdir}/tdc_${title}-package_version.cfg",
    content => epp('tdc/tdc_config_header.epp', { 'type' => 'test for package version', 'cmn' => $title }),
    order   => '00',
  }

  generate ('/bin/bash', '-c', "${tdc::generator} ${nagiosout} service no dummy")
  generate ('/bin/bash', '-c', "${tdc::generator} ${nagiosout} hostgroup no dummy ${facts['networking']['fqdn']}")

  # create the tests from the packages array
  $lfqdn=$facts['networking']['fqdn']
  $packages.each | $f, $fff | {
    concat::fragment { "${fff} ${f}":
      target  => "${tdc::checkrootdir}/${tdc::checkconfigdir}/tdc_${title}-package_version.cfg",
      content => "command[check_tdc_${title}-${f}-${lfqdn}-packages]=${nagioscheck} ${fff} ${versions[$f]}\n",
      notify  => Service[$tdc::nrpeservice],
    }
    generate ('/bin/bash', '-c', "${tdc::generator} ${nagiosout} service yes check_tdc_${title}-${f}-${lfqdn}-package_version")
    generate ('/bin/bash', '-c', "${tdc::generator} ${nagiosout} hostgroup yes check_tdc_${title}-${f}-${lfqdn}-package_version ${lfqdn}")
  }

  if !defined(File["${tdc::checkrootdir}/${tdc::checkscriptdir}/check_tdc_package_version"]) {
    file { "${tdc::checkrootdir}/${tdc::checkscriptdir}/check_tdc_package_version":
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      path    => "${tdc::checkrootdir}/${tdc::checkscriptdir}/check_tdc_package_version",
      content => epp('tdc/check_tdc_package_version.epp'),
    }
  }

#III we don't need hosts yet:
# generate ("/bin/bash", "-c", "${tdc::generator} ${tdc::nagiosdir}/tdc-$lfqdn-${title}-file host no $lfqdn")
}
