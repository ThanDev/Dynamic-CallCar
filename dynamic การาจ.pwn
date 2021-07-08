	// --> การาจ
	if (newkeys & KEY_NO)
	{
	    new idx = Callcar_Nearest(playerid);
	    if (idx != -1)
	    {
	    	Dialog_Show(playerid, DIALOG_GARAGE, DIALOG_STYLE_LIST, "{FFFFFF}[{F91D0F}การาจ{FFFFFF}]", "{FFFFFF}- เรียกรถ\n- เก็บรถ", "ตกลง", "ยกเลิก");
		}
	}


Callcar_Create(Float:x, Float:y, Float:z)
{
	for (new i = 0; i < MAX_CALLCAR; i ++) if (!callcarData[i][callcarExists])
	{
	    callcarData[i][callcarExists] = true;
	    callcarData[i][callcarPosX] = x;
	    callcarData[i][callcarPosY] = y;
	    callcarData[i][callcarPosZ] = z;

	    mysql_tquery(g_SQL, "INSERT INTO `callcar` (`callcarID`) VALUES(0)", "OnCallcarCreated", "d", i);
		Callcar_Refresh(i);
		return i;
	}
	return -1;
}

Callcar_Save(pumpid)
{
	static
	    query[220];

	mysql_format(g_SQL, query, sizeof(query), "UPDATE `callcar` SET `callcarX` = '%.4f', `callcarY` = '%.4f', `callcarZ` = '%.4f' WHERE `callcarID` = '%d'",
	    callcarData[pumpid][callcarPosX],
	    callcarData[pumpid][callcarPosY],
	    callcarData[pumpid][callcarPosZ],
	    callcarData[pumpid][callcarID]
	);
	return mysql_tquery(g_SQL, query);
}

Callcar_Refresh(pumpid)
{
	if (pumpid != -1 && callcarData[pumpid][callcarExists])
	{
		if (IsValidDynamicPickup(callcarData[pumpid][callcarPickup]))
		    DestroyDynamicPickup(callcarData[pumpid][callcarPickup]);

		if (IsValidDynamic3DTextLabel(callcarData[pumpid][callcarText3D]))
		    DestroyDynamic3DTextLabel(callcarData[pumpid][callcarText3D]);

		callcarData[pumpid][callcarPickup] = CreateDynamicPickup(1318, 23, callcarData[pumpid][callcarPosX], callcarData[pumpid][callcarPosY], callcarData[pumpid][callcarPosZ]);
  		callcarData[pumpid][callcarText3D] = CreateDynamic3DTextLabel("{09F566}[การาจเรียกรถ]\n{FFFFFF}กด 'N' เพื่อเรียกรถและเก็บรถ", COLOR_GREEN, callcarData[pumpid][callcarPosX], callcarData[pumpid][callcarPosY], callcarData[pumpid][callcarPosZ], 5.0, INVALID_VEHICLE_ID, INVALID_PLAYER_ID, 0);
	}
	return 1;
}
Callcar_Nearest(playerid)
{
    for (new i = 0; i != MAX_CALLCAR; i ++) if (callcarData[i][callcarExists] && IsPlayerInRangeOfPoint(playerid, 4.0, callcarData[i][callcarPosX], callcarData[i][callcarPosY], callcarData[i][callcarPosZ]))
	{
		return i;
	}
	return -1;
}

// --> เรียกรถ
alias:callcar("เรียกรถ")
CMD:callcar(playerid, params[])
{
	// --> เรียกรถการาจ
	new id = Callcar_Nearest(playerid);

	if (id == -1)
		return SendClientMessage(playerid, COLOR_RED, "[ระบบ] {FFFFFF}คุณไม่ได้อยู่จุดเรียกรถใด ๆ");

	new
		count,
		string[1024],
		string2[1024],
		var[11];

	for (new i = 0; i < MAX_CARS; i ++)
	{
		if (Car_IsOwner(playerid, i))
		{
		    GetVehicleHealth(i,carData[i][carHealth]);

			new mecMessage[512];
			if(carData[i][carHealth] < 400) { mecMessage = "{FFFFFF}[{F94031}ใช้งานไม่ได้{FFFFFF}]"; }
			else { mecMessage = "{FFFFFF}[{BFF508}สามารถใช้งานได้{FFFFFF}]"; }

			format(string, sizeof(string), "{70F905}%s\t%s\n", ReturnVehicleModelName(carData[i][carModel]), mecMessage);
			strcat(string2, string);
			count++;
			format(var, sizeof(var), "PvCarID%d", count);
			SetPVarInt(playerid, var, i);
		}
	}

	if (!count) {
		SendClientMessage(playerid, COLOR_LIGHTRED, "[รถส่วนตัว] {FFFFFF}คุณไม่มีรถส่วนตัวเลย");
		return 1;
	}
	format(string, sizeof(string), "{70F905}ชื่อรุ่น\t{FFFFFF}สถานะยานพาหนะ\n%s", string2);
	Dialog_Show(playerid, DIALOG_CALLVEH, DIALOG_STYLE_TABLIST_HEADERS, "{70F905}(รายชื่อรถส่วนตัวของคุณ)", string, "เลือก", "ปิด");
	return 1;
}

