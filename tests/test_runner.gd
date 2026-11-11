extends Node
## Runner de tests maison. Lancement :
##   godot --headless res://tests/test_runner.tscn
## Option : `-- --only=test_time` pour ne lancer qu'un fichier.

const TEST_DIR: String = "res://tests/"


func _ready() -> void:
	var only: String = ""
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.trim_prefix("--only=")
	var files: Array[String] = []
	for f: String in DirAccess.get_files_at(TEST_DIR):
		if f.begins_with("test_") and f.ends_with(".gd") and f != "test_runner.gd" and f != "test_case.gd":
			if only == "" or f.get_basename() == only:
				files.append(f)
	files.sort()
	var total_checks: int = 0
	var total_tests: int = 0
	var failed: Array[String] = []
	for f: String in files:
		var script: GDScript = load(TEST_DIR + f)
		var tc: TestCase = script.new()
		for m: Dictionary in script.get_script_method_list():
			var mname: String = m["name"]
			if not mname.begins_with("test_"):
				continue
			tc.begin("%s.%s" % [f.get_basename(), mname])
			tc.before_each()
			await tc.call(mname)
			total_tests += 1
		total_checks += tc.checks
		failed.append_array(tc.failures)
		print("  %s %s" % ["OK  " if tc.failures.is_empty() else "FAIL", f])
	print("")
	for msg: String in failed:
		print("  ✗ " + msg)
	print("Tests : %d · vérifications : %d · échecs : %d" % [total_tests, total_checks, failed.size()])
	get_tree().quit(1 if not failed.is_empty() else 0)
