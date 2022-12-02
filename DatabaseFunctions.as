class DatabaseFunctions {
    string database_filename = "pb_grapher_store.db";
    SQLite::Database@ database = SQLite::Database(database_filename);

    DatabaseFunctions() {
        database.Execute("CREATE TABLE IF NOT EXISTS cp_log (cp_log_id INTEGER PRIMARY KEY AUTOINCREMENT, map_uuid VARCHAR, run_id INTEGER, cp_id INTEGER, cp_time FLOAT, respawns INTEGER)");
    }

    array<array<CpLog>> getCpLogsForMap(string _map_uuid) {
        SQLite::Statement@ num_runs_stmt = database.Prepare("SELECT max(run_id) num_runs FROM cp_log WHERE map_uuid = ?");
        num_runs_stmt.Bind(1, _map_uuid);
        num_runs_stmt.Execute();
        num_runs_stmt.NextRow();
        if (!num_runs_stmt.NextRow()) {
            return array<array<CpLog>>();
        };

        int num_runs = num_runs_stmt.GetColumnInt("num_runs");
        array<array<CpLog>> cpLogsForMap(10);
            for (int i = 0; i < num_runs; i++) {
                array<CpLog> returnVector();
                SQLite::Statement@ statement = database.Prepare("SELECT * FROM cp_log WHERE map_uuid = ?");
                statement.Bind(1, _map_uuid);
                statement.Execute();
                statement.NextRow();
                while (statement.NextRow()) {
                    returnVector.InsertLast(CpLog(statement));
                }
            cpLogsForMap.InsertLast(returnVector);
        }
        return cpLogsForMap;
}
}