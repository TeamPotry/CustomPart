/*
||||****|||**||||**||||****|||*******|||||****|||||***|||||***|||||||||||||||
||**|||||||**||||**||***|||||||||*||||||**||||**|||**|*|||*|**|||||||||||||||
||**|||||||**||||**||||****||||||*||||||**||||**|||**||*|*||**|||||||||||||||
||||****||||******|||***|||||||||*||||||||****|||||**|||*|||**|||||||||||||||

|||||||||||||||||||||******||||||||*|||||****|||||*******||||||||||||||||||||
|||||||||||||||||||||**||||**|||||*|*||||**||**||||||*|||||||||||||||||||||||
|||||||||||||||||||||******||||||*****|||****||||||||*|||||||||||||||||||||||
|||||||||||||||||||||**|||||||||*||||*|||**||**||||||*|||||||||||||||||||||||

Core Plugin By Nopied◎
*/

//

#include <sourcemod>
#include <morecolors>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <custompart>

#include "custompart/global_var.sp"

#include "custompart/stocks.sp"
#include "custompart/menu.sp"
#include "custompart/part_stocks.sp"

#include "custompart/natives.sp"

#define PLUGIN_NAME "CustomPart Core"
#define PLUGIN_AUTHOR "Nopied◎"
#define PLUGIN_DESCRIPTION "Yup. Yup."
#define PLUGIN_VERSION "Dev"

public Plugin myinfo = {
  name=PLUGIN_NAME,
  author=PLUGIN_AUTHOR,
  description=PLUGIN_DESCRIPTION,
  version=PLUGIN_VERSION,
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, err_max)
{
    CreateNative("CP_GetClientPart", Native_GetClientPart);
    CreateNative("CP_SetClientPart", Native_SetClientPart);
    CreateNative("CP_IsPartActived", Native_IsPartActived);
    CreateNative("CP_RefrashPartSlotArray", Native_RefrashPartSlotArray);
    CreateNative("CP_IsValidPart", Native_IsValidPart);
    CreateNative("CP_IsValidSlot", Native_IsValidSlot);
    CreateNative("CP_GetPartPropInfo", Native_GetPartPropInfo);
    CreateNative("CP_SetPartPropInfo", Native_SetPartPropInfo);
    CreateNative("CP_PropToPartProp", Native_PropToPartProp);
    CreateNative("CP_GetClientMaxSlot", Native_GetClientMaxslot);
    CreateNative("CP_SetClientMaxSlot", Native_SetClientMaxslot);
    CreateNative("CP_ReplacePartSlot", Native_ReplacePartSlot);
    CreateNative("CP_FindActiveSlot", Native_FindActiveSlot);
    CreateNative("CP_NoticePart", Native_NoticePart);
    CreateNative("CP_GetClientActiveSlotDuration", Native_GetClientActiveSlotDuration);
    CreateNative("CP_SetClientActiveSlotDuration", Native_SetClientActiveSlotDuration);
    CreateNative("CP_GetClientTotalCooldown", Native_GetClientTotalCooldown);
    CreateNative("CP_GetClientPartCharge", Native_GetClientPartCharge);
    CreateNative("CP_SetClientPartCharge", Native_SetClientPartCharge);
    CreateNative("CP_GetClientPartMaxChargeDamage", Native_GetClientPartMaxChargeDamage);
    CreateNative("CP_SetClientPartMaxChargeDamage", Native_SetClientPartMaxChargeDamage);
    CreateNative("CP_AddClientPartCharge", Native_AddClientPartCharge);
    CreateNative("CP_FindPart", Native_FindPart);
    CreateNative("CP_IsEnabled", Native_IsEnabled);
    CreateNative("CP_RandomPart", Native_RandomPart);
    CreateNative("CP_RandomPartRank", Native_RandomPartRank);
    CreateNative("CP_GetClientCPFlags", Native_GetClientCPFlags);
    CreateNative("CP_SetClientCPFlags", Native_SetClientCPFlags);

    Init_ConfigNatives();
    Init_Forwards();

    return APLRes_Success;
}

