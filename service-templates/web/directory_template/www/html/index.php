<?php

function existsbin($bin) {
    exec("which ".$bin, $output, $retval);
    if ($retval != 0) {
        echo "Binary ".$bin." nicht gefunden.";
    }
}

?>

<html>
<head>
</head>
<body>
  <h1>It works for kvwmap!</h1><br>
  <b>
    <?php existsbin("mysql"); ?><br>
    <?php existsbin("psql"); ?><br>
    <?php existsbin("/usr/lib/cgi-bin/mapserv"); ?><br>
  </b>
</body>
</html>
