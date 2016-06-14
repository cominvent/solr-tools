# upgradeindex.sh

Bash script to upgrade an entire Solr index from 4.x -> 5.x -> 6.x so it can be read by Solr6.x or Solr 7.x

## Usage:

    Script to Upgrade old indices from 4.x -> 5.x -> 6.x format, so it can be used with Solr 6.x or 7.x
    Usage: ./upgradeindex.sh [-s] [-t target-ver] <indexdata-root>
    
    Example: ./upgradeindex.sh -t 5 /var/solr
    Please run the tool only on a cold index (no Solr running)
    The script leaves a backup in <indexdata-root>/<core>/data/index_backup_<version>.tgz. Use -s to skip backup
    Requires wget or curl to download dependencies

**Use on your own risk!**

## License

© [Cominvent AS](www.cominvent.com) and licensed under the Apache License v2.0
