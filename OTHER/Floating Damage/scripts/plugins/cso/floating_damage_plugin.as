//Unusable until TraceAttack and TakeDamage hooks are added

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor("Nero");
	g_Module.ScriptInfo.SetContactInfo( "https://discord.gg/0wtJ6aAd7XOGI6vI" );

	//g_Hooks.RegisterHook( Hooks::Game::EntityTakedamage, @cso_fldamage::EntityTakedamage );
	//g_Hooks.RegisterHook( Hooks::Game::EntityTraceAttack, @cso_fldamage::EntityTraceAttack );
}

namespace cso_fldamage
{

/*HookReturnCode EntityTakedamage( DamageInfo@ pDamageInfo )
{
	g_Game.AlertMessage( at_notice, "[TAKEDAMAGE] pVictim: %1\n", pDamageInfo.pVictim.GetClassname()  );
	g_Game.AlertMessage( at_notice, "[TAKEDAMAGE] Damage Type: %1\n", pDamageInfo.bitsDamageType );
	g_Game.AlertMessage( at_notice, "[TAKEDAMAGE] Damage Amount: %1\n", pDamageInfo.flDamage );
	g_Game.AlertMessage( at_notice, "[TAKEDAMAGE] pAttacker: %1\n", pDamageInfo.pAttacker.GetClassname() );
	g_Game.AlertMessage( at_notice, "[TAKEDAMAGE] pInflictor: %1\n", pDamageInfo.pInflictor.GetClassname() );

	return HOOK_CONTINUE;
}

HookReturnCode EntityTraceAttack( entvars_t@ pevAttacker, entvars_t@ pevVictim,, float flDamage, const Vector& in vecDir, TraceResult& in traceResult, int bitsDamageType )
{
	if( flDamage > 0 and pev.deadflag == DEAD_NO )
		SpawnFloatingDamage( g_EntityFuncs.Instance(pevAttacker), g_EntityFuncs.Instance(pevVictim), pevVictim.origin, flDamage, (traceResult.iHitgroup == HITGROUP_HEAD) );

	return HOOK_CONTINUE;
}*/

} //namespace cso_fldamage END