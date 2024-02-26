namespace cso
{

//Hitconfirm
const string SPRITE_HITMARKER	= "sprites/custom_weapons/cso/buffhit.spr";

//Gundrop Effect
const string CSO_ITEMDISPLAY_MODEL	= "models/custom_weapons/cso/ef_gundrop.mdl";

//Floating Damage
const string MODEL_FLDAMAGE = "models/cso/floating_damage.mdl";
const bool bEnableFDRotation = true;


//TODO REMOVE THIS
class cso_aoetrigger : ScriptBaseEntity
{
	void Spawn()
	{
		pev.solid = SOLID_TRIGGER;
		pev.movetype = MOVETYPE_NONE;
		g_EntityFuncs.SetOrigin( self, self.GetOrigin() );
		SetThink( null );
		//pev.nextthink = g_Engine.time + 0.1f;
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

class ef_gundrop : ScriptBaseAnimating
{
	EHandle m_hOwner;

	void Spawn()
	{
		Precache();

		g_EntityFuncs.SetModel( self, CSO_ITEMDISPLAY_MODEL );
		g_EntityFuncs.SetOrigin( self, self.pev.origin );
		g_EntityFuncs.SetSize( self.pev, g_vecZero, g_vecZero );

		pev.solid		= SOLID_NOT;
		pev.framerate	= 1.0;

		self.pev.frame = 0;
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

class cso_buffhit : ScriptBaseEntity
{
	private float m_flRemoveTime;

	void Spawn()
	{
		Precache();

		pev.scale = 0.13;
		pev.frame = 0.0;
		pev.framerate = 1.0;
		pev.movetype = MOVETYPE_NONE;
		pev.solid = SOLID_NOT;
		pev.rendermode = kRenderGlow;
		pev.renderfx = kRenderFxNoDissipation;
		pev.renderamt = 190;

		g_EntityFuncs.SetOrigin( self, self.pev.origin );
		g_EntityFuncs.SetModel( self, SPRITE_HITMARKER );

		m_flRemoveTime = g_Engine.time + 0.1;

		SetThink( ThinkFunction(this.HitMarkerThink) );
		pev.nextthink = g_Engine.time;
	}

	void Precache()
	{
		g_Game.PrecacheModel( SPRITE_HITMARKER );
	}

	void HitMarkerThink()
	{
		pev.nextthink = g_Engine.time + 0.01;

		if( pev.owner is null )
		{
			g_EntityFuncs.Remove( self );
			return;
		}

		Vector vecOrigin;
		get_position( pev.owner, 50.0, -0.05, 0.0, vecOrigin );
		g_EntityFuncs.SetOrigin( self, vecOrigin );

		/*NetworkMessage m1( MSG_ONE_UNRELIABLE, NetworkMessages::SVC_TEMPENTITY, pev.owner );
			m1.WriteByte( TE_SPRITE );
			m1.WriteCoord( vecOrigin.x );
			m1.WriteCoord( vecOrigin.y );
			m1.WriteCoord( vecOrigin.z );
			m1.WriteShort( g_EngineFuncs.ModelIndex(SPRITE_HITMARKER) );
			m1.WriteByte( 2 );//scale
			m1.WriteByte( 255 );//brightness
		m1.End();*/

		if( g_Engine.time >= m_flRemoveTime )
			g_EntityFuncs.Remove( self );
	}

	void get_position( edict_t@ pOwner, float flForward, float flRight, float flUp, Vector &out vecOut )
	{
		Vector vecOrigin, vecAngle, vecForward, vecRight, vecUp;

		vecOrigin = pOwner.vars.origin;
		vecUp = pOwner.vars.view_ofs; //GetGunPosition() ??
		vecOrigin = vecOrigin + vecUp;

		vecAngle = pOwner.vars.v_angle; //if normal entity: use pev.angles

		g_EngineFuncs.AngleVectors( vecAngle, vecForward, vecRight, vecUp );

		vecOut = vecOrigin + vecForward * flForward + vecRight * flRight + vecUp * flUp;
	}
}

void RegisterBuffHit()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cso::cso_buffhit", "cso_buffhit" );
	g_Game.PrecacheOther( "cso_buffhit" );
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