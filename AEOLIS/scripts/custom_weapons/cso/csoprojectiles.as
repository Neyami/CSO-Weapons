//Thanks to Aperture for this one!
class csoproj_flame : ScriptBaseEntity
{
	void Spawn()
	{
		g_EntityFuncs.SetModel( self, AEOLIS_SPRITE_FLAME );
		g_EntityFuncs.SetSize( self.pev, Vector(-4, -4, -4), Vector(4, 4, 4) );
		g_EntityFuncs.SetOrigin( self, self.pev.origin );

		self.pev.movetype = MOVETYPE_FLY;
		self.pev.solid    = SOLID_BBOX;
		self.pev.rendermode = kRenderTransAdd;
		self.pev.renderamt = 250;  
		self.pev.scale = 0.3f;
		self.pev.frame = 0;
		self.pev.nextthink = g_Engine.time + 0.1f;
		SetThink( ThinkFunction(this.FlameThink) );
	}

	void FlameThink()
	{
		self.pev.nextthink = g_Engine.time + 0.03f;

		int r = 255, g = 200, b = 100;
		
		NetworkMessage glowdl( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
			glowdl.WriteByte( TE_DLIGHT );
			glowdl.WriteCoord( self.pev.origin.x );
			glowdl.WriteCoord( self.pev.origin.y );
			glowdl.WriteCoord( self.pev.origin.z );
			glowdl.WriteByte( 16 );//radius
			glowdl.WriteByte( int(r) );
			glowdl.WriteByte( int(g) );
			glowdl.WriteByte( int(b) );
			glowdl.WriteByte( 4 );//life
			glowdl.WriteByte( 128 );//decay
		glowdl.End();

		self.pev.frame += 1.0f;
		self.pev.scale += 0.09f;
		
		if( self.pev.frame > 21 )
		{
			self.pev.frame = 0;
			g_EntityFuncs.Remove( self );
			return;
		}
	}

	void Touch( CBaseEntity@ pOther )
	{
		entvars_t@ pevOwner = self.pev.owner.vars;

		if( pOther.edict() is self.pev.owner )
			return;

		if( pOther.pev.classname == "csoproj_flame" )
		{
			self.pev.solid = SOLID_NOT;
			self.pev.movetype = MOVETYPE_NONE;

			return;
		}

		if( pOther.pev.takedamage != DAMAGE_NO && pOther.IsAlive() == true )
		{
			if( pOther.pev.classname == "monster_cleansuit_scientist" || pOther.IsMonster() == false )
				pOther.TakeDamage( pevOwner, pevOwner, Math.RandomLong(AEOLIS_DAMAGE,AEOLIS_DAMAGE_FLAME), DMG_BURN | DMG_NEVERGIB );
			else
				pOther.TakeDamage( pevOwner, pevOwner, Math.RandomLong(AEOLIS_DAMAGE,AEOLIS_DAMAGE_FLAME), DMG_BURN | DMG_POISON | DMG_NEVERGIB );
		}

		self.pev.movetype = MOVETYPE_NONE;
		self.pev.solid = SOLID_NOT;
		SetTouch(null);
	}
}

class csoproj_petrolbomb : ScriptBaseEntity
{
	private int FireStayTime;

	void Spawn()
	{
		g_EntityFuncs.SetModel( self, PB_MODEL_BOMB );
		g_EntityFuncs.SetSize( self.pev, Vector(-4, -4, -4), Vector(4, 4, 4) );
		g_EntityFuncs.SetOrigin( self, self.pev.origin );

		self.pev.movetype = MOVETYPE_TOSS;
		self.pev.solid = SOLID_BBOX;
	}

	void Touch( CBaseEntity@ pOther )
	{
		Explode();
	}

	void Explode()
	{
		entvars_t@ pevOwner = self.pev.owner.vars;
		string szFireAnim;

		g_WeaponFuncs.RadiusDamage( self.pev.origin, self.pev, pevOwner, PB_DAMAGE, PB_DAMAGE, CLASS_NONE, DMG_BLAST | DMG_NEVERGIB );
		//ExplosionEffect
		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, pPBSounds[PB_SOUND_EXPLOSION], 1, ATTN_NONE );

		CBaseEntity@ ownerInstance = g_EntityFuncs.Instance( self.pev.owner );
		//CBasePlayer@ owner = cast<CBasePlayer@>( ownerInstance );

		Vector vecFlameVelocity = Vector(0, 0, 1) * Math.RandomLong(300, 400);
		Vector vecFlameOrigin1 = self.pev.origin;
		Vector vecFlameOrigin2 = self.pev.origin;
		Vector vecFlameOrigin3 = self.pev.origin;
		Vector vecFlameOrigin4 = self.pev.origin;
		Vector vecFlameOrigin5 = self.pev.origin;
		vecFlameOrigin2.x += 64;
		vecFlameOrigin3.x -= 64;
		vecFlameOrigin4.y += 64;
		vecFlameOrigin5.y -= 64;

