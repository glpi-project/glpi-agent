
# GLPI Agent Contribs

## Included contribs

 * [Unix](contrib/unix):
   * legacy Redhat init scripts
   * systemd sample service file
   * install-deb.sh by @J-C-P, script to simplify installation on debian/ubuntu, see [README](contrib/unix/install-deb-README.md)
 * [Windows](contrib/windows):
   * [glpi-agent-deployment.vbs](contrib/windows/glpi-agent-deployment.vbs):
     GLPI Agent deployment helper script
   * ADML & ADMX templates to help setup GLPI Agent through GPO
 * [netdisco_2_glpi.sh](contrib/netdisco/netdisco_2_glpi.sh) by Stoatwblr
   This script makes fusioninventory-compatible xml from netdisco data.
   Stoatwblr says even if it is ugly and slow, it works ;-)

## Submit your contribs

 * Clone [GLPI-Agent github repository](https://github.com/glpi-project/glpi-agent)
 * Create a dedicated branch to develop and test your contrib
 * On your develop branch, update this CONTRIB.md file to reference properly your contrib
 * Make a PR so we only include your new contrib reference
