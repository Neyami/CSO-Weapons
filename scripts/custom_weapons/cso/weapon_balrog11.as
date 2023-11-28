namespace cso_balrog11
{

const Vector CSOW_VECTOR_SPREAD( 0.0725f, 0.0725f, 0.0f );
const Vector CSOW_VECTOR_EJECT( 22.0f, 11.0f, -9.0f );
const Vector2D CSOW_VEC2D_RECOIL( 6.0f, 10.0f );

const int CSOW_DEFAULT_GIVE			= 7;
const int CSOW_MAX_CLIP 			= 7;
const int CSOW_MAX_AMMO	 			= 32; //doesn't actually do anything since it uses the maxammo set by the buymenu plugin ¯\_(ツ)_/¯
const int CSOW_MAX_AMMO2	 		= 7;
const int CSOW_WEIGHT 				= 20;
const float CSOW_DAMAGE1			= 6;
const float CSOW_DAMAGE2A			= 25; //200
const int CSOW_FIREBALLS_AMOUNT		= 8; //200 total
const float CSOW_FIREBALLS_SPEED	= 1.0f;

const uint CSOW_PELLETCOUNT			= 6;

const float CSOW_DELAY1				= 0.25f;
const float CSOW_DELAY2				= 0.35;
const float CSOW_TIME_RELOAD		= 0.3f;
const float CSOW_TIME_IDLE			= 1.7f;
const float CSOW_TIME_DRAW			= 1.1f;
const float CSOW_TIME_FIRE_TO_IDLE	= 1.0f;
const float CSOW_SPECIAL_RADIUS		= 600;

const string MODEL_VIEW				= "models/custom_weapons/cso/v_balrog11.mdl";
const string MODEL_PLAYER			= "models/custom_weapons/cso/p_balrog11.mdl";
const string MODEL_WORLD			= "models/custom_weapons/cso/w_balrog11.mdl";
const string MODEL_SHELL			= "models/shotgunshell.mdl";
const string MODEL_SHELL_SPECIAL	= "models/custom_weapons/cso/shell_bcs.mdl";
const string SPRITE_FIRE			= "sprites/custom_weapons/cso/flame_puff01.spr";

enum csow_e
{
	ANIM_IDLE = 0,
	ANIM_DRAW,
	ANIM_SHOOT1,
	ANIM_SHOOT2,
	ANIM_SHOOT_BCS,
	ANIM_START_RELOAD,
	ANIM_INSERT,
	ANIM_AFTER_RELOAD
}

enum csowsounds_e
{
	SND_EMPTY = 0,
	SND_DRAW,
	SND_INSERT,
	SND_SHOOT1,
	SND_SHOOT2,
	SND_CHARGE
};

const array<string> pCSOWSounds =
{
	"custom_weapons/cs16/dryfire_rifle.wav",
	"custom_weapons/cso/balrog11_draw.wav",
	"custom_weapons/cso/balrog11_insert.wav",
	"custom_weapons/cso/balrog11-1.wav",
	"custom_weapons/cso/balrog11-2.wav",
	"custom_weapons/cso/balrog9_charge_finish.wav"
};

class weapon_balrog11 : CBaseCustomWeapon //ScriptBasePlayerWeaponEntity
{
	//private CBasePlayer@ m_pPlayer = null;
	private float m_flNextSpecialExplosion;
	private int m_iShotgunReload;
	private int m_iShotsFired;

	void Spawn()
	{
		g_EntityFuncs.SetModel( self, MODEL_WORLD );
		self.m_iDefaultAmmo = CSOW_DEFAULT_GIVE;
		self.m_flCustomDmg = pev.dmg;
		m_iShotsFired = 0;
		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();

		g_Game.PrecacheModel( MODEL_VIEW );
		g_Game.PrecacheModel( MODEL_PLAYER );
		g_Game.PrecacheModel( MODEL_WORLD );

		g_Game.PrecacheModel( MODEL_SHELL );
		g_Game.PrecacheModel( MODEL_SHELL_SPECIAL );
		g_Game.PrecacheModel( SPRITE_FIRE );

		g_SoundSystem.PrecacheSound( "items/9mmclip1.wav" );
		g_SoundSystem.PrecacheSound( "weapons/357_cock1.wav" );

		for( uint i = 0; i < pCSOWSounds.length(); ++i )
			g_SoundSystem.PrecacheSound( pCSOWSounds[i] );

		//Precache these for downloading
		for( uint i = 0; i < pCSOWSounds.length(); ++i )
			g_Game.PrecacheGeneric( "sound/" + pCSOWSounds[i] );

		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/weapon_balrog11.txt" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud3.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud7.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud89.spr" );
		g_Game.PrecacheGeneric( "sprites/cso/muzzleflash17.spr" );
		g_Game.PrecacheGeneric( "sprites/cso/muzzleflash27.spr" );
		g_Game.PrecacheGeneric( "sprites/cso/muzzleflash29.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= CSOW_MAX_AMMO;
		info.iMaxAmmo2 	= CSOW_MAX_AMMO2;
		info.iMaxClip 	= CSOW_MAX_CLIP;
		info.iSlot 		= CSO::BALROG11_SLOT - 1;
		info.iPosition 	= CSO::BALROG11_POSITION - 1;
		info.iFlags 	= 0;
		info.iWeight 	= CSOW_WEIGHT;

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer(pPlayer) )
			return false;

		@m_pPlayer = pPlayer;

		NetworkMessage balrog11( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			balrog11.WriteLong( g_ItemRegistry.GetIdForName("weapon_balrog11") );
		balrog11.End();

		return true;
	}

	bool PlayEmptySound()
	{
		if( self.m_bPlayEmptySound )
		{
			self.m_bPlayEmptySound = false;
			
			g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_EMPTY], 0.8f, ATTN_NORM );
		}
		
		return false;
	}

	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model(MODEL_VIEW), self.GetP_Model(MODEL_PLAYER), ANIM_DRAW, "saw" );
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DRAW;
			return bResult;
		}
	}

	void Holster( int skipLocal = 0 )
	{
		SetThink(null);
		self.m_fInReload = false;
		m_iShotgunReload = 0;
		m_iShotsFired = 0;

		BaseClass.Holster( skipLocal );
	}

	~weapon_balrog11()
	{
		SetThink(null);
		self.m_fInReload = false;
		m_iShotgunReload = 0;
		m_iShotsFired = 0;
	}

	void PrimaryAttack()
	{
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = g_Engine.time + 0.15f;
			return;
		}

		if( self.m_iClip <= 0 )
		{
			Reload(); //self. ??

			if( self.m_iClip == 0 )
				self.PlayEmptySound();

			self.m_flNextPrimaryAttack = g_Engine.time + 1.0f;

			return;
		}

		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;

		--self.m_iClip;

		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		self.SendWeaponAnim( Math.RandomLong(ANIM_SHOOT1, ANIM_SHOOT2) );

		Vector vecShellVelocity, vecShellOrigin;
		CS16GetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, CSOW_VECTOR_EJECT.x, CSOW_VECTOR_EJECT.y, CSOW_VECTOR_EJECT.z, false, false );
		g_EntityFuncs.EjectBrass( vecShellOrigin, vecShellVelocity, m_pPlayer.pev.angles.y, g_EngineFuncs.ModelIndex(MODEL_SHELL), TE_BOUNCE_SHOTSHELL );

		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SHOOT1], 1.0f, ATTN_NORM, 0, 94 + Math.RandomLong(0, 0xf) );

		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		Vector vecSrc	 = m_pPlayer.GetGunPosition();
		Vector vecAiming = g_Engine.v_forward;

		float flDamage = CSOW_DAMAGE1;
		if( self.m_flCustomDmg > 0 )
			flDamage = self.m_flCustomDmg;

		m_pPlayer.FireBullets( CSOW_PELLETCOUNT, vecSrc, vecAiming, CSOW_VECTOR_SPREAD, 8192.0f, BULLET_PLAYER_CUSTOMDAMAGE, 0, 0 );
		CSO::CreateShotgunPelletDecals( m_pPlayer, vecSrc, vecAiming, CSOW_VECTOR_SPREAD, CSOW_PELLETCOUNT, flDamage, (DMG_BULLET | DMG_LAUNCH | DMG_NEVERGIB) );

		if( m_iShotsFired == 3 )
		{
			if( m_pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType) < CSOW_MAX_AMMO2 )
			{
				m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType, m_pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType) + 1 );
				g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_ITEM, pCSOWSounds[SND_CHARGE], 1.0f, ATTN_NORM );
			}
		}
		else if( m_iShotsFired == 4 )
			m_iShotsFired = 0;

		++m_iShotsFired;

		if( self.m_iClip <= 0 and m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 )
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

		self.m_flNextPrimaryAttack = g_Engine.time + CSOW_DELAY1;
		self.m_flNextSecondaryAttack = g_Engine.time + CSOW_DELAY1;

		if( self.m_iClip > 0 )
			self.m_flTimeWeaponIdle = g_Engine.time + 2.25f;
		else
			self.m_flTimeWeaponIdle = 0.75f;

		m_iShotgunReload = 0;

		if( (m_pPlayer.pev.flags & FL_ONGROUND) != 0 )
			m_pPlayer.pev.punchangle.x -= g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed + 1, (CSOW_VEC2D_RECOIL.x/2), (CSOW_VEC2D_RECOIL.y/2) );
		else
			m_pPlayer.pev.punchangle.x -= g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed + 1, CSOW_VEC2D_RECOIL.x, CSOW_VEC2D_RECOIL.y );
	}

	void SecondaryAttack()
	{
		int ammo2 = m_pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType);
		if( ammo2 <= 0 )
			return;

		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CSOW_DELAY2;
		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_DELAY2 + 0.5f;

		--ammo2;
		m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType, ammo2 );

		self.SendWeaponAnim( ANIM_SHOOT_BCS );

		Vector vecShellVelocity, vecShellOrigin;
		CS16GetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, CSOW_VECTOR_EJECT.x, CSOW_VECTOR_EJECT.y, CSOW_VECTOR_EJECT.z, false, false );
		g_EntityFuncs.EjectBrass( vecShellOrigin, vecShellVelocity, m_pPlayer.pev.angles.y, g_EngineFuncs.ModelIndex(MODEL_SHELL_SPECIAL), TE_BOUNCE_SHOTSHELL );

		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SHOOT2], 1.0f, ATTN_NORM, 0, PITCH_LOW );
		Create_FireSystem();
		m_flNextSpecialExplosion = g_Engine.time + 0.25f;
	}

	void Reload()
	{
		int ammo = m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType);

		if( ammo <= 0 or self.m_iClip >= CSOW_MAX_CLIP )
			return;

		if( self.m_flNextPrimaryAttack > g_Engine.time )
			return;

		m_iShotsFired = 0;

		if( m_iShotgunReload <= 0 )
		{
			m_pPlayer.SetAnimation(PLAYER_RELOAD);
			self.SendWeaponAnim( ANIM_START_RELOAD );

			m_iShotgunReload = 1;
			self.m_flTimeWeaponIdle = g_Engine.time + 0.55f;
			//self.m_flNextPrimaryAttack = g_Engine.time + 0.55f; //prevents firing while reloading
			//self.m_flNextSecondaryAttack = g_Engine.time + 0.55f; //prevents firing while reloading
		}
		else if( m_iShotgunReload == 1 )
		{
			if( self.m_flTimeWeaponIdle > g_Engine.time )
				return;

			m_iShotgunReload = 2;

			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, pCSOWSounds[SND_INSERT], VOL_NORM, ATTN_NORM, 0, 85 + Math.RandomLong(0, 31) ); //0x1f

			m_pPlayer.SetAnimation(PLAYER_RELOAD);
			self.SendWeaponAnim( ANIM_INSERT );

			self.m_iClip++;
			ammo--;
			m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType, ammo);

			self.m_flTimeWeaponIdle = g_Engine.time + 0.3f;
		}
		else
		{
			/*self.m_iClip++;
			ammo--;
			m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType, ammo);*/
			m_iShotgunReload = 1;
		}

		//BaseClass.Reload(); //needed??
	}

	void ItemPostFrame()
	{
		if( (m_pPlayer.pev.button & IN_ATTACK) == 0 ) m_iShotsFired = 0;

		/*if( m_flNextSpecialExplosion > 0 and g_Engine.time > m_flNextSpecialExplosion )
		{
			Check_RadiusDamage();
			m_flNextSpecialExplosion = 0;
		}*/

		BaseClass.ItemPostFrame();
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		if( self.m_flTimeWeaponIdle < g_Engine.time )
		{
			m_iShotsFired = 0;

			if( self.m_iClip == 0 and m_iShotgunReload == 0 and m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) > 0 )
				Reload();
			else if( m_iShotgunReload != 0 )
			{
				if( self.m_iClip != CSOW_MAX_CLIP and m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) > 0 )
					Reload();
				else
				{
					self.SendWeaponAnim( ANIM_AFTER_RELOAD );

					m_iShotgunReload = 0;
					self.m_flTimeWeaponIdle = g_Engine.time + 1.5f;
				}
			}
			else
			{
				self.SendWeaponAnim( ANIM_IDLE );
				self.m_flTimeWeaponIdle = g_Engine.time + 3.3f;
			}
		}
	}

	void Create_FireSystem()
	{
		Vector vecStartOrigin;
		array<Vector> arr_vecTargetOrigin(CSOW_FIREBALLS_AMOUNT);
		array<float> arr_flSpeed(CSOW_FIREBALLS_AMOUNT);

		// -- Left
		get_position( 100.0f, Math.RandomFloat(-10.0f, -30.0f), -5.0f, arr_vecTargetOrigin[0] );
		arr_flSpeed[0] = 210.0f * CSOW_FIREBALLS_SPEED;
		get_position( 100.0f, Math.RandomFloat(-10.0f, -20.0f), -5.0f, arr_vecTargetOrigin[1] );
		arr_flSpeed[1] = 240.0f * CSOW_FIREBALLS_SPEED;
		get_position( 100.0f, Math.RandomFloat(-10.0f, -10.0f), -5.0f, arr_vecTargetOrigin[2] );
		arr_flSpeed[2] = 300.0f * CSOW_FIREBALLS_SPEED;

		// -- Center
		get_position( 100.0f, 0.0f, -5.0f, arr_vecTargetOrigin[3]);
		arr_flSpeed[3] = 200.0f * CSOW_FIREBALLS_SPEED;
		get_position( 100.0f, 0.0f, -5.0f, arr_vecTargetOrigin[4]);
		arr_flSpeed[4] = 200.0f * CSOW_FIREBALLS_SPEED;

		// -- Right
		get_position( 100.0f, Math.RandomFloat(10.0f, 10.0f), -5.0f, arr_vecTargetOrigin[5]);
		arr_flSpeed[5] = 150.0f * CSOW_FIREBALLS_SPEED;
		get_position( 100.0f, Math.RandomFloat(10.0f, 20.0f) , -5.0f, arr_vecTargetOrigin[6]);
		arr_flSpeed[6] = 180.0f * CSOW_FIREBALLS_SPEED;
		get_position( 100.0f, Math.RandomFloat(10.0f, 30.0f), -5.0f, arr_vecTargetOrigin[7]);
		arr_flSpeed[7] = 210.0f * CSOW_FIREBALLS_SPEED;

		for( int i = 0; i < CSOW_FIREBALLS_AMOUNT; i++ )
		{
			get_position( Math.RandomFloat(30.0f, 40.0f), 0.0f, -5.0f, vecStartOrigin );
			Create_Fire( vecStartOrigin, arr_vecTargetOrigin[i], arr_flSpeed[i] );
		}
	}

	void Create_Fire( Vector vecOrigin, Vector vecTargetOrigin, float flSpeed )
	{
		CBaseEntity@ pEnt = g_EntityFuncs.Create( "balrog11_fire", vecOrigin, g_vecZero, false, m_pPlayer.edict() ); 

		if( pEnt is null ) return;
		if( !g_EntityFuncs.IsValidEntity(pEnt.edict()) ) return;

		Vector vecVelocity;

		get_speed_vector( vecOrigin, vecTargetOrigin, flSpeed * 3.0f, vecVelocity );
		pEnt.pev.velocity = vecVelocity;
	}

	/*void Check_RadiusDamage()
	{
		CBaseEntity@ pTarget = null;
		Vector vecTargetOrigin, vecMyOrigin;
		float flDamageMulti, flDmgMulti;

		vecMyOrigin = m_pPlayer.GetOrigin();

		while( (@pTarget = g_EntityFuncs.FindEntityInSphere(pTarget, vecMyOrigin, CSOW_SPECIAL_RADIUS, "*", "classname")) !is null )
		{
			if( pTarget.edict() is m_pPlayer.edict() or !pTarget.IsAlive() ) //or (!pTarget.IsMonster() and !pTarget.IsPlayer())
				continue;

			vecTargetOrigin = pTarget.GetOrigin();

			if( !m_pPlayer.FInViewCone(pTarget) ) continue;
			if( (vecMyOrigin - vecTargetOrigin).Length() > CSOW_SPECIAL_RADIUS ) continue;

			flDmgMulti = 1.1f;
			flDamageMulti = (vecMyOrigin - vecTargetOrigin).Length() / CSOW_SPECIAL_RADIUS;
			flDmgMulti -= flDamageMulti;

			pTarget.TakeDamage( g_EntityFuncs.Instance(0).pev, m_pPlayer.pev, CSOW_DAMAGE2A * flDmgMulti, DMG_BURN );

			//g_WeaponFuncs.ClearMultiDamage();
			//pTarget.TraceAttack( m_pPlayer.pev, CSOW_DAMAGE_A, g_Engine.v_forward, tr, (DMG_NEVERGIB|DMG_BULLET) );
			//g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );
		}
	}*/

	void get_position( float forw, float right, float up, Vector &out vOut )
	{
		Vector vOrigin, vAngle, vForward, vRight, vUp;

		vOrigin = m_pPlayer.pev.origin;
		vUp = m_pPlayer.pev.view_ofs; //for player, can also use GetGunPosition()
		vOrigin = vOrigin + vUp;
		vAngle = m_pPlayer.pev.v_angle; //if normal entity: use pev.angles

		g_EngineFuncs.AngleVectors( vAngle, vForward, vRight, vUp );

		vOut.x = vOrigin.x + vForward.x * forw + vRight.x * right + vUp.x * up;
		vOut.y = vOrigin.y + vForward.y * forw + vRight.y * right + vUp.y * up;
		vOut.z = vOrigin.z + vForward.z * forw + vRight.z * right + vUp.z * up;
	}
}

