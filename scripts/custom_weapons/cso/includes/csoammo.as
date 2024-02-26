namespace cso
{

//Ammo
const string MODEL_50BMG			= "models/custom_weapons/cso/w_50bmg.mdl";
const string MODEL_762MG			= "models/custom_weapons/cs16/w_762natobox_big.mdl";
const string MODEL_GASOLINE	= "models/hunger/w_gas.mdl";

const int BMG50_MAXCARRY		= 50;
const int BMG50_GIVE					= 10;

const int GASOLINE_MAXCARRY	= 600;
const int GASOLINE_GIVE			= 50;

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
		if( pOther.GiveAmmo( BMG50_GIVE, "50bmg", BMG50_MAXCARRY ) != -1)
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
		if( pOther.GiveAmmo( GASOLINE_GIVE, "gasoline", GASOLINE_MAXCARRY ) != -1)
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

} //namespace cso END