public void OnPluginStart()
{
      cvarChatCommand = CreateConVar("cp_chatcommand", "파츠,part,스킬");

      cvarPropCount = CreateConVar("cp_prop_count", "3", "생성되는 프롭 갯수, 0은 생성을 안함", _, true, 0.0);
      cvarPropVelocity = CreateConVar("cp_prop_velocity", "250.0", "프롭 생성시 흩어지는 최대 속도, 설정한 범위 내로 랜덤으로 속도가 정해집니다.", _, true, 0.0);
      cvarPropForNoBossTeam = CreateConVar("cp_prop_for_team", "0", "0 혹은 1은 제한 없음, 2는 레드팀에게만, 3은 블루팀에게만. (생성도 포함됨.)", _, true, 0.0, true, 2.0);
      cvarPropSize = CreateConVar("cp_prop_size", "50.0", "캡슐 섭취 범위", _, true, 0.1);
      cvarPropCooltime = CreateConVar("cp_prop_cooltime", "1.0", "캡슐 섭취 쿨타임.", _, true, 0.1);
      cvarDebug = CreateConVar("cp_debug", "1", "", _, true, 0.0, true, 1.0);

      RegAdminCmd("slot", TestSlot, ADMFLAG_CHEATS, "");
      RegAdminCmd("givepart", GivePart, ADMFLAG_CHEATS, "");

      AddCommandListener(Listener_Say, "say");
      AddCommandListener(Listener_Say, "say_team");

      AddCommandListener(OnCallForMedic, "voicemenu");

      LoadTranslations("custompart");
      LoadTranslations("common.phrases");
      LoadTranslations("core.phrases");

      HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Pre);
      HookEvent("player_death", OnPlayerDeath);

      HookEvent("teamplay_round_start", OnRoundStart);
      HookEvent("teamplay_round_win", OnRoundEnd);

      AllPartPropCount = 0;
      CPHud = CreateHudSynchronizer();
      CPChargeHud = CreateHudSynchronizer();

      CreateTimer(0.1, ClientTimer, _, TIMER_REPEAT);
}

public Action OnRoundStart(Handle event, const char[] name, bool dont)
{ // FIXME: 라운드 종료 후 파츠 흭득 시 다음 라운드가 되어서 사용이 가능함.

    /*
    int ent = -1;

    float position[3];
    float velocity[3];

    while((ent = FindEntityByClassname(ent, "item_healthkit_*")) != -1)
    {
        GetEntPropVector(ent, Prop_Send, "m_vecOrigin", position);

        position[2] += GetRandomFloat(3.0, 15.0);
        int part = SpawnCustomPart(RandomPartRank(), position, velocity, false);

        if(IsValidEntity(part))
        {
            SetEntityMoveType(part, MOVETYPE_NONE);
        }
    }

    while((ent = FindEntityByClassname(ent, "item_ammopack_*")) != -1)
    {
        GetEntPropVector(ent, Prop_Send, "m_vecOrigin", position);

        position[2] += GetRandomFloat(3.0, 15.0);
        int part = SpawnCustomPart(RandomPartRank(), position, velocity, false);

        if(IsValidEntity(part))
        {
            SetEntityMoveType(part, MOVETYPE_NONE);
        }
    }
    */
}

public Action OnRoundEnd(Handle event, const char[] name, bool dont)
{
    CPClientPartSlot clientPartslot;

    for(int client = 1; client <= MaxClients; client++)
    {
        if(IsClientInGame(client)) // TODO: 동일한 역할들을 묶어놓기.
        {
            clientPartslot = g_hClientInfo[client].PartSlot;
            clientPartslot.RefrashSlot(false);

            g_hClientInfo[client].MaxSlotCount = MaxPartGlobalSlot;
            g_hClientInfo[client].Charge = 0.0;
            g_hClientInfo[client].ActiveCooldown = -1.0;
            g_hClientInfo[client].MaxChargeDamage = 0.0;
        }
    }
}

