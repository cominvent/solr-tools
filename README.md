# Solr tools

Author: Jan Høydahl @ Cominvent AS

## upgradeindex.sh
Bash script to upgrade an entire Solr index from 4.x or 5.x to 6.x
so it can be read by Solr6.x or Solr 7.x

### Usage:

    Script to Upgrade old indices from 4.x and 5.x to 6.x format, so it can be used with Solr 6.x or 7.x
    Usage: ./upgradeindex.sh [-s] <indexdata-root>
    
    Example: ./upgradeindex.sh /var/lib/solr
    Please run the tool only on a cold index (no Solr running)
    The script leaves a backup in <indexdata-root>/<core>/data/index_backup_<version>.tgz. Use -s to skip backup
    Requires wget or curl to download dependencies


##SolrPasswordHash
Simple command line tool to generate a password hash for `security.json`

### Build

    mvn package

### Usage:

    java -jar target/security-tool-1.0-SNAPSHOT.jar admin 123
    Generating password hash for admin and salt 123:
    HZtl83vopLyZfOpGedEQveAwvVdAQ1Ukr6dDJPEfs/w= MTIz
    Example usage:
    "credentials":{"myUser":"HZtl83vopLyZfOpGedEQveAwvVdAQ1Ukr6dDJPEfs/w= MTIz"}
    
# License

All scripts © Cominvent AS and licensed under the Apache License v2.0
