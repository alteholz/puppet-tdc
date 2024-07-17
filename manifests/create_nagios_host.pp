#
#    TDC: Test-driven configuration
#
#    define host entry for nagios
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
# @summary create host entry for nagios
#
# @example Basic usage
#   define { 'tdc::create_nagios_host':
#   }
#
# @param nagiosout outputfile for this test
# @param nagioshostuse name of host to be used in definition
# @param nagioshostdb name of hostdb to be used
# @param tdctitle name of test (should not be changed)
define tdc::create_nagios_host (
  String  $nagiosout   = "${tdc::nagiosdir}/tdc-${facts['networking']['fqdn']}",
  String  $nagioshostuse = 'generic-host',
  String  $nagioshostdb = "${tdc::nagiosdir}/hostdb.tdc",
  String  $tdctitle = $title,
) {
#) inherits tdc {

  Exec {
    path    => ['/usr/bin', '/usr/sbin', '/bin'],
  }

  generate ('/bin/bash', '-c',
  "${tdc::generator} ${nagiosout} host onlycreateonce ${facts['networking']['fqdn']} ${nagioshostuse} ${nagioshostdb}")
}