class balrog11_fire : ScriptBaseEntity
{
	void Spawn()
	{
		pev.movetype = MOVETYPE_FLY;
		pev.rendermode = kRenderTransAdd;
		pev.renderamt = 75.0f;
		pev.fuser1 = g_Engine.time + 0.75f;	// time remove
		pev.scale = Math.RandomFloat(0.25f, 0.75f);
		pev.nextthink = g_Engine.time + 0.05f;

		SetThink( ThinkFunction(this.MyThink) );
		SetTouch( TouchFunction(this.MyTouch) );

		g_EntityFuncs.SetModel( self, SPRITE_FIRE );
		g_EntityFuncs.SetSize( pev, Vector(-1.0f, -1.0f, -1.0f), Vector(1.0f, 1.0f, 1.0f) );

		pev.gravity = 0.01f;
		pev.solid = SOLID_TRIGGER;
		pev.frame = 0.0f;
		//pev.iuser4 = 1;
	}

	void MyThink()
	{
		g_Engine.force_retouch++;

		float flFrame, flNextThink, flScale;
		flFrame = pev.frame;
		flScale = pev.scale;

		// effect exp
		int iMoveType = pev.movetype;
		if( iMoveType == MOVETYPE_NONE )
		{
			flNextThink = 0.0015f;
			flFrame += Math.RandomFloat(0.25f, 0.75f);
			flScale += 0.01;

			if( flFrame > 21.0f )
			{
				g_EntityFuncs.Remove( self );
				return;
			}
		}
		else
		{
			flNextThink = 0.045;

			flFrame += Math.RandomFloat(0.5f, 1.0f);
			flScale += 0.001f;

			flFrame = Math.min(21.0f, flFrame);
			flScale = Math.min(1.5f, flFrame);
		}

		pev.frame = flFrame;
		pev.scale = flScale;
		pev.nextthink = g_Engine.time + flNextThink;

		// time remove
		float flTimeRemove = pev.fuser1;
		if( g_Engine.time >= flTimeRemove )
		{
			float flAmount = pev.renderamt;
			if( flAmount <= 5.0f )
			{
				g_EntityFuncs.Remove( self );
				return;
			}
			else
			{
				flAmount -= 5.0f;
				pev.renderamt = flAmount;
			}
		}
	}

