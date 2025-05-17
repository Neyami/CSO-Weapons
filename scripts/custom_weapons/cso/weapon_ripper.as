namespace cso_ripper
{

const int CSOW_DEFAULT_GIVE					= 200;
const int CSOW_MAX_CLIP 						= 200;
const int CSOW_DAMAGE1							= 20;
const float CSOW_RANGE1							= 90;
const float CSOW_RADIUS1						= 90;
const float CSOW_DAMAGE2						= 85;
const float CSOW_RANGE2							= 75;
const float CSOW_RADIUS2						= 120;
const float CSOW_KNOCKBACK					= 250;
const float CSOW_TIME_DRAW					= 1.5;
const float CSOW_TIME_RELOAD				= 3.0;
const float CSOW_TIME_DELAY1					= 0.075;
const float CSOW_TIME_DELAY2					= 1.2;
const float CSOW_TIME_IDLE						= 5.0;

const string CSOW_ANIMEXT	= "minigun";

const string MODEL_VIEW		= "models/custom_weapons/cso/v_chainsaw.mdl";
const string MODEL_PLAYER	= "models/custom_weapons/cso/p_chainsaw.mdl";
const string MODEL_WORLD	= "models/custom_weapons/cso/w_chainsaw.mdl";

enum csow_e
{
	ANIM_IDLE = 0,
	ANIM_DRAW,
	ANIM_DRAW_EMPTY,
	ANIM_ATTACK1_START,
	ANIM_ATTACK1_LOOP,
	ANIM_ATTACK1_END,
	ANIM_RELOAD,
	ANIM_SLASH1,
	ANIM_SLASH2,
	ANIM_SLASH3,
	ANIM_SLASH4,
	ANIM_EMPTY
};

enum csowsounds_e
{
	SND_ATTACK1_END = 0,
	SND_ATTACK1_LOOP,
	SND_ATTACK1_START,
	SND_HIT1,
	SND_HIT2,
	SND_HIT3,
	SND_HIT4,
	SND_IDLE
};

const array<string> pCSOWSounds =
{
	"custom_weapons/cso/chainsaw_attack1_end.wav",
	"custom_weapons/cso/chainsaw_attack1_loop.wav",
	"custom_weapons/cso/chainsaw_attack1_start.wav",
	"custom_weapons/cso/chainsaw_hit1.wav",
	"custom_weapons/cso/chainsaw_hit2.wav",
	"custom_weapons/cso/chainsaw_hit3.wav",
	"custom_weapons/cso/chainsaw_hit4.wav",
	"custom_weapons/cso/chainsaw_idle.wav",
	"custom_weapons/cso/chainsaw_draw.wav",
	"custom_weapons/cso/chainsaw_draw1.wav",
	"custom_weapons/cso/chainsaw_reload.wav",
	"custom_weapons/cso/chainsaw_slash1.wav",
	"custom_weapons/cso/chainsaw_slash2.wav",
	"custom_weapons/cso/chainsaw_slash3.wav",
	"custom_weapons/cso/chainsaw_slash4.wav"
};

enum csowstate_e
{
	STATE_NONE = 0,
	STATE_LOOP,
	STATE_END
};

class weapon_ripper : CBaseCSOWeapon
{
	private int m_iWeaponState;

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, MODEL_WORLD );
		self.m_iDefaultAmmo = CSOW_DEFAULT_GIVE;
		self.m_flCustomDmg = pev.dmg;

		m_iWeaponState = STATE_NONE;
		g_iCSOWHands = HANDS_SVENCOOP;
		m_bSwitchHands = true;

		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();

		uint i;

		g_Game.PrecacheModel( MODEL_VIEW );
		g_Game.PrecacheModel( MODEL_PLAYER );
		g_Game.PrecacheModel( MODEL_WORLD );

		if( cso::bUseDroppedItemEffect )
			g_Game.PrecacheModel( cso::CSO_ITEMDISPLAY_MODEL );

		for( i = 0; i < pCSOWSounds.length(); ++i )
			g_SoundSystem.PrecacheSound( pCSOWSounds[i] );

		//Precache these for downloading
		for( i = 0; i < pCSOWSounds.length(); ++i )
			g_Game.PrecacheGeneric( "sound/" + pCSOWSounds[i] );

		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/weapon_ripper.txt" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud21.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud84.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= cso::MAXCARRY_GASOLINE;
		info.iMaxClip		= CSOW_MAX_CLIP;
		info.iSlot				= cso::RIPPER_SLOT - 1;
		info.iPosition		= cso::RIPPER_POSITION - 1;
		info.iWeight			= cso::RIPPER_WEIGHT;
		info.iFlags			= ITEM_FLAG_SELECTONEMPTY | ITEM_FLAG_NOAUTOSWITCHEMPTY;

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer(pPlayer) )
			return false;

		@m_pPlayer = pPlayer;

		NetworkMessage m( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			m.WriteLong( g_ItemRegistry.GetIdForName("weapon_ripper") );
		m.End();

		return true;
	}

	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model(MODEL_VIEW), self.GetP_Model(MODEL_PLAYER), ANIM_DRAW, CSOW_ANIMEXT, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DRAW;

			return bResult;
		}
	}

	void Holster( int skiplocal )
	{
		g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_STATIC, pCSOWSounds[SND_IDLE] );
		g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_ATTACK1_LOOP] );
		m_iWeaponState = STATE_NONE;

		SetThink( null );
	}

	void PrimaryAttack()
	{
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD or self.m_iClip <= 0 )
		{
			//self.PlayEmptySound();
			self.m_flNextPrimaryAttack = g_Engine.time + 0.2;

			return;
		}

		switch( m_iWeaponState )
		{
			case STATE_NONE:
			{
				self.SendWeaponAnim( ANIM_ATTACK1_START, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
				g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_STATIC, pCSOWSounds[SND_ATTACK1_START], VOL_NORM, ATTN_NORM );
				g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_IDLE] );

				m_iWeaponState = STATE_LOOP;
				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.5;

				break;
			}

			case STATE_LOOP:
			{
				if( m_pPlayer.pev.weaponanim != ANIM_ATTACK1_LOOP )
					self.SendWeaponAnim( ANIM_ATTACK1_LOOP, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );

				float flDamage = CSOW_DAMAGE1;
				if( self.m_flCustomDmg > 0 )
					flDamage = self.m_flCustomDmg;

				CheckMeleeAttack( CSOW_RANGE1, CSOW_RADIUS1, flDamage, false );

				g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_ATTACK1_LOOP], 0.8, ATTN_NORM );

				Vector vecRecoil;
				vecRecoil.x = Math.RandomFloat( -1.0, 1.0 );
				vecRecoil.y = Math.RandomFloat( -1.0, 1.0 );
				m_pPlayer.pev.punchangle = vecRecoil;

				m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

				HandleAmmoReduction( 1 );
				self.m_flNextPrimaryAttack = g_Engine.time + CSOW_TIME_DELAY1;
				self.m_flTimeWeaponIdle = self.m_flNextSecondaryAttack = g_Engine.time + 0.5;

				break;
			}
		}
	}

	void SecondaryAttack()
	{
		if( self.m_iClip > 0 )
			self.SendWeaponAnim( Math.RandomLong(ANIM_SLASH1, ANIM_SLASH2), 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
		else
			self.SendWeaponAnim( Math.RandomLong(ANIM_SLASH3, ANIM_SLASH4), 0, (m_bSwitchHands ? g_iCSOWHands : 0) );

		Vector vecRecoil;
		vecRecoil.x = -5.0;
		vecRecoil.y = Math.RandomFloat( -2.5, 2.5 );
		m_pPlayer.pev.punchangle = vecRecoil;

		float flDamage = CSOW_DAMAGE2;
		if( self.m_flCustomDmg > 0 )
			flDamage = self.m_flCustomDmg;

		CheckMeleeAttack( CSOW_RANGE2, CSOW_RADIUS2, flDamage, true );

		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_DELAY2;
	}

	void Reload()
	{
		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 or self.m_iClip >= CSOW_MAX_CLIP )
			return;

		self.DefaultReload( CSOW_MAX_CLIP, ANIM_RELOAD, CSOW_TIME_RELOAD, (m_bSwitchHands ? g_iCSOWHands : 0) );
		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_RELOAD;

		BaseClass.Reload();
	}

	void WeaponIdle()
	{
		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		if( self.m_iClip <= 0 )
			self.SendWeaponAnim( ANIM_EMPTY, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
		else
		{
			self.SendWeaponAnim( ANIM_IDLE, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
			g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_IDLE], 0.8, ATTN_NORM );
		}

		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_IDLE;
	}

	void ItemPostFrame()
	{
		switch( m_iWeaponState )
		{
			case STATE_LOOP:
			{
				if( (m_pPlayer.pev.weaponanim == ANIM_ATTACK1_START or m_pPlayer.pev.weaponanim == ANIM_ATTACK1_LOOP) and (m_pPlayer.pev.button & IN_ATTACK) == 0 or self.m_iClip <= 0 )
					m_iWeaponState = STATE_END;

				break;
			}

			case STATE_END:
			{
				self.SendWeaponAnim( ANIM_ATTACK1_END, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );

				m_iWeaponState = STATE_NONE;
				g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_ATTACK1_LOOP] );
				g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_STATIC, pCSOWSounds[SND_ATTACK1_END], 0.8, ATTN_NORM );

				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 1.5;

				break;
			}
		}

		BaseClass.ItemPostFrame();
	}

	void CheckMeleeAttack( float flRange, float flRadius, float flDamage, bool bSlash )
	{
		int iTarget = MeleeAttack( flRange, flRadius, flDamage, bSlash );
		if( iTarget != HIT_NOTHING )
		{
			int iSound = self.m_iClip > 0 ? Math.RandomLong(SND_HIT1, SND_HIT2) : Math.RandomLong(SND_HIT3, SND_HIT4);
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, pCSOWSounds[iSound], VOL_NORM, ATTN_NORM );
		}
	}

	int MeleeAttack( float flRange, float flRadius, float flDamage, bool bSlash )
	{
		float flFOV = bSlash ? 0.5 : VIEW_FIELD_ULTRA_NARROW;

		Vector vecTargetOrigin, vecMyOrigin;
		vecMyOrigin = m_pPlayer.pev.origin;

		int iHitSomething = HIT_NOTHING;
		CBaseEntity@ pTarget = null;

		while( (@pTarget = g_EntityFuncs.FindEntityInSphere(pTarget, m_pPlayer.pev.origin, flRadius*4, "*", "classname")) !is null )
		{
			if( pTarget.edict() is m_pPlayer.edict() or (!pTarget.IsMonster() and !pTarget.IsPlayer()) or !pTarget.IsAlive() )
				continue;

			m_pPlayer.m_flFieldOfView = flFOV;

			if( !m_pPlayer.FInViewCone(pTarget) ) continue;

			m_pPlayer.m_flFieldOfView = 0.5;

			vecTargetOrigin = pTarget.pev.origin + Vector( 0, 0, (pTarget.pev.size.z/2) );

			if( (m_pPlayer.pev.origin - vecTargetOrigin).Length() > flRange ) continue;

			vecTargetOrigin = pTarget.pev.origin;

			if( is_wall_between_points(vecMyOrigin, vecTargetOrigin, m_pPlayer.edict()) ) continue;

			iHitSomething = HIT_ENEMY;

			Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );

			if( !bSlash )
			{
				TraceResult tr = g_Utility.GetGlobalTrace();
				g_WeaponFuncs.ClearMultiDamage();
				pTarget.TraceAttack( m_pPlayer.pev, flDamage, g_Engine.v_forward, tr, DMG_SLASH );
				g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );

			}
			else
			{
				float flKnockback = CSOW_KNOCKBACK;
				if( self.m_iClip <= 0 )
				{
					flDamage *= 0.5; //Deal half damage if out of gas
					flKnockback *= 0.5;
				}

				pTarget.TakeDamage( m_pPlayer.pev, m_pPlayer.pev, flDamage, DMG_SLASH ); 
				//pTarget.pev.solid = SOLID_NOT; //TODO if multiple mobs are close to each other, they don't get knocked back. Spawn an entity that checks if the mob is still alive and reset pev.solid ??

				if( cso::g_arrsKnockbackImmuneMobs.find(pTarget.GetClassname()) < 0 )
				{
					pTarget.pev.velocity = (pTarget.Center() - m_pPlayer.pev.origin).Normalize() * flKnockback;
					pTarget.pev.velocity.z += 200.0;
				}
			}

			g_Utility.BloodDrips( pTarget.Center(), g_vecZero, pTarget.BloodColor(), int(Math.min(Math.max(3,flDamage/10),16)) );
			g_Utility.BloodDrips( m_pPlayer.GetGunPosition() + g_Engine.v_forward * 16.0 + g_Engine.v_right * 2.0 + g_Engine.v_up * 1.0, g_vecZero, pTarget.BloodColor(), int(Math.min(Math.max(3,flDamage/10),16)) ); //Blood at the tip of the chainsaw
			g_Utility.BloodStream( pTarget.Center(), g_Engine.v_forward, pTarget.BloodColor(), int(flDamage) );
		}

		if( iHitSomething != HIT_ENEMY )
		{
			Vector vecWallCheck;
			vecMyOrigin.z += 26.0;
			get_position( flRange, 0.0, 0.0, vecWallCheck );

			TraceResult tr;
			g_Utility.TraceLine( vecMyOrigin, vecWallCheck, ignore_monsters, m_pPlayer.edict(), tr );

			if( (vecWallCheck - tr.vecEndPos).Length() > 0 )
			{
				CBaseEntity@ pEntity = g_EntityFuncs.Instance(tr.pHit);

				if( pEntity !is null and pEntity.IsBSPModel() )
				{
					g_WeaponFuncs.ClearMultiDamage();
					pEntity.TraceAttack( m_pPlayer.pev, flDamage, g_Engine.v_forward, tr, DMG_SLASH );
					g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );
				}

				iHitSomething = HIT_WALL;

				NetworkMessage m1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
					m1.WriteByte( TE_STREAK_SPLASH );
					m1.WriteCoord( tr.vecEndPos.x );
					m1.WriteCoord( tr.vecEndPos.y );
					m1.WriteCoord( tr.vecEndPos.z );
					m1.WriteCoord( tr.vecPlaneNormal.x * Math.RandomFloat(25.0, 30.0) );
					m1.WriteCoord( tr.vecPlaneNormal.y * Math.RandomFloat(25.0, 30.0) );
					m1.WriteCoord( tr.vecPlaneNormal.z * Math.RandomFloat(25.0, 30.0) );
					m1.WriteByte( 1 ); //color
					m1.WriteShort( 20 ); //count
					m1.WriteShort( 3 ); //speed
					m1.WriteShort( 90 ); //velocity
				m1.End();

				NetworkMessage m2( MSG_PAS, NetworkMessages::SVC_TEMPENTITY, tr.vecEndPos );
					m2.WriteByte( TE_EXPLOSION );
					m2.WriteCoord( tr.vecEndPos.x );
					m2.WriteCoord( tr.vecEndPos.y );
					m2.WriteCoord( tr.vecEndPos.z - 10.0 );
					m2.WriteShort( g_EngineFuncs.ModelIndex(cso::pSmokeSprites[Math.RandomLong(1, 4)]) );
					m2.WriteByte( 2 ); //scale
					m2.WriteByte( 100 ); //framerate
					m2.WriteByte( TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOSOUND );
				m2.End();
			}
		}

		return iHitSomething;
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_ripper::weapon_ripper", "weapon_ripper" );
	g_ItemRegistry.RegisterWeapon( "weapon_ripper", "custom_weapons/cso", "gasoline", "", "ammo_gasoline" );

	if( !g_CustomEntityFuncs.IsCustomEntity( "ammo_gasoline" ) ) 
		cso::RegisterGasoline();

	if( cso::bUseDroppedItemEffect )
	{
		if( !g_CustomEntityFuncs.IsCustomEntity( "ef_gundrop" ) )
			cso::RegisterGunDrop();
	}
}

} //namespace cso_ripper END