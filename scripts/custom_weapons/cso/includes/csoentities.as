namespace cso
{

//Hitconfirm
const string SPRITE_HITMARKER	= "sprites/custom_weapons/cso/buffhit.spr";

//Gundrop Effect
const string CSO_ITEMDISPLAY_MODEL	= "models/custom_weapons/cso/ef_gundrop.mdl";

//Floating Damage
const string MODEL_FLDAMAGE = "models/cso/floating_damage.mdl";
const bool bEnableFDRotation = true;

class ef_gundrop : ScriptBaseAnimating
{
	EHandle m_hOwner;

	void Spawn()
	{
		Precache();

		g_EntityFuncs.SetModel( self, CSO_ITEMDISPLAY_MODEL );
		g_EntityFuncs.SetOrigin( self, pev.origin );
		g_EntityFuncs.SetSize( self.pev, g_vecZero, g_vecZero );

		pev.solid		= SOLID_NOT;
		pev.framerate	= 1.0;
		pev.rendermode = kRenderTransTexture;
		pev.renderamt = 0;

		pev.frame = 0;
		self.ResetSequenceInfo();

		SetThink( ThinkFunction(this.IdleThink) );
		pev.nextthink = g_Engine.time + 0.1;
	}

	void Precache()
	{
		g_Game.PrecacheModel( CSO_ITEMDISPLAY_MODEL );
	}

	void IdleThink()
	{
		if( m_hOwner.IsValid() )
		{
			if( pev.rendermode != 0 and m_hOwner.GetEntity().pev.velocity == g_vecZero )
				pev.rendermode = 0;

			self.StudioFrameAdvance();

			if( m_hOwner.GetEntity().pev.owner !is null )
				g_EntityFuncs.Remove( self );
		}
		else g_EntityFuncs.Remove( self );

		pev.nextthink = g_Engine.time + 0.1;
	}
}

void RegisterGunDrop()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cso::ef_gundrop", "ef_gundrop" );
	g_Game.PrecacheOther( "ef_gundrop" );
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

const array<string> pCSOFlameSprites =
{
	"sprites/flame2.spr",
	"sprites/fire.spr"
};

class cso_dotent : ScriptBaseEntity
{
	EHandle m_hTarget;
	float m_flRemoveTime;
	float m_flDamageRate;

	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if( szKey == "damagerate" )
		{
			if( atof(szValue) > 0 )
				m_flDamageRate = atof( szValue );

			return true;
		}
		else
			return BaseClass.KeyValue( szKey, szValue );
	}

	void Spawn()
	{
		//g_Game.AlertMessage( at_notice, "cso_dotent spawned with owner: %1, dmgtime: %2\n", pev.owner.vars.classname, pev.dmgtime );
		Precache();

		g_EntityFuncs.SetOrigin( self, pev.origin );

		pev.solid = SOLID_NOT;
		pev.movetype = MOVETYPE_FOLLOW;

		m_flRemoveTime = g_Engine.time + pev.dmgtime;

		if( m_flDamageRate == 0 )
			m_flDamageRate = 1.0;

		SetThink( ThinkFunction(this.DotThink) );
		pev.nextthink = g_Engine.time + 0.01;
	}

	void Precache()
	{
		for( uint i = 0; i < pCSOFlameSprites.length(); ++i )
			g_Game.PrecacheModel( pCSOFlameSprites[i] );

		g_SoundSystem.PrecacheSound( "ambience/flameburst1.wav" );
	}

	void DotThink()
	{
		if( !m_hTarget.IsValid() or m_hTarget.GetEntity().pev.deadflag > DEAD_NO or m_hTarget.GetEntity().pev.takedamage == DAMAGE_NO or g_Engine.time >= m_flRemoveTime )
		{
			g_EntityFuncs.Remove( self );
			return;
		}

		CBaseEntity@ pHurt = m_hTarget.GetEntity();
		pHurt.TakeDamage( self.pev, pev.owner.vars, pev.dmg, DMG_BURN );

		if( Math.RandomFloat(0, 1) >= 0.66 )
			g_SoundSystem.EmitSoundDyn( pHurt.edict(), CHAN_ITEM, "ambience/flameburst1.wav", VOL_NORM, ATTN_NORM, 100 + Math.RandomLong(-16, 16) );

		Vector vecBurnSprite = pHurt.pev.origin;
		NetworkMessage m1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
			m1.WriteByte( TE_SPRITE );
			m1.WriteCoord( vecBurnSprite.x );
			m1.WriteCoord( vecBurnSprite.y );
			m1.WriteCoord( vecBurnSprite.z+32 );
			m1.WriteShort( g_EngineFuncs.ModelIndex(pCSOFlameSprites[0]) );
			m1.WriteByte( 10 );
			m1.WriteByte( 200 );
		m1.End();

		pev.nextthink = g_Engine.time + m_flDamageRate;
	}
}