public Action ClientTimer(Handle timer)
{
    int target;
    char HudMessage[200], partName[100];
    CPPart part;
    bool hasActivePart = false;
    float duration;

    if(CheckRoundState() != 1)
        return Plugin_Continue;

    for(int client = 1; client <= MaxClients; client++)
    {
        hasActivePart = false;
        if(!IsClientInGame(client)) continue;

        if(IsClientHaveDuration(client))
        {
            Action action;
            float tempDuration;

            for(int count = 0; count < g_hClientInfo[client].MaxSlotCount; count++)
            {
                duration = GetClientActiveSlotDuration(client, count);
                part = GetClientPart(client, count);
                if(duration > 0.0)
                {
                    duration -= 0.1;
                    tempDuration = duration;

                    if(part != null)
                    {
                        action = Forward_OnActivedPartTime(client, part, tempDuration);
                        if(action == Plugin_Changed)
                        {
                            duration = tempDuration;
                        }
                        else if(action == Plugin_Handled || action == Plugin_Stop)
                        {
                            continue;
                        }
                    }

                    SetClientActiveSlotDuration(client, count, duration);

                    if(duration <= 0.0)
                    {
                        Forward_OnActivedPartEnd(client, GetClientPart(client, count));
                    }

                    /*


                        duration = GetClientActiveSlotDuration(client, count);

                        if(duration <= 0.0)
                        {
                            Forward_OnActivedPartEnd(client, GetClientPart(client, count));
                        }
                    */
                }

            }
        }
        else if(g_hClientInfo[client].ActiveCooldown <= 0.0)
        {
            if(g_hClientInfo[client].ActiveCooldown <= 0.0)
            {
                Forward_OnClientCooldownEnd(client);
            }
        }

        if(!(CPFlags[client] & CPFLAG_DISABLE_HUD))
        {
            SetHudTextParams(0.7, 0.1, 0.12, 255, 228, 0, 185);

            if(IsPlayerAlive(client))
            {
                target = client;
                Format(HudMessage, sizeof(HudMessage), "활성화된 파츠: (최대 슬릇: %i)", g_hClientInfo[target].MaxSlotCount);
            }
            else
            {
                target = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
                if(IsValidClient(target))
                    Format(HudMessage, sizeof(HudMessage), "관전 중인 상대 파츠: (최대 슬릇: %i)", g_hClientInfo[target].MaxSlotCount);
            }

            if(IsValidClient(target))
            {
                int partcount = 0;
                for(int count = 0; count < g_hClientInfo[target].MaxSlotCount; count++)
                {
                    if(g_hClientInfo[target].IsValidSlot(count))
                    {
                        part = GetClientPart(target, count);

                        if(part == null)
                            continue;

                        if((part.KeyValue).IsPartActive())
                            hasActivePart = true;

                        if(partcount <= 5)
                        {
                            (part.KeyValue).GetValue("name", partName, sizeof(partName), client);
                            Format(HudMessage, sizeof(HudMessage), "%s\n%s", HudMessage, partName);
                        }

                        partcount++;
                    }
                }
                if(partcount > 5)
                {
                    Format(HudMessage, sizeof(HudMessage), "%s\n.. 그 외 %i개!", HudMessage, partcount - 5);
                }
                ShowSyncHudText(client, CPHud, HudMessage);

                // Charge Hud

                if(hasActivePart)
                {
                    SetHudTextParams(-1.0, 0.76, 0.12, 255, 228, 0, 185);

                    int ragemeter = RoundFloat(g_hClientInfo[target].Charge * (g_hClientInfo[target].MaxChargeDamage * 0.01));

                    if(IsClientHaveDuration(target))
                    {
                        int activeCount = 0;

                        for(int count = 0; count < g_hClientInfo[target].MaxSlotCount; count++)
                        {
                            if(GetClientActiveSlotDuration(target, count) > 0.0)
                            {
                                part = GetClientPart(target, count);
                                if(part == null)
                                    continue;

                                PartKV.GetPartString(part, "name", partName, sizeof(partName), client);
                                if(activeCount == 0)
                                {
                                    Format(HudMessage, sizeof(HudMessage), "%s: %.1f", partName, GetClientActiveSlotDuration(target, count));
                                }
                                else if(activeCount < 2)
                                {
                                    Format(HudMessage, sizeof(HudMessage), "%s | %s: %.1f", HudMessage, partName, GetClientActiveSlotDuration(target, count));
                                }

                                activeCount++;
                            }
                        }

                        if(activeCount > 2)
                        {
                            Format(HudMessage, sizeof(HudMessage), "%s 그 외 %i개!", HudMessage, activeCount - 2);
                        }
                    }
                    else if(GetClientPartCooldown(target) > 0.0)
                    {
                        Format(HudMessage, sizeof(HudMessage), "액티브 파츠 쿨타임: %.1f", GetClientPartCooldown(target));
                    }
                    else
                    {
                        if(client == target)
                        {
                            if(g_hClientInfo[target].Charge >= 100.0)
                            {
                                Format(HudMessage, sizeof(HudMessage), "메딕을 불러 능력을 발동시키세요!");
                            }
                            else
                            {
                                Format(HudMessage, sizeof(HudMessage), "액티브 파츠 충전: %i%% / 100%% (%i / %i)", RoundFloat(g_hClientInfo[target].Charge), ragemeter, RoundFloat(g_hClientInfo[target].MaxChargeDamage));
                            }
                        }
                        else
                        {
                            Format(HudMessage, sizeof(HudMessage), "%N님의 액티브 파츠 충전: %i%% / 100%% (%i / %i)", target, RoundFloat(g_hClientInfo[target].Charge), ragemeter, RoundFloat(g_hClientInfo[target].MaxChargeDamage));
                        }
                    }
                    ShowSyncHudText(client, CPChargeHud, HudMessage);
                }
            }
        }
    }

    return Plugin_Continue;
}