// --> การาจเรียกรถ

CMD:createcallcar(playerid, params[])
{
	static
	    id = -1,
		Float:x,
		Float:y,
		Float:z;

	GetPlayerPos(playerid, x, y, z);

    if (playerData[playerid][pAdmin] < 5)
	    return 1;

	if (GetPlayerInterior(playerid) != 0)
	    return 1;

	id = Callcar_Create(x, y, z);

	if (id == -1)
	    return SendClientMessage(playerid, COLOR_RED, "[ระบบ] {FFFFFF}ความจุของการาจเรียกรถในฐานข้อมูลเต็มแล้ว ไม่สามารถสร้างได้อีก (ติดต่อผู้พัฒนา)");

	SendClientMessageEx(playerid, COLOR_SERVER, "คุณได้สร้างการาจเรีกยรถขึ้นมาใหม่ ไอดี: %d", id);
	return 1;
}

CMD:deletecallcar(playerid, params[])
{
	static
	    id = 0;

    if (playerData[playerid][pAdmin] < 5)
	    return 1;

	if (sscanf(params, "d", id))
	    return SendClientMessage(playerid, COLOR_WHITE, "การใช้งาน : /deletecallcar [ไอดี]");

	if ((id < 0 || id >= MAX_CALLCAR) || !callcarData[id][callcarExists])
	    return SendClientMessage(playerid, COLOR_RED, "[ระบบ] {FFFFFF}ไม่มีไอดีการาจเรียกรถนี้อยู่ในฐานข้อมูล");

	Callcar_Delete(id);
	SendClientMessageEx(playerid, COLOR_SERVER, "คุณได้ลบปั้มการาจเรียกรถไอดี %d ออกสำเร็จ", id);
	return 1;
}
// --> การาจ
Dialog:DIALOG_GARAGE(playerid, response, listitem, inputtext[])
{
	if(response)
	{
		switch(listitem)
  		{
			case 0: Dialog_Show(playerid, DIALOG_TYPE_CALLVEH, DIALOG_STYLE_LIST, "{70F905}(การาจเรียกรถ)", "{FFFFFF}- รถส่วนตัว\n- รถโดเนทแบบแต่ง", "เลือก", "ปิด");
			case 1:
			{
				new idg, vehicleid = GetPlayerVehicleID(playerid);

				if ((idg = Car_Inside(playerid)) != -1)
				{
		  			if (Car_IsOwner(playerid, idg))
			    	{
	      				Car_Save(playerData[playerid][pVehicleCall]);
						DestroyVehicle(playerData[playerid][pVehicleCall]);
						playerData[playerid][pVehicleCall] = -1;
						SendClientMessage(playerid, COLOR_GREY, "คุณได้เก็บรถเข้า Garage เรียบร้อยแล้ว");
						return 1;
					}
				}

			    if (CallVehicle[playerid] == vehicleid)
			    {
					DestroyVehicle(CallVehicle[playerid]);
					CallVehicle[playerid] = -1;
					SendClientMessage(playerid, COLOR_GREY, "คุณได้เก็บรถเข้า Garage เรียบร้อยแล้ว");
					return 1;
			    }

				else return SendClientMessage(playerid, COLOR_LIGHTRED, "คุณต้องอยู่บนรถเท่านั้น");
			}
		}
	}
	return 1;
}
Car_GetCount(playerid)
{
	new
		count = 0;

	for (new i = 0; i != MAX_CARS; i ++)
	{
		if (carData[i][carExists] && carData[i][carOwner] == playerData[playerid][pID])
   		{
   		    count++;
		}
	}
	return count;
}

Car_SaveFuel(carid)
{
	static
	    query[65];

	mysql_format(g_SQL, query, sizeof(query), "UPDATE `cars` SET `carFuel` = '%.1f' WHERE `carID` = '%d'",
		carData[carid][carFuel],
		carData[carid][carID]
	);
	return mysql_tquery(g_SQL, query);
}

Car_Inside(playerid)
{
	new carid;

	if (IsPlayerInAnyVehicle(playerid) && (carid = Car_GetID(GetPlayerVehicleID(playerid))) != -1)
	    return carid;

	return -1;
}

Car_Nearest(playerid)
{
	static
	    Float:fX,
	    Float:fY,
	    Float:fZ;

	for (new i = 0; i != MAX_CARS; i ++)
	{
		if (carData[i][carExists])
		{
			GetVehiclePos(carData[i][carVehicle], fX, fY, fZ);

			if (IsPlayerInRangeOfPoint(playerid, 3.0, fX, fY, fZ))
			{
				return i;
			}
		}
	}
	return -1;
}

Car_IsOwner(playerid, carid)
{
	if (!playerData[playerid][IsLoggedIn] || playerData[playerid][pID] == -1)
	    return 0;

    if ((carData[carid][carExists] && carData[carid][carOwner] != 0) && carData[carid][carOwner] == playerData[playerid][pID])
 {
		return 1;
	}

	return 0;
}

Car_GetID(vehicleid)
{
	for (new i = 0; i != MAX_CARS; i ++)
	{
		if (carData[i][carExists] && carData[i][carVehicle] == vehicleid)
		{
	    	return i;
		}
	}
	return -1;
}

