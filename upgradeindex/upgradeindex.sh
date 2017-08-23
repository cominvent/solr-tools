#!/usr/bin/env bash

# Licensed under the Apache License 2.0: http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

VERSION_5=5.5.4
VERSION_6=6.6.0

JAR_CORE_5=lucene-core-$VERSION_5.jar
JAR_CORE_5_URL=http://central.maven.org/maven2/org/apache/lucene/lucene-core/$VERSION_5/lucene-core-$VERSION_5.jar
JAR_BACK_5=lucene-backward-codecs-$VERSION_5.jar
JAR_BACK_5_URL=http://central.maven.org/maven2/org/apache/lucene/lucene-backward-codecs/$VERSION_5/lucene-backward-codecs-$VERSION_5.jar
JAR_CORE_6=lucene-core-$VERSION_6.jar
JAR_CORE_6_URL=http://central.maven.org/maven2/org/apache/lucene/lucene-core/$VERSION_6/lucene-core-$VERSION_6.jar
JAR_BACK_6=lucene-backward-codecs-$VERSION_6.jar
JAR_BACK_6_URL=http://central.maven.org/maven2/org/apache/lucene/lucene-backward-codecs/$VERSION_6/lucene-backward-codecs-$VERSION_6.jar
BASEDIR=$(dirname "$0")
BACKUP=true
TARGET=6
while getopts ":st:" opt; do
  case $opt in
    s)
      unset BACKUP
      ;;
    t)
      TARGET=$OPTARG
      if [ $TARGET -ge 5 ] && [ $TARGET -le 6 ] ; then
        echo "Target version is $TARGET"
      else
        echo "Invalid target version $TARGET, must be 5 or 6"
        exit 1
      fi
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done
shift $(($OPTIND - 1))

if [ X$1 == X ] ; then
	echo "Script to Upgrade old indices from 4.x -> 5.x -> 6.x format, so it can be used with Solr 6.x or 7.x"
	echo "Usage: $0 [-s] [-t target-ver] <indexdata-root>"
	echo
	echo "Example: $0 -t 5 /var/solr"
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
  if [ $majorVer -lt $TARGET ] ; then
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
  if [ $majorVer -ge $TARGET ] ; then
      echo "- Already on version $ver, not upgrading"
  else
      echo "- Index version is $ver, checking integrity"
      java -cp $CP org.apache.lucene.index.CheckIndex -fast $INDEXDIR|grep "check integrity"
      if [ $majorVer -lt 5 ] && [ $TARGET -ge 5 ] ; then
          echo "- Upgrading 4.x -> 5.x"
          java -cp $BASEDIR/$JAR_CORE_5:$BASEDIR/$JAR_BACK_5 org.apache.lucene.index.IndexUpgrader -delete-prior-commits $INDEXDIR
          majorVer=5
      fi
      if [ $majorVer -lt 6 ] && [ $TARGET -ge 6 ] ; then
          echo "- Upgrading 5.x -> 6.x"
          java -cp $BASEDIR/$JAR_CORE_6:$BASEDIR/$JAR_BACK_6 org.apache.lucene.index.IndexUpgrader -delete-prior-commits $INDEXDIR
          majorVer=6
      fi
  fi
}

if [[ "X$CORES" == "X" ]] ; then
  echo "No indices found on path $DIR"
else
    for c in $CORES ; do
      if find $c/data -maxdepth 1 -type d -name 'index*' 1> /dev/null 2>&1; then
        name=$(echo $c | sed -e 's/.*\///g')
        abspath=$(cd "$(dirname "$c")"; pwd)/$(basename "$c")
        echo "Core $name - $abspath"
        find $c/data -maxdepth 1 -type d -name 'index*' | while read indexDir; do
	      upgrade "$indexDir"
        done
      else
        echo "No index folder found for $name"
      fi
    done
    echo "DONE"
fi