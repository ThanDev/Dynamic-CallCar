	// --> ���Ҩ
	if (newkeys & KEY_NO)
	{
	    new idx = Callcar_Nearest(playerid);
	    if (idx != -1)
	    {
	    	Dialog_Show(playerid, DIALOG_GARAGE, DIALOG_STYLE_LIST, "{FFFFFF}[{F91D0F}���Ҩ{FFFFFF}]", "{FFFFFF}- ���¡ö\n- ��ö", "��ŧ", "¡��ԡ");
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
  		callcarData[pumpid][callcarText3D] = CreateDynamic3DTextLabel("{09F566}[���Ҩ���¡ö]\n{FFFFFF}�� 'N' �������¡ö�����ö", COLOR_GREEN, callcarData[pumpid][callcarPosX], callcarData[pumpid][callcarPosY], callcarData[pumpid][callcarPosZ], 5.0, INVALID_VEHICLE_ID, INVALID_PLAYER_ID, 0);
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

// --> ���¡ö
alias:callcar("���¡ö")
CMD:callcar(playerid, params[])
{
	// --> ���¡ö���Ҩ
	new id = Callcar_Nearest(playerid);

	if (id == -1)
		return SendClientMessage(playerid, COLOR_RED, "[�к�] {FFFFFF}�س���������ش���¡ö� �");

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
			if(carData[i][carHealth] < 400) { mecMessage = "{FFFFFF}[{F94031}��ҹ�����{FFFFFF}]"; }
			else { mecMessage = "{FFFFFF}[{BFF508}����ö��ҹ��{FFFFFF}]"; }

			format(string, sizeof(string), "{70F905}%s\t%s\n", ReturnVehicleModelName(carData[i][carModel]), mecMessage);
			strcat(string2, string);
			count++;
			format(var, sizeof(var), "PvCarID%d", count);
			SetPVarInt(playerid, var, i);
		}
	}

	if (!count) {
		SendClientMessage(playerid, COLOR_LIGHTRED, "[ö��ǹ���] {FFFFFF}�س�����ö��ǹ������");
		return 1;
	}
	format(string, sizeof(string), "{70F905}�������\t{FFFFFF}ʶҹ��ҹ��˹�\n%s", string2);
	Dialog_Show(playerid, DIALOG_CALLVEH, DIALOG_STYLE_TABLIST_HEADERS, "{70F905}(��ª���ö��ǹ��Ǣͧ�س)", string, "���͡", "�Դ");
	return 1;
}

// --> ���Ҩ���¡ö

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
	    return SendClientMessage(playerid, COLOR_RED, "[�к�] {FFFFFF}�����آͧ���Ҩ���¡ö㹰ҹ������������� �������ö���ҧ���ա (�Դ��ͼ��Ѳ��)");

	SendClientMessageEx(playerid, COLOR_SERVER, "�س�����ҧ���Ҩ��ա�ö��������� �ʹ�: %d", id);
	return 1;
}

CMD:deletecallcar(playerid, params[])
{
	static
	    id = 0;

    if (playerData[playerid][pAdmin] < 5)
	    return 1;

	if (sscanf(params, "d", id))
	    return SendClientMessage(playerid, COLOR_WHITE, "�����ҹ : /deletecallcar [�ʹ�]");

	if ((id < 0 || id >= MAX_CALLCAR) || !callcarData[id][callcarExists])
	    return SendClientMessage(playerid, COLOR_RED, "[�к�] {FFFFFF}������ʹա��Ҩ���¡ö�������㹰ҹ������");

	Callcar_Delete(id);
	SendClientMessageEx(playerid, COLOR_SERVER, "�س��ź�������Ҩ���¡ö�ʹ� %d �͡�����", id);
	return 1;
}
// --> ���Ҩ
Dialog:DIALOG_GARAGE(playerid, response, listitem, inputtext[])
{
	if(response)
	{
		switch(listitem)
  		{
			case 0: Dialog_Show(playerid, DIALOG_TYPE_CALLVEH, DIALOG_STYLE_LIST, "{70F905}(���Ҩ���¡ö)", "{FFFFFF}- ö��ǹ���\n- ö�๷Ẻ��", "���͡", "�Դ");
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
						SendClientMessage(playerid, COLOR_GREY, "�س����ö��� Garage ���º��������");
						return 1;
					}
				}

			    if (CallVehicle[playerid] == vehicleid)
			    {
					DestroyVehicle(CallVehicle[playerid]);
					CallVehicle[playerid] = -1;
					SendClientMessage(playerid, COLOR_GREY, "�س����ö��� Garage ���º��������");
					return 1;
			    }

				else return SendClientMessage(playerid, COLOR_LIGHTRED, "�س��ͧ���躹ö��ҹ��");
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