public Action OnCallForMedic(int client, const char[] command, int args)
{
    if(CheckRoundState() != 1 && IsClientInGame(client) && IsPlayerAlive(client))
        return Plugin_Continue;

    char arg1[4]; char arg2[4];
    GetCmdArg(1, arg1, sizeof(arg1));
    GetCmdArg(2, arg2, sizeof(arg2));
    if(StringToInt(arg1) || StringToInt(arg2))  //We only want "voicemenu 0 0"-thanks friagram for pointing out edge cases
    {
        return Plugin_Continue;
    }

    if(!g_hClientInfo[client].IsHaveActivePart()) return Plugin_Continue;

    if(g_hClientInfo[client].Charge >= 100.0 && !IsClientHaveDuration(client) && GetClientPartCooldown(client) <= 0.0)
    {
        g_hClientInfo[client].Charge = 0.0;
        g_hClientInfo[client].ActiveCooldown = GetClientTotalCooldown(client);
        Action action;

        for(int count=0; count < g_hClientInfo[client].MaxSlotCount; count++)
        {
            CPPart part = GetClientPart(client, count);
            if((part.KeyValue).IsPartActive())
            {
                action = Forward_PreActivePart(client, part);
                if(action == Plugin_Handled)
                    continue;

                SetClientActiveSlotDuration(client, count, PartKV.GetActivePartDuration(part));
                Forward_OnActivedPart(client, part);
            }
        }
    }
    else
    {
        CPrintToChat(client, "{yellow}[CP]{default} 지금은 사용하실 수 없습니다.");
    }
    return Plugin_Continue;
}

public Action TestSlot(int client, int args)
{
    CPClientPartSlot clientPartSlot = g_hClientInfo[client].PartSlot;
    CPPart part;

    CPrintToChatAll("%N's slot. size = %i, MaxPartSlot = %i", client, clientPartSlot.Length, g_hClientInfo[client].MaxSlotCount);

    for(int count = 0; count < g_hClientInfo[client].MaxSlotCount; count++)
    {
        part = clientPartSlot.GetPart(count);
        CPrintToChatAll("[%i] %i", count, part.Index);
        CPrintToChatAll("[%i] 지속시간: %.1f", count, part.Duration);
    }
    CPrintToChatAll("쿨타임: %.1f", g_hClientInfo[client].ActiveCooldown);
}

public void OnEntityDestroyed(int entity)
{
    if(entity >= 0)
    {
        if(PartPropRank[entity] > Rank_None)
            AllPartPropCount--;

        PartPropRank[entity] = Rank_None;
        PartPropCustomIndex[entity] = 0;
    }
}

public void OnMapStart()
{
    ChangeChatCommand();
    CheckPartConfigFile();
    CreateTimer(0.2, PrecacheTimer);

    for(int client = 1; client <= MaxClients; client++)
    {
        CPFlags[client] = 0;

        if(g_hClientInfo[client] != null)
            g_hClientInfo[client].KillSelf();
    }
}

