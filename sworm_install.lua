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
-- (deprecated) shell.run("rom/programs/http/pastebin get TtbVATev sworm_api")
shell.run("rom/programs/http/wget https://raw.githubusercontent.com/renanmfd/turtlesworm/master/sworm_api.lua sworm_api")

if arg[1] == "master" then
  print("  Install MASTER")
  shell.run("label set master-" .. os.getComputerID())
  -- (deprecated) shell.run("rom/programs/http/pastebin get qyNPY1r4 startup")
  shell.run("rom/programs/http/wget https://raw.githubusercontent.com/renanmfd/turtlesworm/master/sworm_master.lua startup")
else
  print("  Install SLAVE")
  shell.run("label set slave-" .. os.getComputerID())
  -- (deprecated) shell.run("rom/programs/http/pastebin get T5N2kxDA startup")
  shell.run("rom/programs/http/wget https://raw.githubusercontent.com/renanmfd/turtlesworm/master/sworm_slave.lua startup")
end

print("Done!")

-- (deprecated) pastebin get mef07AqS install
-- wget https://raw.githubusercontent.com/renanmfd/turtlesworm/master/sworm_install.lua install

-- GPS Program
-- shell.run("gps", "host", -95, 70, 115)
-- shell.run("gps", "host", -95, 65, 115)
-- shell.run("gps", "host", -95, 65, 110)
-- shell.run("gps", "host", -95, 70, 115)

