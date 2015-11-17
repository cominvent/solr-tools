# Solr security tools

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