void ChangeChatCommand()
{
	g_iChatCommand = 0;

	char cvarV[100];
	GetConVarString(cvarChatCommand, cvarV, sizeof(cvarV));

	for (int i = 0; i < ExplodeString(cvarV, ",", g_strChatCommand, sizeof(g_strChatCommand), sizeof(g_strChatCommand[])); i++)
	{
		LogMessage("[CP] Added chat command: %s", g_strChatCommand[i]);
		g_iChatCommand++;
	}
}

public OnClientPostAdminCheck(int client)
{
    g_hClientInfo[client] = new CPClient(client, MaxPartGlobalSlot);
    g_hClientInfo[client].MaxSlotCount = MaxPartGlobalSlot;

    if(enabled)
    {
        SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
    }
}

public void OnClientDisconnect(int client)
{
    if(enabled) // 아마도 될껄?
    {
        CPClientPartSlot clientPartslot = g_hClientInfo[client].PartSlot;
        clientPartslot.RefrashSlot(false);
    }

    if(g_hClientInfo[client] != null)
        g_hClientInfo[client].KillSelf();

    SDKUnhook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
}

public Action OnPlayerSpawn(Handle event, const char[] name, bool dont)
{
    if(enabled) return Plugin_Continue;

    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    g_hClientInfo[client].GetCoolTime = 0.0;

    CPClientPartSlot clientPartslot = g_hClientInfo[client].PartSlot;
    clientPartslot.RefrashSlot(false);

    g_hClientInfo[client].MaxSlotCount = MaxPartGlobalSlot;
    g_hClientInfo[client].Charge = 0.0;
    g_hClientInfo[client].GetCoolTime = -1.0;
    g_hClientInfo[client].MaxChargeDamage = 0.0;

    return Plugin_Continue
}

public void OnTakeDamagePost(int client, int attacker, int inflictor, float damage, int damagetype)
{
    if(IsValidClient(client) && IsValidClient(attacker) && IsPlayerAlive(attacker) && client != attacker)
    {
        if(g_hClientInfo[attacker].MaxChargeDamage > 0.0)
        {
            float realDamage = damage;
            if(damagetype & DMG_CRIT)
                realDamage *= 3.0;

            g_hClientInfo[attacker].AddPartCharge(realDamage * 100.0 / g_hClientInfo[attacker].MaxChargeDamage);
        }
    }
}

public Action OnPlayerDeath(Handle event, const char[] name, bool dont)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    if(!enabled || !IsCorrectTeam(client) || CheckRoundState() != 1)
    {
        return Plugin_Continue;
    }

    bool IsFake = false;
    if(GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER)
        IsFake = true;

    for(int count = 0; count < GetConVarInt(cvarPropCount); count++)
    {
        float position[3];
        GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);

        float velocity[3];
        velocity[0] = GetRandomFloat(GetConVarFloat(cvarPropVelocity)*-0.5, GetConVarFloat(cvarPropVelocity)*0.5);
        velocity[1] = GetRandomFloat(GetConVarFloat(cvarPropVelocity)*-0.5, GetConVarFloat(cvarPropVelocity)*0.5);
        velocity[2] = GetRandomFloat(GetConVarFloat(cvarPropVelocity)*-0.5, GetConVarFloat(cvarPropVelocity)*0.5);
        NormalizeVector(velocity, velocity);

        SpawnCustomPart(RandomPartRank(), position, velocity, IsFake);
    }

    return Plugin_Continue;
}

bool ReplacePartSlot(int client, int beforePartIndex, int afterPartIndex)
{
    CPClientPartSlot clientPartslot = g_hClientInfo[client].PartSlot;

    if(clientPartslot.FindPart(beforePartIndex) != -1)
    {
        clientPartslot.SetPart(slot, PartKV.LoadPart(afterPartIndex));
        return true;
    }

    return false;
}

CPPart GetClientPart(int client, int slot)
{
    CPClientPartSlot clientPartslot = g_hClientInfo[client].PartSlot;

    if(g_hClientInfo[client].IsValidSlot(slot))
    {
        return clientPartslot.GetPart(slot);
    }

    return null;
}

