namespace cso_skull11
{

const string CSOW_NAME								= "weapon_skull11";
const bool YEET_MAG_FOR_REAL					= true; //sometimes the mag actually gets launched and instakills almost anything :ayaya:
const int YEET_MAG_CHANCE							= 1; //in percent, 1-100

const int CSOW_DEFAULT_GIVE						= 28;
const int CSOW_MAX_CLIP 								= 28;
const int CSOW_MAX_AMMO							= 120;
const int CSOW_TRACERFREQ							= 0;
const int CSOW_PELLETCOUNT1						= 7;
const int CSOW_PELLETCOUNT2						= 3;
const float CSOW_DAMAGE1							= (91/CSOW_PELLETCOUNT1);
const float CSOW_DAMAGE2							= (45/CSOW_PELLETCOUNT2);
const float CSOW_TIME_DELAY1						= 0.32;
const float CSOW_TIME_DELAY2						= 0.6;
const float CSOW_TIME_DRAW						= 1.4;
const float CSOW_TIME_FIRE_TO_IDLE			= 1.0;
const float CSOW_TIME_RELOAD					= 4.0;
const Vector CSOW_OFFSETS_SHELL				= Vector( 10.592894, -5.715073, -4.249912 ); //forward, right, up
const Vector CSOW_VECTOR_SPREAD1			= Vector( 0.0725, 0.0725, 0.0 );
const Vector CSOW_VECTOR_SPREAD2			= Vector( 0.00873, 0.00873, 0.00873 );

const string CSOW_ANIMEXT							= "mp5"; //m249

const string MODEL_VIEW								= "models/custom_weapons/cso/v_skull11.mdl";
const string MODEL_PLAYER							= "models/custom_weapons/cso/p_skull11.mdl";
const string MODEL_WORLD							= "models/custom_weapons/cso/w_skull11.mdl";
const string MODEL_MAG									= "models/custom_weapons/cso/mag_skull11.mdl";
const string MODEL_SHELL								= "models/shotgunshell.mdl";

enum csow_e
{
	ANIM_IDLE = 0,
	ANIM_SHOOT1,
	ANIM_SHOOT2,
	ANIM_RELOAD,
	ANIM_DRAW,
	ANIM_RELOAD_YEET
};

enum csowsounds_e
{
	SND_EMPTY = 0,
	SND_SHOOT
};

const array<string> pCSOWSounds =
{
	"custom_weapons/cs16/dryfire_rifle.wav",
	"custom_weapons/cso/skull11_1.wav",
	"custom_weapons/cso/skull11_boltpull.wav",
	"custom_weapons/cso/skull11_clipin.wav",
	"custom_weapons/cso/skull11_clipout.wav"
};

enum csowmodes_e
{
	MODE_BUCKSHOT = 0,
	MODE_SLUG
}

class weapon_skull11 : CBaseCSOWeapon
{
	private int m_iWeaponMode;
	private float m_flYeetMag;

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, MODEL_WORLD );
		self.m_iDefaultAmmo = CSOW_DEFAULT_GIVE;
		self.m_flCustomDmg = pev.dmg;

		m_iWeaponType = TYPE_PRIMARY;
		g_iCSOWHands = HANDS_SVENCOOP;
		m_bSwitchHands = true;
		m_iWeaponMode = MODE_BUCKSHOT;
		m_flYeetMag = 0.0;

		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();

		g_Game.PrecacheModel( MODEL_VIEW );
		g_Game.PrecacheModel( MODEL_PLAYER );
		g_Game.PrecacheModel( MODEL_WORLD );
		g_Game.PrecacheModel( MODEL_MAG );

		m_iShell = g_Game.PrecacheModel( MODEL_SHELL );

		if( cso::bUseDroppedItemEffect )
			g_Game.PrecacheModel( cso::CSO_ITEMDISPLAY_MODEL );

		for( uint i = 1; i < cso::pSmokeSprites.length(); ++i )
			g_Game.PrecacheModel( cso::pSmokeSprites[i] );

		for( uint i = 0; i < pCSOWSounds.length(); ++i )
			g_SoundSystem.PrecacheSound( pCSOWSounds[i] );