void RegisterDotEnt()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cso::cso_dotent", "cso_dotent" );
	g_Game.PrecacheOther( "cso_dotent" );
}

//TODO REMOVE THIS
class cso_aoetrigger : ScriptBaseEntity
{
	void Spawn()
	{
		pev.solid = SOLID_TRIGGER;
		pev.movetype = MOVETYPE_NONE;
		g_EntityFuncs.SetOrigin( self, self.GetOrigin() );
		SetThink( null );
		//pev.nextthink = g_Engine.time + 0.1;
	}
/*
	void Think()
	{
		DrawDebugBox( pev.absmin, pev.absmax, 25, Math.RandomLong( 0, 255 ), Math.RandomLong( 0, 255 ), Math.RandomLong( 0, 255 ) );
		SetThink( null );
	}

	void DrawDebugBox( Vector &in mins, Vector &in maxs, uint time, int r, int g, int b )
	{
		NetworkMessage box( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null );
			box.WriteByte( TE_BOX );
			box.WriteCoord( mins.x );
			box.WriteCoord( mins.y );
			box.WriteCoord( mins.z );
			box.WriteCoord( maxs.x );
			box.WriteCoord( maxs.y );
			box.WriteCoord( maxs.z );
			box.WriteShort( time );
			box.WriteByte( r );
			box.WriteByte( g );
			box.WriteByte( b );
		box.End();
	}*/
}

class csoproj_flame : ScriptBaseEntity
{
	private float m_flRemoveTime;

	void Spawn()
	{
		Precache();

		g_EntityFuncs.SetModel( self, "sprites/custom_weapons/cso/flame_puff01.spr" );
		g_EntityFuncs.SetSize( self.pev, Vector(-1.0, -1.0, -1.0), Vector(1.0, 1.0, 1.0) );
		g_EntityFuncs.SetOrigin( self, pev.origin );

		pev.movetype = MOVETYPE_FLY;
		pev.solid    = SOLID_TRIGGER; //SOLID_BBOX
		pev.rendermode = kRenderTransAdd;
		pev.renderamt = 160;
		pev.scale = 0.25;
		pev.frame = 0;
		pev.gravity = 0.01; //?

		m_flRemoveTime = g_Engine.time + 1.0;

		pev.nextthink = g_Engine.time + 0.05;
		SetThink( ThinkFunction(this.FlameThink) );
	}

	void Precache()
	{
		g_Game.PrecacheModel( "sprites/custom_weapons/cso/flame_puff01.spr" );
	}

	void FlameThink()
	{
		float flFrame, flScale;
		flFrame = pev.frame;
		flScale = pev.scale;

		if( pev.movetype == MOVETYPE_NONE )
		{
			flFrame += 1.0;
			flScale += 0.1;
			flScale = Math.min( flScale, 1.75 );

			if( flFrame > 21.0 )
			{
				g_EntityFuncs.Remove( self );
				return;
			}

			pev.nextthink = g_Engine.time + 0.025;
		}
		else
		{
			flFrame += 1.25;
			flFrame = Math.min( 21.0, flFrame );
			flScale += 0.15;
			flScale = Math.min( flScale, 1.75 );

			pev.nextthink = g_Engine.time + 0.05;
		}

		pev.frame = flFrame;
		pev.scale = flScale;

		if( g_Engine.time >= m_flRemoveTime )
			g_EntityFuncs.Remove( self );
	}

	void Touch( CBaseEntity@ pOther )
	{
		if( pOther.edict() is pev.owner or pOther.pev.classname == self.GetClassname() ) //is checking the classname NEEDED ??
			return;

		if( g_EntityFuncs.Instance(pev.owner).IRelationship(pOther) <= R_NO )
			return;

		if( pOther.pev.takedamage != DAMAGE_NO and pOther.IsAlive() )
		{
			pOther.TakeDamage( self.pev, pev.owner.vars, pev.dmg, DMG_BURN | DMG_NEVERGIB );

			CBaseEntity@ cbeOldDotEnt = null;
			cso_dotent@ pOldDotEnt = null;

			while( (@cbeOldDotEnt = g_EntityFuncs.FindEntityByClassname(cbeOldDotEnt, "cso_dotent")) !is null )
			{
				if( cbeOldDotEnt.pev.owner !is null and cbeOldDotEnt.pev.owner is pev.owner )
				{
					@pOldDotEnt = cast<cso_dotent@>(CastToScriptClass(cbeOldDotEnt));
					if( pOldDotEnt.m_hTarget.IsValid() and pOldDotEnt.m_hTarget.GetEntity() is pOther )
						break;
					else
						@pOldDotEnt = null;
				}
			}

			if( pOldDotEnt is null )
			{
				CBaseEntity@ cbeDotEnt = g_EntityFuncs.Create( "cso_dotent", pOther.pev.origin, g_vecZero, true, pev.owner );
				cso_dotent@ pDotEnt = cast<cso_dotent@>(CastToScriptClass(cbeDotEnt));

				if( pDotEnt !is null )
				{
					pDotEnt.m_hTarget = EHandle( pOther );
					@pDotEnt.pev.aiment = pOther.edict();
					pDotEnt.pev.dmgtime = 10.0;
					pDotEnt.pev.dmg = pev.dmg;
					g_EntityFuncs.DispatchSpawn( pDotEnt.self.edict() );
				}
			}
			/*else
			{
				//TODO update dotent ??
			}*/
		}

		pev.movetype = MOVETYPE_NONE;
		pev.solid = SOLID_NOT;
		SetTouch( null );
	}
}

