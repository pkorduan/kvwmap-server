<?php
function getMySQLVersion() {
  return getVersionFromText(
    shell_exec('mysql -V')
  );
}

function getPostgreSQLVersion() { 
  return getVersionFromText(
    shell_exec('psql -h $MYSQL_PORT_3306_TCP_ADDR -V')
  );
}

function getMapServerVersion() {
  return getVersionFromText(
    shell_exec('/usr/lib/cgi-bin/mapserv -v')
  );
}

function getPHPVersion() {
  return getVersionFromText(
    shell_exec('php -v')
  );
}

function getVersionFromText($text) {
  preg_match('@[0-9]+\.[0-9]+\.[0-9]+@', $text, $version);
  return $version[0];
}

function versionFormatter($version) {
  return substr(
    str_pad(
      str_replace(
        '.', 
        '',
        $version
      ),
      3,
      '0',
      STR_PAD_RIGHT
    ),
    0,
    3
  );
}
?>
<html>
<head>
</head>
<body>
  <h1>It works for kvwmap!</h1><br>
  <b>MySQL-Version:</b> <?php echo versionFormatter(getMySQLVersion()); ?><br>
  <b>PostgreSQL-Version:</b> <?php echo versionFormatter(getPostgreSQLVersion()); ?><br>
  <b>MapServer-Version:</b> <?php echo versionFormatter(getMapServerVersion()); ?><br>
  <b>PHP-Version:</b> <?php echo versionFormatter(getPHPVersion()); ?><br>
  <?php
  #phpinfo();
  ?>
</body>
</html>