		//Precache these for downloading
		for( uint i = 0; i < pCSOWSounds.length(); ++i )
			g_Game.PrecacheGeneric( "sound/" + pCSOWSounds[i] );

		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/" + CSOW_NAME + ".txt" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud2.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud71.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/muzzleflash2.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/muzzleflash4.spr" );
		g_Game.PrecacheGeneric( "events/cso/muzzle_usas12_1.txt" );
		g_Game.PrecacheGeneric( "events/cso/muzzle_usas12_2.txt" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= CSOW_MAX_AMMO;
		info.iMaxClip 		= CSOW_MAX_CLIP;
		info.iSlot				= cso::SKULL11_SLOT - 1;
		info.iPosition		= cso::SKULL11_POSITION - 1;
		info.iWeight			= cso::SKULL11_WEIGHT;

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer(pPlayer) )
			return false;

		@m_pPlayer = pPlayer;

		NetworkMessage m( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			m.WriteLong( g_ItemRegistry.GetIdForName(CSOW_NAME) );
		m.End();

		return true;
	}

	bool PlayEmptySound()
	{
		if( self.m_bPlayEmptySound )
		{
			self.m_bPlayEmptySound = false;
			g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_EMPTY], VOL_NORM, ATTN_NORM );
		}

		return false;
	}

	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model(MODEL_VIEW), self.GetP_Model(MODEL_PLAYER), ANIM_DRAW, CSOW_ANIMEXT, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + (CSOW_TIME_DRAW-0.7);
			self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_DRAW;

			return bResult;
		}
	}

	void Holster( int skiplocal )
	{
		m_flYeetMag = 0.0;

		BaseClass.Holster( skiplocal );
	}

	void PrimaryAttack()
	{
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD or self.m_iClip <= 0 )
		{
			self.m_bPlayEmptySound = true;
			PlayEmptySound();
			self.m_flNextPrimaryAttack = g_Engine.time + 1.0;
			return;
		}

		HandleAmmoReduction( 1 );

		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		self.SendWeaponAnim( Math.RandomLong(ANIM_SHOOT1, ANIM_SHOOT2), 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SHOOT], VOL_NORM, ATTN_NORM );

		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );

		float flDamage = (m_iWeaponMode == MODE_BUCKSHOT ? CSOW_DAMAGE1 : CSOW_DAMAGE2);
		if( self.m_flCustomDmg > 0 )
			flDamage = self.m_flCustomDmg;

		int iPelletCount = (m_iWeaponMode == MODE_BUCKSHOT ? CSOW_PELLETCOUNT1 : CSOW_PELLETCOUNT2);
		m_pPlayer.FireBullets( iPelletCount, m_pPlayer.GetGunPosition(), g_Engine.v_forward, (m_iWeaponMode == MODE_BUCKSHOT ? CSOW_VECTOR_SPREAD1 : CSOW_VECTOR_SPREAD2), 8192.0, BULLET_PLAYER_CUSTOMDAMAGE, CSOW_TRACERFREQ, 0 );
		cso::CreateShotgunPelletDecals( m_pPlayer, m_pPlayer.GetGunPosition(), g_Engine.v_forward, (m_iWeaponMode == MODE_BUCKSHOT ? CSOW_VECTOR_SPREAD1 : CSOW_VECTOR_SPREAD2), iPelletCount, flDamage, (DMG_BULLET | DMG_LAUNCH | DMG_NEVERGIB | DMG_ANTIZOMBIE) );

		EjectBrass( m_pPlayer.GetGunPosition() + g_Engine.v_forward * CSOW_OFFSETS_SHELL.x - g_Engine.v_right * CSOW_OFFSETS_SHELL.y + g_Engine.v_up * CSOW_OFFSETS_SHELL.z, m_iShell, TE_BOUNCE_SHOTSHELL, false, true );

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + (m_iWeaponMode == MODE_BUCKSHOT ? CSOW_TIME_DELAY1 : CSOW_TIME_DELAY2);
		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_FIRE_TO_IDLE;

		if( (m_pPlayer.pev.flags & FL_ONGROUND) != 0 )
			m_pPlayer.pev.punchangle.x -= g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed + 1, 1.5, 2.5 );
		else
			m_pPlayer.pev.punchangle.x -= g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed + 1, 3.0, 5.0 );
	}

	void SecondaryAttack()
	{
		if( m_iWeaponMode == MODE_BUCKSHOT )
		{
			m_iWeaponMode = MODE_SLUG;
			g_PlayerFuncs.ClientPrint( m_pPlayer, HUD_PRINTCENTER, "Ammo changed to slug rounds." );
		}
		else
		{
			m_iWeaponMode = MODE_BUCKSHOT;
			g_PlayerFuncs.ClientPrint( m_pPlayer, HUD_PRINTCENTER, "Ammo changed to buckshot rounds." );
		}

		self.m_flNextSecondaryAttack = g_Engine.time + 0.6;
	}

	void Reload()
	{
		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 or self.m_iClip >= CSOW_MAX_CLIP or (m_pPlayer.pev.button & IN_ATTACK) != 0 )
			return;

		int iAnim = ANIM_RELOAD;

		if( YEET_MAG_FOR_REAL )
		{
			int iYeetChance = g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed + 1, 1, 100 );
			iAnim = (iYeetChance <= YEET_MAG_CHANCE ? ANIM_RELOAD_YEET : ANIM_RELOAD);
			if( iYeetChance <= YEET_MAG_CHANCE ) m_flYeetMag = g_Engine.time + 1.2;
			SetThink( ThinkFunction(this.YeetMagThink) );
			pev.nextthink = g_Engine.time;
		}

		self.DefaultReload( CSOW_MAX_CLIP, iAnim, CSOW_TIME_RELOAD, (m_bSwitchHands ? g_iCSOWHands : 0) );
		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_RELOAD;

		BaseClass.Reload();
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		self.SendWeaponAnim( ANIM_IDLE, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
		self.m_flTimeWeaponIdle = g_Engine.time + 20;
	}

	void YeetMagThink()
	{
		if( m_flYeetMag > 0.0 and m_flYeetMag < g_Engine.time )
		{
			YeetMag();
			m_flYeetMag = 0.0;
			SetThink( null );
		}

		pev.nextthink = g_Engine.time + 0.01;
	}

	void YeetMag()
	{
		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		Vector vecOrigin = m_pPlayer.GetGunPosition() + g_Engine.v_forward * 16 + g_Engine.v_right * 8 + g_Engine.v_up * -4;

		CBaseEntity@ pYeetMag = g_EntityFuncs.Create( "skull11_yeetmag", vecOrigin, g_vecZero, false, m_pPlayer.edict() );
		pYeetMag.pev.velocity = m_pPlayer.pev.velocity + (g_Engine.v_forward * 840);
		pYeetMag.pev.dmgtime = g_Engine.time + 1.0; //how long the mag stays
	}
}

