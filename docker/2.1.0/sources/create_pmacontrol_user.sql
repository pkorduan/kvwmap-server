GRANT USAGE ON mysql.* TO 'pmacontroluser'@'172.17.%' IDENTIFIED BY '$KVWMAP_INIT_PASSWORD';
GRANT SELECT (
    Host, User, Select_priv, Insert_priv, Update_priv, Delete_priv,
    Create_priv, Drop_priv, Reload_priv, Shutdown_priv, Process_priv,
    File_priv, Grant_priv, References_priv, Index_priv, Alter_priv,
    Show_db_priv, Super_priv, Create_tmp_table_priv, Lock_tables_priv,
    Execute_priv, Repl_slave_priv, Repl_client_priv
    ) ON mysql.user TO 'pmacontroluser'@'172.17.%';
GRANT SELECT ON mysql.db TO 'pmacontroluser'@'172.17.%';
GRANT SELECT ON mysql.host TO 'pmacontroluser'@'172.17.%';
GRANT SELECT (Host, Db, User, Table_name, Table_priv, Column_priv)
    ON mysql.tables_priv TO 'pmacontroluser'@'172.17.%';
FLUSH PRIVILEGES;