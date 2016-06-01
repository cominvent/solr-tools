#!/usr/bin/env bash
JAR_CORE_5=lucene-core-5.5.1.jar
JAR_CORE_5_URL=http://central.maven.org/maven2/org/apache/lucene/lucene-core/5.5.1/lucene-core-5.5.1.jar
JAR_BACK_5=lucene-backward-codecs-5.5.1.jar
JAR_BACK_5_URL=http://central.maven.org/maven2/org/apache/lucene/lucene-backward-codecs/5.5.1/lucene-backward-codecs-5.5.1.jar
JAR_CORE_6=lucene-core-6.0.1.jar
JAR_CORE_6_URL=http://central.maven.org/maven2/org/apache/lucene/lucene-core/6.0.1/lucene-core-6.0.1.jar
JAR_BACK_6=lucene-backward-codecs-6.0.1.jar
JAR_BACK_6_URL=http://central.maven.org/maven2/org/apache/lucene/lucene-backward-codecs/6.0.1/lucene-backward-codecs-6.0.1.jar
BASEDIR=$(dirname "$0")
BACKUP=true
if [ "$1" == "-s" ] ; then
    unset BACKUP
    shift
fi
if [ X$1 == X ] ; then
	echo "Script to Upgrade old indices from 4.x and 5.x to 6.x format, so it can be used with Solr 6.x or 7.x"
	echo "Usage: $0 [-s] <indexdata-root>"
	echo
	echo "Example: $0 /var/lib/solr"
	echo "Please run the tool only on a cold index (no Solr running)"
	echo "The script leaves a backup in <indexdata-root>/<core>/data/index_backup_<version>.tgz. Use -s to skip backup"
	echo "Requires wget or curl to download dependencies"
	exit
fi

if [[ ! -f ./$JAR_CORE_5 ]] ; then
    curl --version >/dev/null
    if [[ $? -eq 0 ]] ; then
        tool="curl -O -# "
    else
        wget --version >/dev/null
        if [[ $? -eq 0 ]] ; then
            tool="wget -q "
        else
            echo "You need wget or curl to download dependencies"
            exit 2
        fi
    fi
    for f in $JAR_BACK_5_URL $JAR_BACK_6_URL $JAR_CORE_5_URL $JAR_CORE_6_URL ; do
        echo "Downloading $f"
        $tool $f
    done
fi

DIR="$1"

CORES=$(for a in `find $DIR -name data`; do dirname $a; done);

function upgrade() {
  INDEXDIR=$1
  ver=$(java -cp $BASEDIR/$JAR_CORE_6:$BASEDIR/$JAR_BACK_6 org.apache.lucene.index.CheckIndex -fast $INDEXDIR|grep "   version="|sed -e 's/.*=//g'|head -1)
  if [ X$ver == X ] ; then
      ver=$(java -cp $BASEDIR/$JAR_CORE_5:$BASEDIR/$JAR_BACK_5  org.apache.lucene.index.CheckIndex -fast $INDEXDIR|grep "   version="|sed -e 's/.*=//g'|head -1)
  fi
  if [ X$ver == X ] ; then
      echo "- Empty index?"
      return
  fi
  majorVer=$(echo $ver|cut -c 1)
  if [ $majorVer -lt 6 ] ; then
      if [[ $BACKUP ]] ; then
        file=$(basename $INDEXDIR)
        dir=$(dirname $INDEXDIR)
        echo "- Backing up index to $dir/${file}_backup_$ver.tgz"
        tar -C "$dir" -czf "$dir/${file}_backup_$ver.tgz" "$file"
      fi
  fi
  if [ $majorVer -lt 5 ] ; then
      CP="$BASEDIR/$JAR_CORE_5:$BASEDIR/$JAR_BACK_5"
  else
      CP="$BASEDIR/$JAR_CORE_6:$BASEDIR/$JAR_BACK_6"
  fi
  echo "- Index version is $ver, checking integrity"
  java -cp $CP org.apache.lucene.index.CheckIndex -fast $INDEXDIR|grep "check integrity"
  if [ $majorVer -lt 5 ] ; then
      echo "- Upgrading 4.x -> 5.x"
      java -cp $BASEDIR/$JAR_CORE_5:$BASEDIR/$JAR_BACK_5 org.apache.lucene.index.IndexUpgrader -delete-prior-commits $INDEXDIR
  fi
  if [ $majorVer -lt 6 ] ; then
      echo "- Upgrading 5.x -> 6.x"
      java -cp $BASEDIR/$JAR_CORE_6:$BASEDIR/$JAR_BACK_6 org.apache.lucene.index.IndexUpgrader -delete-prior-commits $INDEXDIR
  else
      echo "- Already on version $ver, not upgrading"
  fi
}

if [[ "X$CORES" == "X" ]] ; then
  echo "No indices found on path $DIR"
else
    for c in $CORES ; do
      if [[ -d $c/data/index ]]; then
        name=$(echo $c | sed -e 's/.*\///g')
        abspath=$(cd "$(dirname "$c")"; pwd)/$(basename "$c")
        echo "Upgrading core $name - $abspath"
        upgrade $c/data/index
        if [[ "dn" == "$name" ]] ; then
            echo "Upgrading autosuggest index $name - wine_suggest_index"
            upgrade $c/data/wine_suggest_index
        fi
      else
        echo "No index folder found for $name"
      fi
    done
    echo "DONE"
fi
