//Based on AMXX plugin "Floating Damage" by Yoshioka Haruki

namespace cso
{

const int iFloatingDamageSkin = 0; //0-18 only put even numbers here, odd numbers are for crits (headshots)
const bool bCumulativeDamage = false;

const string MODEL_FLDAMAGE = "models/cso/floating_damage.mdl";
const bool bEnableFDRotation = true;

void SpawnFloatingDamage( CBaseEntity@ pAttacker, CBaseEntity@ pVictim, Vector vecOrigin, float flDamage, bool bHeadShot )
{
	int iDamagerSkin = iFloatingDamageSkin;
	if( iDamagerSkin != 0 ) iDamagerSkin *= 2;
	if( bHeadShot )
	{
		iDamagerSkin += 1;
		flDamage *= g_EngineFuncs.CVarGetFloat( "sk_monster_head" );
	}

	CBaseEntity@ pEntity = null;

	if( bCumulativeDamage )
	{
		@pEntity = FindActiveEntity( pAttacker, pVictim );
		if( pEntity !is null )
		{
			if( pVictim !is null )
				GetPosition( pAttacker, pVictim, vecOrigin, vecOrigin );

			g_EntityFuncs.SetOrigin( pEntity, vecOrigin );

			cso_fldamage@ pDamageEnt = cast<cso_fldamage@>(CastToScriptClass(pEntity));

			vecOrigin = pDamageEnt.m_vecStartVelocity;
			pDamageEnt.pev.velocity = vecOrigin;

			vecOrigin = pAttacker.pev.v_angle;
			vecOrigin.y -= 180.0;
			pDamageEnt.pev.angles = vecOrigin;

			// Update total damage
			flDamage += pDamageEnt.pev.dmg;
		
			pDamageEnt.pev.dmg = flDamage;

			pDamageEnt.pev.sequence = 0;
			pDamageEnt.pev.renderamt = 255.0;
			pDamageEnt.pev.nextthink = g_Engine.time + 0.3;
			pDamageEnt.pev.skin = iDamagerSkin;
			pDamageEnt.pev.body = PrepareBody( flDamage );

			return;
		}
	}

	@pEntity = g_EntityFuncs.Create( "cso_fldamage", vecOrigin, g_vecZero, false, pAttacker.edict() );
	cso_fldamage@ pDamageEntNew = cast<cso_fldamage@>(CastToScriptClass(pEntity));
	if( pDamageEntNew is null )
		return;

	if( pVictim !is null )
		GetPosition( pAttacker, pVictim, vecOrigin, vecOrigin );
	//else
	{
		vecOrigin.x += Math.RandomFloat( -8.0, 8.0 );
		vecOrigin.y += Math.RandomFloat( -8.0, 8.0 );
		vecOrigin.z += 16.0;
	}

	Vector vecTemp = vecOrigin;

	Vector vecVelocity;
	vecTemp.z += 64.0;
	GetSpeedVector( vecOrigin, vecTemp, 0.0, 1.0, vecVelocity );
	pDamageEntNew.pev.velocity = vecVelocity;

	g_EntityFuncs.SetOrigin( pDamageEntNew.self, vecOrigin );

	pDamageEntNew.m_hMonster = EHandle( pVictim );
	pDamageEntNew.pev.skin = iDamagerSkin;
	pDamageEntNew.pev.body = PrepareBody( flDamage );

	pDamageEntNew.m_vecStartVelocity = vecVelocity;
	pDamageEntNew.pev.dmg = flDamage;
	pDamageEntNew.pev.scale = GetScaleForMonster( pVictim, 1.0, 0.13, 3.0 );

/*
#if defined _reapi_included
	set_entvar( pDamageEntNew, var_effects, get_entvar( pDamageEntNew, var_effects ) | EF_OWNER_VISIBILITY );
#else*/
	//set_entvar( pDamageEntNew, var_groupinfo, BIT( pAttacker ) );
	//pDamageEntNew.pev.groupinfo |= pAttacker.entindex(); //??

	vecTemp = pAttacker.pev.v_angle;
	vecTemp.y -= 180.0;
	pDamageEntNew.pev.angles = vecTemp;
}

CBaseEntity@ FindActiveEntity( CBaseEntity@ pAttacker, CBaseEntity@ pVictim )
{
	if( pVictim is null )
		return null;

	cso_fldamage@ pDamageEnt = null;
	CBaseEntity@ pEntity = null;
	
	while( (@pEntity = g_EntityFuncs.FindEntityByClassname(pEntity, "cso_fldamage")) !is null )
	{
		if( pEntity.pev.owner is null or pEntity.pev.owner !is pAttacker.edict() )
			continue;

		@pDamageEnt = cast<cso_fldamage@>(CastToScriptClass(pEntity));
		if( pDamageEnt is null or !pDamageEnt.m_hMonster.IsValid() or pDamageEnt.m_hMonster.GetEntity() !is pVictim )
			continue;

		//g_Game.AlertMessage( at_notice, "FindActiveEntity called and found an entity!\n" );

		return pEntity;
	}

	//g_Game.AlertMessage( at_notice, "FindActiveEntity called with no found entity!\n" );
	return null;
}

void GetPosition( CBaseEntity@ pAttacker, CBaseEntity@ pVictim, Vector &in vecVictimOrigin, Vector &out vecOut )
{
	Vector vecAttackerOrigin = pAttacker.pev.origin;

	Vector vecDirection;
	vecDirection = vecAttackerOrigin - vecVictimOrigin;
	vecDirection = vecDirection.Normalize();

	Vector vecViewOfs = pVictim.pev.view_ofs;
	vecViewOfs.z += 30.0;

	vecOut = vecVictimOrigin + vecViewOfs;
	vecOut = vecOut + vecDirection * 20.0;
}

void GetSpeedVector( Vector &in vecStartOrigin, Vector &in vecEndOrigin, float flSpeed, float flTime, Vector &out vecVelocity )
{
	if( flSpeed <= 0.0 )
		flSpeed = (vecStartOrigin - vecEndOrigin).Length() / flTime;
	else flSpeed /= flTime;

	vecVelocity = vecEndOrigin - vecStartOrigin;
	vecVelocity = vecVelocity.Normalize();
	vecVelocity = vecVelocity * flSpeed;
}

int PrepareBody( float flDamage )
{
	//g_Game.AlertMessage( at_notice, "PrepareBody called: %1\n", flDamage );
	int iDamage = Math.clamp( 0, 990, int(flDamage) ); //limited to 990 for now, and the third number can only go to 0 :pinkieSad:
	int iBodyConfig = 0;
	string sDamage = string(iDamage);
	if( sDamage.Length() == 3 ) sDamage = string(sDamage[0]) + string(sDamage[1]) + "0"; //force the third number to be zero

	for( uint i = 0; i < sDamage.Length(); ++i )
	{
		iBodyConfig = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex(MODEL_FLDAMAGE), iBodyConfig, i, atoi(sDamage[i])+1 );
		//g_Game.AlertMessage( at_notice, "sDamage.Length(): %1, sDamage[%2]: %3\n", sDamage.Length(), i, atoi(sDamage[i])+1 );
	}

