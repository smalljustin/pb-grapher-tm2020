class DatabaseFunctions {
    string database_filename = "pb_grapher_store.db";
    SQLite::Database@ database = SQLite::Database(database_filename);
    string getCpLogsForMapSql = """
        WITH run_time AS 
        (SELECT map_uuid, run_id, MAX(cp_time) AS run_time
        FROM cp_log
		WHERE run_id IN (
			SELECT DISTINCT run_id FROM cp_log _cp_log WHERE _cp_log.map_uuid = cp_log.map_uuid AND _cp_log.cp_id = (SELECT MAX(cp_id) FROM cp_log __cp_log WHERE __cp_log.map_uuid = _cp_log.map_uuid GROUP BY __cp_log.map_uuid)
		)
		GROUP BY map_uuid, run_id
        ORDER BY run_time ASC
        LIMIT 5
        )
        SELECT cl.* FROM cp_log cl 
        JOIN run_time rt 
        ON cl.map_uuid = rt.map_uuid AND cl.run_id = rt.run_id
        WHERE cl.map_uuid = ?
        ORDER BY rt.run_time, cl.run_id, cl.cp_id
    """;
    DatabaseFunctions() {
        database.Execute("CREATE TABLE IF NOT EXISTS cp_log (cp_log_id INTEGER PRIMARY KEY AUTOINCREMENT, map_uuid VARCHAR, run_id INTEGER, cp_id INTEGER, cp_time FLOAT, UNIQUE(map_uuid, run_id, cp_id))");
    }
    void persistBuffer(array<CpLog> active_run_buffer) {
        string sql = "INSERT INTO cp_log (map_uuid, run_id, cp_id, cp_time) VALUES (?, ?, ?, ?)";
        for (int i = 0; i < active_run_buffer.Length; i++) {
            SQLite::Statement@ stmt = database.Prepare(sql);
            active_run_buffer[i].saveToStatement(stmt);
            stmt.Execute();
            log(active_run_buffer[i].tostring());
        }
        
    }

    int getNumRunsForMap(string _map_uuid) {
        SQLite::Statement@ num_runs_stmt = database.Prepare("SELECT max(run_id) num_runs FROM cp_log WHERE map_uuid = ?");
        num_runs_stmt.Bind(1, _map_uuid);
        num_runs_stmt.Execute();
        num_runs_stmt.NextRow();
        if (!num_runs_stmt.NextRow()) {
            return 0;
        };
        return num_runs_stmt.GetColumnInt("num_runs");
    }

    array<array<CpLog>> getCpLogsForMap(string _map_uuid) {
        int num_runs = getNumRunsForMap(_map_uuid);

        array<array<CpLog>> cpLogsForMap();

        if (num_runs == 0) {
            return cpLogsForMap;
        }

        array<CpLog> current_set;
        int current_run = -1;
        int idx = -1; 

        SQLite::Statement@ statement = database.Prepare(getCpLogsForMapSql);
        statement.Bind(1, _map_uuid);
        statement.Execute();
        while (statement.NextRow()) {
            CpLog cp_log_tmp = CpLog(statement);
            if (cp_log_tmp.run_id == current_run){
                cpLogsForMap[idx].InsertLast(cp_log_tmp);
            } else {
                idx += 1;
                current_run = cp_log_tmp.run_id;
                cpLogsForMap.InsertLast(array<CpLog>());
                cpLogsForMap[idx].InsertLast(cp_log_tmp);
            }
        }
        for (int i = 0; i < cpLogsForMap.Length; i++) {
            log(tostring(cpLogsForMap[i].Length));
            if (cpLogsForMap[i][0].cp_id != 0) {
                log("Warning: First cp doesn't have an index of zero! Removing this one.");
                cpLogsForMap.RemoveAt(i);
            }
        }
        return cpLogsForMap;
    }


}