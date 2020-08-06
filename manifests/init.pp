#
#    TDC: Test-driven configuration
#
#    main definition of class tdc
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
# @summary initial configuration of the TDC module, needs to be called first
#
# @example Basic usage
#   tdc {}
#   }
#
# @param monitor
#   Monitoring software that shall be used together with this module.
#   Currently only nagios is supported (and probably icinga).
# @param checkrootdir
#   Root directory of the tree where all configuration and scripts will be stored.
# @param checkscriptdir
#   Subdirectory of $checkrootdir to define the location of all scripts that perform checks.
# @param checkconfigdir
#   Subdirectory of $checkrootdir to define the location of all configurations files.
# @param nagiosdir
#   Directory on puppetmaster where all nagios configurations files shall be stored.
# @param generator
#   Generator for configuration files (up to now only nagios)
# @param nrpeservice
#   service to notify in case of changed test configuration
#
class tdc (
  String  $monitor      = 'nagios',
  String  $checkrootdir      = '/usr/local/nagios/tdc',
  String  $checkscriptdir    = 'plugins',
  String  $checkconfigdir    = 'config',
  String  $nagiosdir      = '/etc/puppet/code/environments/production/modules/nagios4_server/files/tdc',
  String  $generator      = '/usr/share/puppet/modules/tdc/lib/puppet-generator-nagios',
  String  $nrpeservice      = 'nagios-nrpe-server',
) {

  warning("here i am $nrpeservice")

  Exec {
    path    => ['/usr/bin', '/usr/sbin', '/bin'],
  }

  file{ $checkrootdir:
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
    }
  file{ "${checkrootdir}/${checkscriptdir}":
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
    }

  file{ "${checkrootdir}/${checkconfigdir}":
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
    }

}