void SetClientPart(int client, int slot, CPPart value) // return: 적용된 슬릇 값.
{
    if(!g_hClientInfo[client].IsValidSlot(slot)) return;

    CPClientPartSlot clientPartslot = g_hClientInfo[client].PartSlot;
    CPPart part = GetClientPart(client, slot);

    clientPartslot.SetPart(slot, value);

    if(PartKV.IsValidPart(part))
        Forward_OnActivedPartEnd(client, part.Index);
}

float GetClientTotalCooldown(int client)
{
    CPPart part;
    float totalCooldown;

    for(int count = 0; count < g_hClientInfo[client].MaxSlotCount; count++)
    {
        part = GetClientPart(client, count);

        if(g_hClientInfo[client].IsValidSlot(count) && PartKV.IsValidPart(part))
        {
            totalCooldown += PartKV.GetActivePartDuration(part);
        }
    }

    return totalCooldown;
}

float GetClientPartCooldown(int client)
{
    float cooldown = g_hClientInfo[client].ActiveCooldown;
    return cooldown > 0.0 ? cooldown : 0.0;
}

void SetClientPartCooldown(int client, float cooldown)
{
    g_hClientInfo[client].ActiveCooldown = cooldown;
}

float GetClientActiveSlotDuration(int client, int slot)
{
    CPClientPartSlot clientPartslot;
    CPPart part;

    if(g_hClientInfo[client].IsValidSlot(count))
    {
        clientPartslot = g_hClientInfo[client].PartSlot;
        part = GetClientPart(client, slot);

        if(part != null && part.Duration < 0.0)
        {
            part.Duration = 0.0;
        }

        return duration;
    }

    return -1.0;
}

void SetClientActiveSlotDuration(int client, int slot, float duration)
{
    CPClientPartSlot clientPartslot = g_hClientInfo[client].PartSlot;
    CPPart part = GetClientPart(client, slot);

    if(part != null)
        part.Duration = duration;
}

bool IsClientHaveDuration(int client)
{
    CPClientPartSlot clientPartslot = g_hClientInfo[client].PartSlot;
    CPPart part;

    for(int count = 0; count < g_hClientInfo[client].MaxSlotCount; count++)
    {
        part = GetClientPart(client, slot);

        if(g_hClientInfo[client].IsValidSlot(count))
        {
            if(ActivedDurationArray[client].Get(count) > 0.0)
                return true;
        }
    }

    return false;
}

public Native_GetClientPart(Handle plugin, int numParams)
{
    return GetClientPart(GetNativeCell(1), GetNativeCell(2));
}

public Native_SetClientPart(Handle plugin, int numParams)
{
    SetClientPart(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3));
}

public Native_IsPartActived(Handle plugin, int numParams)
{
    CPClientPartSlot clientPartslot = g_hClientInfo[GetNativeCell(1)].PartSlot;
    return view_as<int>(clientPartslot.IsPartActived(GetNativeCell(2)));
}

public Native_RefrashPartSlotArray(Handle plugin, int numParams)
{
    RefrashPartSlotArray(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3));
}

public Native_IsValidPart(Handle plugin, int numParams)
{
    return PartKV.IsValidPart(GetNativeCell(1));
}

public Native_IsValidSlot(Handle plugin, int numParams)
{
    return g_hClientInfo[GetNativeCell(1)].IsValidSlot(GetNativeCell(2));
}

public Native_GetPartPropInfo(Handle plugin, int numParams)
{
    return GetPartPropInfo(GetNativeCell(1), GetNativeCell(2));
}

public Native_SetPartPropInfo(Handle plugin, int numParams)
{
    SetPartPropInfo(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3), GetNativeCell(4));
}

public Native_PropToPartProp(Handle plugin, int numParams)
{
    PropToPartProp(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3), GetNativeCell(4), GetNativeCell(5), GetNativeCell(6));
}

public Native_GetClientMaxslot(Handle plugin, int numParams)
{
    return g_hClientInfo[GetNativeCell(1)].MaxSlotCount;
}

public Native_SetClientMaxslot(Handle plugin, int numParams)
{
    SetClientMaxSlot(GetNativeCell(1), GetNativeCell(2));
}

public Native_ReplacePartSlot(Handle plugin, int numParams)
{
    return ReplacePartSlot(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3));
}

