Application.ensure_all_started(:mimic)
Mimic.copy(FarmbotCeleryScript.SysCalls.Stubs)
ExUnit.configure(max_cases: 1)
ExUnit.start()