	void MyTouch( CBaseEntity@ pOther )
	{
		if( pOther.GetClassname() == "balrog11_fire" ) return;

		//g_Game.AlertMessage( at_console, "Touched: %1!\n", pOther.GetClassname() );

		if( pev.owner !is null )
		{
			CBaseEntity@ cbeOwner = g_EntityFuncs.Instance(pev.owner);
			CBasePlayer@ pOwner = cast<CBasePlayer@>( cbeOwner );
			if( pOther.edict() is pOwner.edict() ) return;

			float flDmgMulti = 1.1f;
			float flDamageMulti = (pOwner.GetOrigin() - pOther.GetOrigin()).Length() / CSOW_SPECIAL_RADIUS;
			flDmgMulti -= flDamageMulti;

			pOther.TakeDamage( g_EntityFuncs.Instance(0).pev, pOwner.pev, CSOW_DAMAGE2A * flDmgMulti, DMG_BURN );
		}

		pev.solid = SOLID_NOT;

		if( pOther.IsBSPModel()/* and pOther.GetClassname() != "func_breakable"*/ ) //todo
			pev.movetype = MOVETYPE_NONE;
	}
}

void get_speed_vector( const Vector &in origin1, const Vector &in origin2, const float &in speed, Vector &out new_velocity )
{
	new_velocity.y = origin2.y - origin1.y;
	new_velocity.x = origin2.x - origin1.x;
	new_velocity.z = origin2.z - origin1.z;

	float num = sqrt( speed*speed / (new_velocity.y*new_velocity.y + new_velocity.x*new_velocity.x + new_velocity.z*new_velocity.z) );
	new_velocity.y *= num;
	new_velocity.x *= num;
	new_velocity.z *= num;
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_balrog11::balrog11_fire", "balrog11_fire" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_balrog11::weapon_balrog11", "weapon_balrog11" );
	g_ItemRegistry.RegisterWeapon( "weapon_balrog11", "custom_weapons/cso", "buckshot", "b11shot", "ammo_buckshot" );
}

} //namespace cso_balrog11 END