print("Nether Ore Finder: Master")
print(" ")
print("Instaling...")
shell.run("delete state.cc")
shell.run("delete mastercode")
shell.run("delete spots.cc")
shell.run("rom/programs/http/pastebin get bBNq1NEw mastercode")
shell.run("rom/programs/http/pastebin get bmXSz0DS spots.cc")
shell.run("rom/programs/http/pastebin get amfVpKfB reset")
print("Done!")