		CSO_ShootCustomProjectile( "csoproj_petrolflame", pPBFlames[PB_SPRITE_FLAME1], vecFlameOrigin1, vecFlameVelocity, g_vecZero, EHandle(ownerInstance) );
		CSO_ShootCustomProjectile( "csoproj_petrolflame", pPBFlames[Math.RandomLong(1, 2)], vecFlameOrigin2, vecFlameVelocity, g_vecZero, EHandle(ownerInstance) );
		CSO_ShootCustomProjectile( "csoproj_petrolflame", pPBFlames[Math.RandomLong(1, 2)], vecFlameOrigin3, vecFlameVelocity, g_vecZero, EHandle(ownerInstance) );
		CSO_ShootCustomProjectile( "csoproj_petrolflame", pPBFlames[Math.RandomLong(1, 2)], vecFlameOrigin4, vecFlameVelocity, g_vecZero, EHandle(ownerInstance) );
		CSO_ShootCustomProjectile( "csoproj_petrolflame", pPBFlames[Math.RandomLong(1, 2)], vecFlameOrigin5, vecFlameVelocity, g_vecZero, EHandle(ownerInstance) );

		g_EntityFuncs.Remove( self );
	}
}

class csoproj_petrolflame : ScriptBaseEntity
{
	int FireStayTime, maxFrames;

	void Spawn()
	{
		g_EntityFuncs.SetModel( self, self.pev.model );
		g_EntityFuncs.SetSize( self.pev, Vector(-4, -4, -4), Vector(4, 4, 4) );
		g_EntityFuncs.SetOrigin( self, self.pev.origin );

		self.pev.movetype = MOVETYPE_TOSS;
		self.pev.solid = SOLID_SLIDEBOX;
		self.pev.rendermode = kRenderTransAdd;
		self.pev.renderamt = 250;  
		self.pev.frame = 0;
		FireStayTime = 100;
		SetThink( ThinkFunction(this.BurnThink) );
		self.pev.nextthink = g_Engine.time + 0.1f;
	}

	void Touch( CBaseEntity@ pOther )
	{
		if( pOther is g_EntityFuncs.Instance(self.pev.owner) || pOther.pev.classname == "csoproj_petrolflame" || pOther.pev.classname == "csoproj_petrolbomb" )
			self.pev.solid = SOLID_NOT;

		Vector vecVelocity = self.pev.velocity * 0.4f;
		self.pev.velocity = vecVelocity;

		TraceResult tr;
		g_Utility.TraceLine( self.pev.origin, self.pev.origin + Vector( 0, 0, -4 ),  ignore_monsters, self.edict(), tr );
		
		if( tr.flFraction < 1.0f )
		{
			self.pev.origin.z += 64;
			g_Game.AlertMessage( at_console, "on the ground!\n" );
		}
	}

	void BurnThink()
	{
		if( FireStayTime <= 0 )
			g_EntityFuncs.Remove( self );
		else
			FireStayTime--;

		entvars_t@ pevOwner = self.pev.owner.vars;
		g_WeaponFuncs.RadiusDamage( self.pev.origin, self.pev, pevOwner, FireStayTime/2, PB_DAMAGE/3, CLASS_NONE, DMG_BURN | DMG_NEVERGIB );

		self.pev.frame += 1;
		maxFrames = self.pev.model == pPBFlames[PB_SPRITE_FLAME1] ? 17 : 16;

		if( self.pev.frame >= maxFrames )
			self.pev.frame = 0;

		self.pev.nextthink = g_Engine.time + 0.06f;
	}
}

CBaseEntity@ CSO_ShootCustomProjectile( string classname, string mdl, Vector origin, Vector velocity, Vector angles, EHandle &in eOwner, float time = 0 )
{
	CBaseEntity@ owner = eOwner.GetEntity();

	if( classname.Length() == 0 )
		return null;

	dictionary keys;
	Vector projAngles = angles * Vector( -1, 1, 1 );
	keys[ "origin" ] = origin.ToString();
	keys[ "angles" ] = projAngles.ToString();
	keys[ "velocity" ] = velocity.ToString();

	string model = mdl.Length() > 0 ? mdl : "models/error.mdl";
	keys[ "model" ] = model;

	if( mdl.Length() == 0 )
		keys[ "rendermode" ] = "1"; // don't render the model

	CBaseEntity@ shootEnt = g_EntityFuncs.CreateEntity( classname, keys, false );
	@shootEnt.pev.owner = owner.edict();

	if( time > 0 ) shootEnt.pev.dmgtime = time;

	g_EntityFuncs.DispatchSpawn( shootEnt.edict() );

	return shootEnt;
}

void CSO_RegisterProjectiles()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "csoproj_flame", "csoproj_flame" );
	g_CustomEntityFuncs.RegisterCustomEntity( "csoproj_petrolbomb", "csoproj_petrolbomb" );
	g_CustomEntityFuncs.RegisterCustomEntity( "csoproj_petrolflame", "csoproj_petrolflame" );
}