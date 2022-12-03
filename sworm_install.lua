print("Sworm Ore Finder")
print(" ")

if fs.exists("state.cc") then
  print("  -- Deleting state.cc")
  shell.run("delete state.cc")
end
if fs.exists("sworm_api") then
  print("  -- Deleting sworm_api")
  shell.run("delete sworm_api")
end
if fs.exists("startup") then
  print("  -- Deleting startup")
  shell.run("delete startup")
end

print("Instaling...")
shell.run("rom/programs/http/pastebin get TtbVATev sworm_api")

if arg[1] == "master" then
  print("  Install MASTER")
  shell.run("label set master-" .. os.getComputerID())
  shell.run("rom/programs/http/pastebin get qyNPY1r4 startup")
else
  print("  Install SLAVE")
  shell.run("label set slave-" .. os.getComputerID())
  shell.run("rom/programs/http/pastebin get T5N2kxDA startup")
end

print("Done!")

-- pastebin get mef07AqS sworm_install

-- pastebin get mef07AqS install
