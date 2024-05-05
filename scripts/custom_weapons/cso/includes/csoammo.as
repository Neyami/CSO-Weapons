namespace cso
{

//Ammo
const string MODEL_45ACP			= "models/custom_weapons/cso/w_45acp.mdl";
const string MODEL_57MM			= "models/w_9mmclip.mdl";
const string MODEL_50BMG			= "models/custom_weapons/cso/w_50bmg.mdl";
const string MODEL_762MG			= "models/custom_weapons/cs16/w_762natobox_big.mdl";
const string MODEL_GASOLINE	= "models/hunger/w_gas.mdl";
const string MODEL_ETHER			= "models/custom_weapons/cso/w_etherammo.mdl";
const string MODEL_CSOBOLTS	= "models/custom_weapons/cso/mag_csocrossbow.mdl";

const int MAXCARRY_45ACP			= 100;
const int GIVE_45ACP					= 12;

const int MAXCARRY_57MM			= 100;
const int GIVE_57MM					= 50;

const int MAXCARRY_BMG50		= 50;
const int GIVE_BMG50					= 10;

const int MAXCARRY_GASOLINE	= 600;
const int GIVE_GASOLINE			= 50;

const int MAXCARRY_ETHER			= 90;
const int GIVE_ETHER					= 30;

const int MAXCARRY_CSOBOLTS	= 200;
const int GIVE_CSOBOLTS			= 50;

class ammo_45acp : ScriptBasePlayerAmmoEntity
{
	void Spawn()
	{ 
		Precache();

		g_EntityFuncs.SetModel( self, MODEL_45ACP );

		BaseClass.Spawn();
	}

	void Precache()
	{
		g_Game.PrecacheModel( MODEL_45ACP );
	}

	bool AddAmmo( CBaseEntity@ pOther )
	{ 
		if( pOther.GiveAmmo( GIVE_45ACP, "45acp", MAXCARRY_45ACP ) != -1)
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "items/9mmclip1.wav", VOL_NORM, ATTN_NORM );
			return true;
		}

		return false;
	}
}

void Register45ACP()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cso::ammo_45acp", "ammo_45acp" );
	g_Game.PrecacheOther( "ammo_45acp" );
}

class ammo_57mm : ScriptBasePlayerAmmoEntity
{
	void Spawn()
	{ 
		Precache();

		g_EntityFuncs.SetModel( self, MODEL_57MM );

		BaseClass.Spawn();
	}

	void Precache()
	{
		g_Game.PrecacheModel( MODEL_57MM );
	}

	bool AddAmmo( CBaseEntity@ pOther )
	{ 
		if( pOther.GiveAmmo( GIVE_57MM, "57mm", MAXCARRY_57MM ) != -1)
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "items/9mmclip1.wav", VOL_NORM, ATTN_NORM );
			return true;
		}

		return false;
	}
}

void Register57MM()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cso::ammo_57mm", "ammo_57mm" );
	g_Game.PrecacheOther( "ammo_57mm" );
}

class ammo_762mg : ScriptBasePlayerAmmoEntity
{
	void Spawn()
	{ 
		Precache();

		g_EntityFuncs.SetModel( self, MODEL_762MG );

		BaseClass.Spawn();
	}

	void Precache()
	{
		g_Game.PrecacheModel( MODEL_762MG );
	}

	bool AddAmmo( CBaseEntity@ pOther )
	{ 
		if( pOther.GiveAmmo( 100, "762mg", 600 ) != -1)
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "items/9mmclip1.wav", VOL_NORM, ATTN_NORM );
			return true;
		}

		return false;
	}
}

void Register762MG()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cso::ammo_762mg", "ammo_762mg" );
	g_Game.PrecacheOther( "ammo_762mg" );
}

class ammo_50bmg : ScriptBasePlayerAmmoEntity
{
	void Spawn()
	{
		Precache();

		g_EntityFuncs.SetModel( self, MODEL_50BMG );

		BaseClass.Spawn();
	}

	void Precache()
	{
		g_Game.PrecacheModel( MODEL_50BMG );
	}

	bool AddAmmo( CBaseEntity@ pOther )
	{ 
		if( pOther.GiveAmmo( GIVE_BMG50, "50bmg", MAXCARRY_BMG50 ) != -1)
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "items/9mmclip1.wav", 1, ATTN_NORM );
			return true;
		}

		return false;
	}
}

void Register50BMG()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cso::ammo_50bmg", "ammo_50bmg" );
	g_Game.PrecacheOther( "ammo_50bmg" );
}

class ammo_gasoline : ScriptBasePlayerAmmoEntity
{
	void Spawn()
	{
		Precache();

		g_EntityFuncs.SetModel( self, MODEL_GASOLINE );

		BaseClass.Spawn();
	}

	void Precache()
	{
		g_Game.PrecacheModel( MODEL_GASOLINE );
	}

	bool AddAmmo( CBaseEntity@ pOther )
	{ 
		if( pOther.GiveAmmo( GIVE_GASOLINE, "gasoline", MAXCARRY_GASOLINE ) != -1)
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "items/9mmclip1.wav", 1, ATTN_NORM );
			return true;
		}

		return false;
	}
}

void RegisterGasoline()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cso::ammo_gasoline", "ammo_gasoline" );
	g_Game.PrecacheOther( "ammo_gasoline" );
}

class ammo_ether : ScriptBasePlayerAmmoEntity
{
	void Spawn()
	{
		Precache();

		g_EntityFuncs.SetModel( self, MODEL_ETHER );

		BaseClass.Spawn();
	}

	void Precache()
	{
		g_Game.PrecacheModel( MODEL_ETHER );
	}

	bool AddAmmo( CBaseEntity@ pOther )
	{ 
		if( pOther.GiveAmmo( GIVE_ETHER, "ether", MAXCARRY_ETHER ) != -1)
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "items/9mmclip1.wav", 1, ATTN_NORM );
			return true;
		}

		return false;
	}
}

void RegisterEther()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cso::ammo_ether", "ammo_ether" );
	g_Game.PrecacheOther( "ammo_ether" );
}

class ammo_csobolts : ScriptBasePlayerAmmoEntity
{
	void Spawn()
	{
		Precache();

		g_EntityFuncs.SetModel( self, MODEL_CSOBOLTS );

		BaseClass.Spawn();
	}

	void Precache()
	{
		g_Game.PrecacheModel( MODEL_CSOBOLTS );
	}

	bool AddAmmo( CBaseEntity@ pOther )
	{ 
		if( pOther.GiveAmmo( GIVE_CSOBOLTS, "csobolts", MAXCARRY_CSOBOLTS ) != -1)
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "items/9mmclip1.wav", 1, ATTN_NORM );
			return true;
		}

		return false;
	}
}

void RegisterCSOBolts()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cso::ammo_csobolts", "ammo_csobolts" );
	g_Game.PrecacheOther( "ammo_csobolts" );
}

} //namespace cso END