class csoproj_buffak : ScriptBaseEntity
{
	private float m_flRemoveTime;

	void Spawn()
	{
		Precache();

		g_EntityFuncs.SetModel( self, "sprites/custom_weapons/cso/muzzleflash19.spr" );
		g_EntityFuncs.SetSize( self.pev, Vector(-1.0, -1.0, -1.0), Vector(1.0, 1.0, 1.0) );
		g_EntityFuncs.SetOrigin( self, pev.origin );

		pev.movetype = MOVETYPE_FLY;
		pev.solid    = SOLID_TRIGGER; //SOLID_BBOX
		pev.rendermode = kRenderTransAdd;
		pev.renderamt = 80;
		pev.scale = 0.15;
		pev.gravity = 0.01; //?

		m_flRemoveTime = g_Engine.time + 5.0;

		pev.nextthink = g_Engine.time;
		SetThink( ThinkFunction(this.FlyThink) );
	}

	void Precache()
	{
		g_Game.PrecacheModel( "sprites/custom_weapons/cso/muzzleflash19.spr" );
		g_Game.PrecacheModel( "sprites/custom_weapons/cso/ef_buffak_hit.spr" );
	}

	void FlyThink()
	{
		pev.nextthink = g_Engine.time + 0.01;

		if( g_Engine.time >= m_flRemoveTime )
			g_EntityFuncs.Remove( self );
	}

	void Touch( CBaseEntity@ pOther )
	{
		if( pOther.edict() is pev.owner or pOther.pev.classname == self.GetClassname() ) //is checking the classname NEEDED ??
			return;

		if( pOther.pev.takedamage != DAMAGE_NO and pOther.IsAlive() )
		{
			if( g_EntityFuncs.Instance(pev.owner).IRelationship(pOther) > R_NO )
			{
				TraceResult tr;
				g_Utility.TraceLine( pOther.Center(), pOther.Center(), ignore_monsters, pev.owner, tr );

				g_WeaponFuncs.ClearMultiDamage();
				pOther.TraceAttack( pev.owner.vars, pev.dmg, g_Engine.v_forward, tr, DMG_NEVERGIB );
				g_WeaponFuncs.ApplyMultiDamage( self.pev, pev.owner.vars );
				//pOther.TakeDamage( self.pev, pev.owner.vars, pev.dmg, DMG_NEVERGIB );
			}
		}

		pev.velocity = g_vecZero;
		pev.movetype = MOVETYPE_NONE;
		pev.solid = SOLID_NOT;
		SetTouch( null );

		Explode();

		g_EntityFuncs.Remove( self );
	}

	void Explode()
	{
		TraceResult tr;
		Vector vecOrigin = pev.origin - pev.velocity.Normalize() * 32;
		g_Utility.TraceLine( vecOrigin, vecOrigin + pev.velocity.Normalize() * 64, ignore_monsters, self.edict(), tr );

		// Pull out of the wall a bit
		if( tr.flFraction != 1.0 )
			vecOrigin = tr.vecEndPos + ( tr.vecPlaneNormal *  0.6 );

		NetworkMessage m1( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecOrigin );
			m1.WriteByte( TE_EXPLOSION );
			m1.WriteCoord( vecOrigin.x );
			m1.WriteCoord( vecOrigin.y );
			m1.WriteCoord( vecOrigin.z );
			m1.WriteShort( g_EngineFuncs.ModelIndex("sprites/custom_weapons/cso/ef_buffak_hit.spr") );
			m1.WriteByte( 5 ); // scale * 10
			m1.WriteByte( 15 ); // framerate
			m1.WriteByte( TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES );
		m1.End();

		//g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, pCSOWSounds[SND_EXPLODE], VOL_NORM, ATTN_NORM );
		g_WeaponFuncs.RadiusDamage( vecOrigin, self.pev, pev.owner.vars, pev.dmg, MetersToUnits(2), CLASS_PLAYER, DMG_LAUNCH ); 
	}

	//WHY THE FUCK CAN'T YOU ACCESS IT FROM csocommon.as ?!
	double MetersToUnits( float flMeters ) { return flMeters/0.0254; }
}

} //namespace cso END