class skull11_yeetmag : ScriptBaseMonsterEntity
{
	void Spawn()
	{
		self.Precache();

		g_EntityFuncs.SetModel( self, MODEL_MAG );
		g_EntityFuncs.SetSize( self.pev, g_vecZero, g_vecZero );
		g_EntityFuncs.SetOrigin( self, self.pev.origin );

		pev.movetype	= MOVETYPE_BOUNCE;
		pev.solid			= SOLID_BBOX;
		pev.dmg			= 999999.0;
		pev.avelocity.x = -360;
		pev.avelocity.y = -360;

		SetTouch( TouchFunction(this.MagTouch) );
		SetThink( ThinkFunction(this.MagThink) );
		pev.nextthink = g_Engine.time + 0.1;
	}

	void Precache()
	{
		g_Game.PrecacheModel( MODEL_MAG );
	}

	void MagThink()
	{
		if( pev.dmgtime <= g_Engine.time )
			SetThink( ThinkFunction(this.RemoveThink) );

		pev.nextthink = g_Engine.time + 0.1;
	}

	void MagTouch( CBaseEntity@ pOther )
	{
		if( self.m_flNextAttack < g_Engine.time and self.pev.velocity.Length() > 100 )
		{
			entvars_t@ pevOwner = self.pev.owner.vars;
			if( pevOwner !is null )
			{
				TraceResult tr = g_Utility.GetGlobalTrace();
				g_WeaponFuncs.ClearMultiDamage();
				pOther.TraceAttack( pevOwner, pev.dmg, g_Engine.v_forward, tr, (DMG_CLUB|DMG_ALWAYSGIB) );
				g_WeaponFuncs.ApplyMultiDamage( self.pev, pevOwner);
			}

			self.m_flNextAttack = g_Engine.time + 0.2;
		}

		pev.velocity = pev.velocity * 0.8;

		if( !pev.FlagBitSet(FL_ONGROUND) )
			BounceSound();
	}

	void BounceSound()
	{
		switch( Math.RandomLong(0, 2) )
		{
			case 0:	g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, "weapons/grenade_hit1.wav", 0.25, ATTN_NONE );	break;
			case 1:	g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, "weapons/grenade_hit2.wav", 0.25, ATTN_NONE );	break;
			case 2:	g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, "weapons/grenade_hit3.wav", 0.25, ATTN_NONE );	break;
		}
	}

	void RemoveThink()
	{
		g_EntityFuncs.Remove( self );
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_skull11::skull11_yeetmag", "skull11_yeetmag" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_skull11::weapon_skull11", CSOW_NAME );
	g_ItemRegistry.RegisterWeapon( CSOW_NAME, "custom_weapons/cso", "buckshot", "", "ammo_buckshot" );
}

} //namespace cso_skull11 END

/*TODO
Improve the mode-change text
*/