	return iBodyConfig;
}

float GetScaleForMonster( CBaseEntity@ pMonster, float flBaseScale, float flMinScale, float flMaxScale, float flScaleIncrease = 0.4, float flScaleDecrease = 1.5 )
{
	float flBaseMobVolume = 73728;
	float flScale;

	float flMobVolume = (pMonster.pev.size.x * pMonster.pev.size.y * pMonster.pev.size.z);
	if( flMobVolume > flBaseMobVolume ) flScale = (flBaseScale * (flMobVolume/flBaseMobVolume)) * flScaleIncrease;
	else if( flMobVolume < flBaseMobVolume ) flScale = (flBaseScale / (flBaseMobVolume/flMobVolume)) * flScaleDecrease;
	else flScale = flBaseScale;

	return Math.clamp( flMinScale, flMaxScale, flScale );
}

class cso_fldamage : ScriptBaseEntity
{
	EHandle m_hMonster;
	Vector m_vecStartVelocity;

	void Spawn()
	{
		Precache();

		g_EntityFuncs.SetModel( self, MODEL_FLDAMAGE );

		pev.solid = SOLID_NOT;
		pev.movetype = MOVETYPE_NOCLIP;
		pev.renderfx = kRenderFxNone;
		pev.rendercolor = Vector(255.0, 255.0, 255.0);
		pev.rendermode = kRenderTransAdd;
		pev.renderamt = 255.0;

		SetThink( ThinkFunction(this.FDThink) );
		pev.nextthink = g_Engine.time + 0.05;

		//g_Game.AlertMessage( at_notice, "cso_fldamage spawned with dmg: %1, body: %2\n", pev.dmg, pev.body );
	}

	void Precache()
	{
		g_Game.PrecacheModel( MODEL_FLDAMAGE );
	}

	void FDThink()
	{
		if( pev.owner is null )
		{
			g_EntityFuncs.Remove( self );
			return;
		}

		if( bEnableFDRotation )
		{
			Vector vecAngles = pev.owner.vars.v_angle;

			vecAngles.y -= 180.0;
			pev.angles = vecAngles;
		}

		if( pev.sequence != 1 )
		{
			pev.frame = 0;
			pev.framerate = 0.33;
			pev.animtime = g_Engine.time; //NEEDED ??
			pev.sequence = 1;
		}

		float flRenderAmt = pev.renderamt;
		flRenderAmt -= 15.0;
		if( flRenderAmt <= 15.0 )
		{
			g_EntityFuncs.Remove( self );
			return;
		}

		pev.renderamt = flRenderAmt;
		pev.nextthink = g_Engine.time + 0.05;
	}
}

void RegisterFLDamage()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cso::cso_fldamage", "cso_fldamage" );
	g_Game.PrecacheOther( "cso_fldamage" );
}

} //namespace cso END
