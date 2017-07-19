#!/bin/bash

if [ -z "$MYSQL_DB" ]; then
    read -p "Dump which db? " MYSQL_DB
    if [ -z "$MYSQL_DB" ]; then
	echo "No DB: aborting"
	exit;
    fi;
fi;

if [ -z "$MYSQL_HOST" ]; then
    read -p "Dump from host? " MYSQL_HOST
    if [ -z "$MYSQL_HOST" ]; then
	echo "No host: aborting"
	exit;
    fi;
fi;

if [ -z "$MYSQL_USER" ]; then
    read -p "Connect as user? " MYSQL_USER
    if [ -z "$MYSQL_USER" ]; then
	echo "No user: aborting"
	exit;
    fi;
fi;

if [ -z "$MYSQL_PASS" ]; then
    read -s -p "Password for $MYSQL_USER? " MYSQL_PASS
    if [ -z "$MYSQL_PASS" ]; then
	echo "No password: aborting"
	exit;
    fi;
    echo;
fi;

function mysql_no_headers () {
    mysql --defaults-extra-file=<(printf "[client]\nhost = %s\nuser = %s\npassword = %s" "$MYSQL_HOST" "$MYSQL_USER" "$MYSQL_PASS") -N
}

# "raw" mode (-r) does not escape special characters like \n and \t

function mysql_no_headers_raw () {
    mysql --defaults-extra-file=<(printf "[client]\nhost = %s\nuser = %s\npassword = %s" "$MYSQL_HOST" "$MYSQL_USER" "$MYSQL_PASS") -N -r
}

function mysql_vertical_raw () {
    mysql --defaults-extra-file=<(printf "[client]\nhost = %s\nuser = %s\npassword = %s" "$MYSQL_HOST" "$MYSQL_USER" "$MYSQL_PASS") -E -r
}

function tables_of_type () {
    TABLE_TYPE=$1
    OBJ_QUERY="SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA = \"$MYSQL_DB\" AND TABLE_TYPE=\"$TABLE_TYPE\" ORDER BY 1;";
    OBJ_NAMES="$( echo $OBJ_QUERY | mysql_no_headers )"
    echo $OBJ_NAMES && return 1
    return 0
}

function routines_of_type () {
    ROUTINE_TYPE=$1
    OBJ_QUERY="SELECT ROUTINE_NAME FROM information_schema.ROUTINES WHERE ROUTINE_SCHEMA = \"$MYSQL_DB\" AND ROUTINE_TYPE=\"$ROUTINE_TYPE\" ORDER BY 1;";
    OBJ_NAMES="$(echo $OBJ_QUERY | mysql_no_headers )";
    echo $OBJ_NAMES && return 1
    return 0
}

echo "Dumping ${MYSQL_DB} artifacts as ${MYSQL_USER}@${MYSQL_HOST}..."

### Tables

OBJ_DIR="${MYSQL_DB}/Tables";
mkdir -p $OBJ_DIR

for N in $(tables_of_type 'BASE TABLE'); do
    # 'cut' returns just the create part of the result set (table name is returned in 1st column)
    CREATE_SQL="$( mysql_no_headers_raw  < <(echo "SHOW CREATE TABLE ${MYSQL_DB}.${N}") | cut -f2 | sed -e 's/ AUTO_INCREMENT=[^ ]*//' )";

    cat <<EOF > "${OBJ_DIR}/${N}.sql"
# TABLE: ${MYSQL_DB}.${N}

USE ${MYSQL_DB};

${CREATE_SQL};
EOF

done;

### Views

OBJ_DIR="${MYSQL_DB}/Views";
mkdir -p $OBJ_DIR

for N in $(tables_of_type 'VIEW'); do
    CREATE_SQL="$( mysql_no_headers < <(echo "SHOW CREATE VIEW ${MYSQL_DB}.${N}") | cut -f2 | sed -e 's/DEFINER=[^ ]*/DEFINER=CURRENT_USER()/' )";

    cat <<EOF > "${OBJ_DIR}/${N}.sql"
# VIEW: ${MYSQL_DB}.${N}

USE ${MYSQL_DB};

${CREATE_SQL};
EOF

done;

### Stored Procedures

OBJ_DIR="${MYSQL_DB}/Stored_Procedures";

mkdir -p $OBJ_DIR

for N in $(routines_of_type 'PROCEDURE'); do
    #
    # embededded tabs in the code definition cause issues with this output, so capture a vertical name/value pair stream (-E) and
    # then cleaned up...
    #
    CREATE_SQL="$( mysql_vertical_raw < <(echo "SHOW CREATE PROCEDURE ${MYSQL_DB}.${N}") )";

    # ...here's the cleanup. The "Create Procedure:" line is the start of the code
    CODE_START=$( echo "$CREATE_SQL" | egrep -n "^ *Create Procedure:" | cut -f1 -d\: );
    # ...and this header is one line past the end of the code
    CODE_END=$( echo "$CREATE_SQL"   | egrep -n "^ *character_set_client:" | cut -f1 -d\: );
    CODE_END=$(( $CODE_END - 1 ))

    # Now cut out the creamy middle from the MySQL result set
    CREATE_SQL=$(echo "${CREATE_SQL}" | head -n ${CODE_END} | tail -n +${CODE_START} | sed -e 's/^ *Create Procedure: *//'  | sed -e 's/DEFINER=[^ ]*/DEFINER=CURRENT_USER()/');

    cat <<EOF > "${OBJ_DIR}/${N}.sql"
# PROCEDURE: ${MYSQL_DB}.${N}

USE ${MYSQL_DB};

DROP PROCEDURE IF EXISTS ${MYSQL_DB}.${N};

DELIMITER \$\$

${CREATE_SQL}\$\$

DELIMITER ;
EOF

done;

### Functions

OBJ_DIR="${MYSQL_DB}/Functions";

mkdir -p $OBJ_DIR

for N in $(routines_of_type 'FUNCTION'); do
    CREATE_SQL="$( mysql_vertical_raw < <(echo "SHOW CREATE FUNCTION ${MYSQL_DB}.${N}") )";

    CODE_START=$( echo "$CREATE_SQL" | egrep -n "^ *Create Function:" | cut -f1 -d\: );
    CODE_END=$( echo "$CREATE_SQL"   | egrep -n "^ *character_set_client:" | cut -f1 -d\: );
    CODE_END=$(( $CODE_END - 1 ))

    CREATE_SQL=$(echo "${CREATE_SQL}" | head -n ${CODE_END} | tail -n +${CODE_START} | sed -e 's/^ *Create Function: *//' | sed -e 's/DEFINER=[^ ]*/DEFINER=CURRENT_USER()/');

    cat <<EOF > "${OBJ_DIR}/${N}.sql"
# FUNCTION: ${MYSQL_DB}.${N}

USE ${MYSQL_DB};

DROP FUNCTION IF EXISTS ${MYSQL_DB}.${N};

DELIMITER \$\$

${CREATE_SQL}\$\$

DELIMITER ;
EOF

done;

echo "DONE";