public Native_FindActiveSlot(Handle plugin, int numParams)
{
    CPClientPartSlot clientPartslot = g_hClientInfo[GetNativeCell(1)].PartSlot;
    return clientPartslot.FindActiveSlot();
}

public Native_NoticePart(Handle plugin, int numParams)
{
    NoticePart(GetNativeCell(1), GetNativeCell(2));
}

public Native_GetClientActiveSlotDuration(Handle plugin, int numParams)
{
    return _:GetClientActiveSlotDuration(GetNativeCell(1), GetNativeCell(2));
}

public Native_SetClientActiveSlotDuration(Handle plugin, int numParams)
{
    SetClientActiveSlotDuration(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3));
}

public Native_GetClientTotalCooldown(Handle plugin, int numParams)
{
    return _:GetClientTotalCooldown(GetNativeCell(1));
}

public Native_GetClientPartCharge(Handle plugin, int numParams)
{
    return _:g_hClientInfo[GetNativeCell(1)].Charge;
}

public Native_SetClientPartCharge(Handle plugin, int numParams)
{
    g_hClientInfo[GetNativeCell(1)].Charge = GetNativeCell(2);
}

public Native_GetClientPartMaxChargeDamage(Handle plugin, int numParams)
{
    return _:g_hClientInfo[GetNativeCell(1)].MaxChargeDamage;
}

public Native_SetClientPartMaxChargeDamage(Handle plugin, int numParams)
{
    g_hClientInfo[GetNativeCell(1)].MaxChargeDamage = GetNativeCell(2);
}

public Native_AddClientPartCharge(Handle plugin, int numParams)
{
    g_hClientInfo[GetNativeCell(1)].AddPartCharge(GetNativeCell(2));
}

public Native_FindPart(Handle plugin, int numParams)
{
    CPClientPartSlot clientPartslot = g_hClientInfo[GetNativeCell(1)].PartSlot;
    return clientPartslot.FindPart(GetNativeCell(2));
}

public Native_IsEnabled(Handle plugin, int numParams)
{
    return enabled;
}

public Native_RandomPart(Handle plugin, int numParams)
{
    return _:PartKV.RandomPart(GetNativeCell(1), GetNativeCell(2));
}

public Native_RandomPartRank(Handle plugin, int numParams)
{
    return _:RandomPartRank(GetNativeCell(1));
}

public Native_GetClientCPFlags(Handle plugin, int numParams)
{
    return CPFlags[GetNativeCell(1)];
}

public Native_SetClientCPFlags(Handle plugin, int numParams)
{
     CPFlags[GetNativeCell(1)] = GetNativeCell(2);
}

void SetClientMaxSlot(int client, int maxSlot)
{
    g_hClientInfo[client].MaxSlotCount = maxSlot;

    RefrashPartSlotArray(client, true, true);
    // ActivedPartSlotArray[client].Resize(g_hClientInfo[client].MaxSlotCount);
    // ActivedDurationArray[client].Resize(g_hClientInfo[client].MaxSlotCount);
}

stock bool IsCorrectTeam(int client)
{
	if(PropForTeam != TFTeam_Red && PropForTeam != TFTeam_Blue)
		return true;

	return PropForTeam == TF2_GetClientTeam(client);
}

stock int IsEntityStuck(int entity) // Copied from Chdata's FFF
{/*
 	float vecMin[3], vecMax[3], vecOrigin[3];

    GetEntPropVector(entity, Prop_Send, "m_vecMins", vecMin);
    GetEntPropVector(entity, Prop_Send, "m_vecMaxs", vecMax);
    GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vecOrigin);

    TR_TraceHullFilter(vecOrigin, vecOrigin, vecMin, vecMax, MASK_SOLID, TraceRayPlayerOnly, entity);
    if(TR_DidHit())
	{
		return TR_GetEntityIndex();
	}
	return -1;
	*/
	float vecOrigin[3], playerOrigin[3];
	float propsize = GetConVarFloat(cvarPropSize);
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vecOrigin);

	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && IsPlayerAlive(client))
		{
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", playerOrigin);

			if(CheckCollision(vecOrigin, playerOrigin, propsize))
				return client;
		}
	}

	return -1;
}
