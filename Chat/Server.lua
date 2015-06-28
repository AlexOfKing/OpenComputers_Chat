﻿local component = require("component")
local event = require("event")
local serialization = require("serialization")
local text = require("text")
local unicode = require("unicode")
local modem = component.proxy("596f1d35-8939-4406-9f1d-a22cf9d31c76")
local primaryPort = math.random(512, 1024)

function ModemSettings()
	modem.open(254)
	modem.open(255) 
	modem.open(256)
	modem.open(primaryPort)
	modem.setStrength(5000)
end

function Manager()
	local _, _, address, port, _, message
	while true do
		_, _, address, port, _, message = event.pull("modem_message")
		if 		port == primaryPort then PrimaryLevel(message)
		elseif	port == 256 then AuthenticationLevel(address, message)
		elseif	port == 255 then RegistrationLevel(address, message)
		elseif	port == 254 then modem.send(address, 254, 1) end
	end
	modem.close()
end

function RegistrationLevel(address, message)
	local file, line
	local user = serialization.unserialize(message)
	if 	unicode.len(user[1]) < 3 or unicode.len(user[1]) > 15  or
		unicode.len(user[2]) < 3 or unicode.len(user[2]) > 10  then
			modem.send(address, 255, "Имя должно быть от 3 до 15 символов\nПароль должен быть от 3 до 10 символов")
	else
		file = io.open("users", "a")
		io.output(file)
		while true do
			line = file:read()
			file:read()
			if user[1] == line then
				modem.send(address, 255, "Пользователь с таким именем уже существует")
				break
			end		
			if line == nil then
				local newUser = string.format("%s\n%s\n", user[1], user[2])
				io.input(file)
				file:seek("end")
				file:write(newUser)
				modem.send(address, 255, 1)		
				break
			end 	
		end
		file:close(file)
	end
end

function AuthenticationLevel(address, message)
	local line
	local user = serialization.unserialize(message)
	local file = io.open("users", "r")
	io.output(file)
	file:seek("set")
	while true do
		line = file:read()
		if user[1] == line then
			line = file:read()
			if user[2] == line then 				
				modem.send(address, 256, primaryPort)	
			else 
				modem.send(address, 256, "Неверный пароль") 					
			end
			break
		end		
		if line == nil then 	
			modem.send(address, 256, "Пользователя с таким именем не существует")
			break
		end 		
	end
	file:close(file)
end

function PrimaryLevel(message)
	local check
	check = text.trim(message)
	if check ~= "" and string.len(message) < 128 then
		modem.broadcast(primaryPort, message)
	end
end

ModemSettings()
Manager()