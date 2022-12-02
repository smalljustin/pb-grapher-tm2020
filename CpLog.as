class CpLog
{
	int cp_log_id;
	string map_uuid;
	int run_id;
	int cp_id;
	float cp_time;
	
	CpLog() {}

	CpLog(string _map_uuid, int _run_id, int _cp_id, float _cp_time) {
		map_uuid = _map_uuid;
		run_id = _run_id;
		cp_id = _cp_id;
		cp_time = _cp_time;
	}

	CpLog(SQLite::Statement@ statement) {
		cp_log_id = statement.GetColumnInt("cp_log_id");
		map_uuid = statement.GetColumnString("map_uuid");
		run_id = statement.GetColumnInt("run_id");
		cp_id = statement.GetColumnInt("cp_id");
		cp_time = statement.GetColumnInt("cp_time");
	}

	void saveToStatement(SQLite::Statement@ statement) {
		statement.Bind(1, map_uuid);
		statement.Bind(2, run_id);
		statement.Bind(3, cp_id);
		statement.Bind(4, cp_time);
	}

	string tostring() {
		return "{\"cp_log_id\": " + cp_log_id + ", \"map_uuid\": \"" + map_uuid 
		+ "\"\", \"run_id\": " + run_id + ", \"cp_id\": " + cp_id
		+ ", \"cp_time\": " + cp_time + "}";
	}
}