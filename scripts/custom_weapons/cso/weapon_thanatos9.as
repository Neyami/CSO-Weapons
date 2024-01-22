namespace cso_thanatos9
{

const float CSOW_DAMAGE_A			= 1000;
const float CSOW_DAMAGE_B			= 500;

const float CSOW_TIME_DRAW			= 1.5f;
const float CSOW_TIME_DELAY1		= 0.9f;

const float CSOW_TIME_MODEA_CHANGE	= 5.0f;
const float CSOW_TIME_MODEB_HITRATE	= 0.75f;
const float CSOW_TIME_MODEB_ATTACK	= 5.0f;
const float CSOW_TIME_MODEB_CHANGE	= 3.5f;

const float CSOW_RADIUS1			= 100;

const string MODEL_VIEW				= "models/custom_weapons/cso/v_thanatos9.mdl";
const string MODEL_PLAYER_MODEA		= "models/custom_weapons/cso/p_thanatos9a.mdl";
const string MODEL_PLAYER_MODEB		= "models/custom_weapons/cso/p_thanatos9b.mdl";
const string MODEL_PLAYER_MODEC		= "models/custom_weapons/cso/p_thanatos9c.mdl";
const string MODEL_WORLD			= "models/custom_weapons/cso/w_thanatos9.mdl";

const string CSOW_ANIMEXT_MODEA		= "crowbar"; //knife
const string CSOW_ANIMEXT_MODEB		= "saw"; //m249

enum csow_e
{
	ANIM_IDLEA = 0,
	ANIM_DRAWA,
	ANIM_SHOOTA1,
	ANIM_SHOOTA2,
	ANIM_CHANGEA,
	ANIM_IDLEB,
	ANIM_DRAWB,
	ANIM_SHOOTB_START,
	ANIM_SHOOTB_LOOP,
	ANIM_SHOOTB_END,
	ANIM_CHANGEB
};

enum csowsounds_e
{
	SND_SHOOTA_1 = 0,
	SND_SHOOTA_2,
	SND_SHOOTB_END,
	SND_SHOOTB_LOOP,
	SND_DRAW,
	SND_CHANGEA_1,
	SND_CHANGEA_2,
	SND_CHANGEA_3,
	SND_CHANGEA_4,
	SND_CHANGEB_1,
	SND_CHANGEB_2,
	SND_HIT,
	SND_HIT_WALL,
	SND_MODEB_HIT_WALL
};

const array<string> pCSOWSounds =
{
	"custom_weapons/cso/thanatos9_shoota1.wav",
	"custom_weapons/cso/thanatos9_shoota2.wav",
	"custom_weapons/cso/thanatos9_shootb_end.wav",
	"custom_weapons/cso/thanatos9_shootb_loop.wav",
	"custom_weapons/cso/thanatos9_drawa.wav",
	"custom_weapons/cso/thanatos9_changea_1.wav",
	"custom_weapons/cso/thanatos9_changea_2.wav",
	"custom_weapons/cso/thanatos9_changea_3.wav",
	"custom_weapons/cso/thanatos9_changea_4.wav",
	"custom_weapons/cso/thanatos9_changeb_1.wav",
	"custom_weapons/cso/thanatos9_changeb_2.wav",
	"custom_weapons/cso/mastercombat_hit1.wav",
	"custom_weapons/cso/nata_wall.wav",
	"custom_weapons/cso/tomahawk_wall.wav"
};

enum t9states_e
{
	STATE_MODEA			= 1,
	STATE_CHANGING		= 2,
	STATE_MODEB			= 4,
	STATE_MODEB_LOOP	= 8
};

class weapon_thanatos9 : CBaseCSOWeapon
{
	private int g_SmokePuff_SprId;
	private int m_iWeaponState;
	private int m_iSwing;

	private uint m_uiSmokeState;

	private float m_flModeBNextHit;
	private float m_flTimeToChangeToA;
	private float m_flTimeToChangeToB;
	private float m_flPlayWallHitSound;
	private float m_flPlayBodyHitSound;

	void Spawn()
	{
		self.Precache();
		g_EntityFuncs.SetModel( self, MODEL_WORLD );
		self.m_iClip = WEAPON_NOCLIP;
		self.m_flCustomDmg = pev.dmg;
		self.FallInit();
	}

	//~18?
	void Precache()
	{
		self.PrecacheCustomModels();

		uint i;

		g_Game.PrecacheModel( MODEL_VIEW );
		g_Game.PrecacheModel( MODEL_PLAYER_MODEA );
		g_Game.PrecacheModel( MODEL_PLAYER_MODEB );
		g_Game.PrecacheModel( MODEL_PLAYER_MODEC );
		g_Game.PrecacheModel( MODEL_WORLD );

		g_SmokePuff_SprId = g_Game.PrecacheModel( "sprites/custom_weapons/cso/smoke_thanatos9.spr" );

		for( i = 0; i < pCSOWSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pCSOWSounds[i] );

		//Precache these for downloading
		for( i = 0; i < pCSOWSounds.length(); i++ )
			g_Game.PrecacheGeneric( "sound/" + pCSOWSounds[i] );

		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/weapon_thanatos9.txt" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud79.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1		= -1;
		info.iMaxAmmo2		= -1;
		info.iMaxClip		= 0; //WEAPON_NOCLIP;
		info.iSlot			= CSO::THANATOS9_SLOT - 1;
		info.iPosition		= CSO::THANATOS9_POSITION - 1;
		info.iWeight		= CSO::THANATOS9_WEIGHT;

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer(pPlayer) )
			return false;

		@m_pPlayer = pPlayer;
		m_iWeaponState = STATE_MODEA;
		m_uiSmokeState = 0;
		m_flPlayWallHitSound = 0;
		m_flPlayBodyHitSound = 0;

		NetworkMessage m( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			m.WriteLong( g_ItemRegistry.GetIdForName("weapon_thanatos9") );
		m.End();

		return true;
	}

	bool Deploy()
	{
		bool bResult;
		{
			m_iSwing = 0;
			m_iWeaponState &= ~STATE_CHANGING;
			m_iWeaponState &= ~STATE_MODEB_LOOP;

			if( (m_iWeaponState & STATE_MODEB) == 0 )
				bResult = self.DefaultDeploy( self.GetV_Model(MODEL_VIEW), self.GetP_Model(MODEL_PLAYER_MODEA), ANIM_DRAWA, CSOW_ANIMEXT_MODEA );
			else
				bResult = self.DefaultDeploy( self.GetV_Model(MODEL_VIEW), self.GetP_Model(MODEL_PLAYER_MODEB), ANIM_DRAWB, CSOW_ANIMEXT_MODEB );

			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DRAW;

			return bResult;
		}
	}

	void Holster( int skipLocal = 0 )
	{
		SetThink(null);

		if( (m_iWeaponState & (STATE_MODEB | STATE_CHANGING)) == (STATE_MODEB | STATE_CHANGING) )
			m_iWeaponState = STATE_MODEA;

		m_iWeaponState &= ~STATE_CHANGING;
		m_iWeaponState &= ~STATE_MODEB_LOOP;
		m_flTimeToChangeToA = 0;
		m_flTimeToChangeToB = 0;
		g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SHOOTB_LOOP] );

		BaseClass.Holster( skipLocal );
	}

	~weapon_thanatos9()
	{
		SetThink(null);

		if( (m_iWeaponState & (STATE_MODEB | STATE_CHANGING)) == (STATE_MODEB | STATE_CHANGING) )
			m_iWeaponState = STATE_MODEA;

		m_iWeaponState &= ~STATE_CHANGING;
		m_iWeaponState &= ~STATE_MODEB_LOOP;
		m_flTimeToChangeToA = 0;
		m_flTimeToChangeToB = 0;
		g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SHOOTB_LOOP] );
		g_Game.AlertMessage( at_console, "weapon_thanatos9 has been destroyed via ~ \n");
	}

	void PrimaryAttack()
	{
		if( (m_iWeaponState & STATE_MODEB_LOOP) != 0 ) return;

		if( (m_iWeaponState & STATE_MODEB) == 0 )
		{
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DELAY1 + 0.25f;
			self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_DELAY1 + 0.75f;

			switch( (m_iSwing++) % 2 )
			{
				case 0: self.SendWeaponAnim( ANIM_SHOOTA1 ); g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SHOOTA_1], VOL_NORM, ATTN_NORM ); break;
				case 1: self.SendWeaponAnim( ANIM_SHOOTA2 ); g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SHOOTA_2], VOL_NORM, ATTN_NORM ); break;
			}

			m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

			SetThink( ThinkFunction(this.Check_Slashing) );
			pev.nextthink = g_Engine.time + CSOW_TIME_DELAY1;
		}
		else
		{
			if( (m_iWeaponState & STATE_MODEB_LOOP) == 0 )
			{
				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.5f;
				self.m_flTimeWeaponIdle = g_Engine.time + 1.0f;
				self.SendWeaponAnim( ANIM_SHOOTB_START );

				SetThink( ThinkFunction(this.Activate_ModeBAttack) );
				pev.nextthink = g_Engine.time + 0.45f;
			}
		}
	}

	void SecondaryAttack()
	{
		if( (m_iWeaponState & STATE_CHANGING) != 0 or (m_iWeaponState & STATE_MODEB_LOOP) != 0 )
			return;

		m_iWeaponState |= STATE_CHANGING;
		m_flModeBNextHit = g_Engine.time + CSOW_TIME_MODEB_HITRATE;

		if( (m_iWeaponState & STATE_MODEB) == 0 )
		{
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_MODEA_CHANGE + 0.25f;
			self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_MODEA_CHANGE + 0.75f;

			self.SendWeaponAnim( ANIM_CHANGEA );

			m_uiSmokeState = 0;
			SetThink( ThinkFunction(this.Create_Smoke) );
			pev.nextthink = g_Engine.time + 1.0f;

			m_flTimeToChangeToB = g_Engine.time + 3.0f;
		}
		else
		{
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_MODEB_CHANGE + 0.25f;
			self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_MODEB_CHANGE + 0.75f;

			self.SendWeaponAnim( ANIM_CHANGEB );

			m_uiSmokeState = 0;
			SetThink( ThinkFunction(this.Create_Smoke) );
			pev.nextthink = g_Engine.time + 2.0f;

			m_flTimeToChangeToA = g_Engine.time + (CSOW_TIME_MODEB_CHANGE - 0.25f);
		}
	}

	void Reload()
	{
		g_Game.AlertMessage( at_console, "m_iWeaponState: %1\n", m_iWeaponState );
	}

	void WeaponIdle()
	{
		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		if( (m_iWeaponState & STATE_MODEB_LOOP) != 0 ) self.SendWeaponAnim( ANIM_SHOOTB_LOOP );
		else if( (m_iWeaponState & STATE_MODEB) != 0 ) self.SendWeaponAnim( ANIM_IDLEB );
		else self.SendWeaponAnim( ANIM_IDLEA );

		self.m_flTimeWeaponIdle = g_Engine.time + 20.0f;
	}

	void ItemPostFrame()
	{
		if( m_flTimeToChangeToB > 0 and g_Engine.time > m_flTimeToChangeToB )
		{
			m_flTimeToChangeToB = 0;
			Remove_Smoke();
		}

		if( m_flTimeToChangeToA > 0 and g_Engine.time > m_flTimeToChangeToA )
		{
			m_flTimeToChangeToA = 0;
			SetThink(null);
			Change_Thanatos9();
		}

		if( (m_iWeaponState & STATE_MODEB_LOOP) != 0 )
		{
			if( (g_Engine.time - 0.085) > m_flModeBNextHit )
			{
				//ExecuteHamB(Ham_Weapon_PrimaryAttack, Ent)
				ModeBAttack();

				g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SHOOTB_LOOP], VOL_NORM, ATTN_NORM );

				if( m_pPlayer.pev.weaponanim != ANIM_SHOOTB_LOOP )
					self.SendWeaponAnim( ANIM_SHOOTB_LOOP );

				m_flModeBNextHit = g_Engine.time;
			}

			//if(CurButton & IN_ATTACK) set_uc(uc_handle, UC_Buttons, CurButton & ~IN_ATTACK)
			//else if (CurButton & IN_ATTACK2) set_uc(uc_handle, UC_Buttons, CurButton & ~IN_ATTACK2)
		}

		BaseClass.ItemPostFrame();
	}

	bool ModeBAttack()
	{
		bool bDidHit = false;

		TraceResult tr;

		Math.MakeVectors( m_pPlayer.pev.v_angle );
		Vector vecSrc	= m_pPlayer.GetGunPosition();
		Vector vecEnd	= vecSrc + g_Engine.v_forward * 48;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );

		if( tr.flFraction >= 1.0f )
		{
			g_Utility.TraceHull( vecSrc, vecEnd, dont_ignore_monsters, head_hull, m_pPlayer.edict(), tr );

			if( tr.flFraction < 1.0f )
			{
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );

				if( pHit is null or pHit.IsBSPModel() )
					g_Utility.FindHullIntersection( vecSrc, tr, tr, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX, m_pPlayer.edict() );

				vecEnd = tr.vecEndPos;
			}
		}

		if( tr.flFraction >= 1.0f )
		{
			self.m_flNextPrimaryAttack = g_Engine.time + 1.0f;
			self.m_flNextSecondaryAttack = g_Engine.time + 1.2f;

			self.m_flTimeWeaponIdle = g_Engine.time + 2.0f;
		}
		else
		{
			bDidHit = true;

			self.m_flTimeWeaponIdle = g_Engine.time + 2.0f;

			CBaseEntity@ pEntity = g_EntityFuncs.Instance(tr.pHit);

			float flDamage = CSOW_DAMAGE_B;
			if( self.m_flCustomDmg > 0 )
				flDamage = self.m_flCustomDmg;

			g_WeaponFuncs.ClearMultiDamage();

			if( self.m_flNextPrimaryAttack + 1 < g_Engine.time )
				pEntity.TraceAttack( m_pPlayer.pev, flDamage, g_Engine.v_forward, tr, DMG_CLUB );  
			else
				pEntity.TraceAttack( m_pPlayer.pev, flDamage * 0.5f, g_Engine.v_forward, tr, DMG_CLUB );  

			g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );

			float flVol = 1.0f;
			bool bHitWorld = true;

			if( m_flPlayWallHitSound == 0 )
				m_flPlayWallHitSound = g_Engine.time + Math.RandomFloat(0.025f, 0.03f);

			if( pEntity !is null )
			{
				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.35f;

				if( pEntity.Classify() != CLASS_NONE and pEntity.Classify() != CLASS_MACHINE and pEntity.BloodColor() != DONT_BLEED )
				{
					if( m_flPlayBodyHitSound == 0 )
						m_flPlayBodyHitSound = g_Engine.time + Math.RandomFloat(0.025f, 0.03f);

					if( m_flPlayBodyHitSound > 0 and g_Engine.time > m_flPlayBodyHitSound )
					{
						m_flPlayBodyHitSound = 0;
						g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_ITEM, pCSOWSounds[SND_HIT], 1, ATTN_NORM );
					}

					m_pPlayer.m_iWeaponVolume = 128; 

					if( !pEntity.IsAlive() )
						return true;
					else
						flVol = 0.1f;

					bHitWorld = false;
				}
			}

			if( bHitWorld )
			{
				//self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.35f;

				if( m_flPlayWallHitSound > 0 and g_Engine.time > m_flPlayWallHitSound )
				{
					m_flPlayWallHitSound = 0;
					g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, pCSOWSounds[SND_MODEB_HIT_WALL], VOL_NORM, ATTN_NORM, 0, 98 + Math.RandomLong(0, 3) );
				}
			}

			m_pPlayer.m_iWeaponVolume = int(flVol * 512);
		}

		return bDidHit;
	}

	void Create_Smoke()
	{
		if( !m_pPlayer.IsAlive() )
			return;

		Vector origin;
		get_position( 25.0f, 15.0f, 0.0f, origin );

		NetworkMessage smoke( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
			smoke.WriteByte( TE_EXPLOSION );
			smoke.WriteCoord( origin.x );
			smoke.WriteCoord( origin.y );
			smoke.WriteCoord( origin.z );
			smoke.WriteShort( g_SmokePuff_SprId );
			smoke.WriteByte( 5 ); //scale
			smoke.WriteByte( 30 ); //framerate
			smoke.WriteByte( TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NOPARTICLES );
		smoke.End();

		if( (m_iWeaponState & (STATE_MODEA | STATE_CHANGING)) == (STATE_MODEA | STATE_CHANGING) ) //changing to mode B
		{
			switch( m_uiSmokeState )
			{
				case 0: pev.nextthink = g_Engine.time + 0.5f; break;
				case 1: pev.nextthink = g_Engine.time + 0.4f; break;
				case 2: pev.nextthink = g_Engine.time + 0.3f; break;
				case 3: pev.nextthink = g_Engine.time + 0.2f; break;
			}

			m_uiSmokeState++;
		}
		else
		{
			switch( m_uiSmokeState )
			{
				case 0: pev.nextthink = g_Engine.time + 0.2f; break;
				case 1: pev.nextthink = g_Engine.time + 0.2f; break;
				case 2: pev.nextthink = g_Engine.time + 0.1f; break;
				case 3: pev.nextthink = g_Engine.time + 0.1f; break;
			}

			m_uiSmokeState++;
		}
	}

	void Remove_Smoke()
	{
		if( !m_pPlayer.IsAlive() )
			return;

		m_uiSmokeState = 0;
		SetThink( ThinkFunction(this.Change_Thanatos9) );
		pev.nextthink = g_Engine.time + (CSOW_TIME_MODEA_CHANGE - 3.25f);
	}

	void Activate_ModeBAttack()
	{
		if( !m_pPlayer.IsAlive() )
			return;

		if( (m_iWeaponState & STATE_MODEB) == 0 )
			return;

		//m_iWeaponState &= ~STATE_MODEB;
		m_iWeaponState = STATE_MODEB_LOOP;

		m_pPlayer.pev.weaponmodel = MODEL_PLAYER_MODEC;

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_MODEB_ATTACK;
		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_MODEB_ATTACK + 0.5f;

		self.SendWeaponAnim( ANIM_SHOOTB_LOOP );

		SetThink( ThinkFunction(this.Deactivate_ModeBAttack) );
		pev.nextthink = g_Engine.time + CSOW_TIME_MODEB_ATTACK;
	}

	void Deactivate_ModeBAttack()
	{
		if( !m_pPlayer.IsAlive() )
			return;

		if( (m_iWeaponState & STATE_MODEB_LOOP) == 0 )
			return;

		//m_iWeaponState &= ~STATE_MODEB_LOOP;
		//m_iWeaponState &= ~STATE_MODEB;
		m_iWeaponState = STATE_MODEA;
		//m_iWeaponState = STATE_MODEB;
		//m_iWeaponState = STATE_MODEB | STATE_CHANGING;

		m_pPlayer.pev.weaponmodel = MODEL_PLAYER_MODEB;

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_MODEB_CHANGE + 0.7f;
		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_MODEB_CHANGE + 1.2f;

		self.SendWeaponAnim( ANIM_SHOOTB_END );

		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_DRAW], VOL_NORM, ATTN_NORM );

		SetThink( ThinkFunction(this.Deactivate_ModeB) );
		pev.nextthink = g_Engine.time + 0.65f;
	}

	void Deactivate_ModeB()
	{
		if( !m_pPlayer.IsAlive() )
			return;

		m_pPlayer.pev.weaponmodel = MODEL_PLAYER_MODEA;
		m_pPlayer.m_szAnimExtension = CSOW_ANIMEXT_MODEA;

		m_uiSmokeState = 0;
		SetThink( ThinkFunction(this.Create_Smoke) );
		pev.nextthink = g_Engine.time + 2.0f;

		m_flTimeToChangeToA = g_Engine.time + (CSOW_TIME_MODEB_CHANGE - 0.25f);

		self.SendWeaponAnim( ANIM_CHANGEB );
	}

	void Change_Thanatos9()
	{
		if( !m_pPlayer.IsAlive() )
			return;

		if( (m_iWeaponState & STATE_CHANGING) == 0 )
			return;

		m_iWeaponState &= ~STATE_CHANGING;

		if( (m_iWeaponState & STATE_MODEB) == 0 )
		{
			m_pPlayer.pev.weaponmodel = MODEL_PLAYER_MODEB;

			m_iWeaponState = STATE_MODEB;
			self.SendWeaponAnim( ANIM_IDLEB );

			m_pPlayer.m_szAnimExtension = CSOW_ANIMEXT_MODEB;
		}
		else
		{
			m_pPlayer.pev.weaponmodel = MODEL_PLAYER_MODEA;

			m_iWeaponState = STATE_MODEA;
			self.SendWeaponAnim( ANIM_IDLEA );

			m_pPlayer.m_szAnimExtension = CSOW_ANIMEXT_MODEA;
		}
	}

	void Check_Slashing()
	{
		if( !m_pPlayer.IsAlive() )
			return;

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 1.0f;
		self.m_flTimeWeaponIdle = g_Engine.time + 1.5f;

		Damage_Slashing();
	}

	void Damage_Slashing()
	{
		array<Vector> vecPoints(4);

		float Point_Dis = 80.0f;
		float TB_Distance = CSOW_RADIUS1 / 4.0f;

		Vector vecTargetOrigin, vecMyOrigin = m_pPlayer.pev.origin;

		for( int i = 0; i < 4; i++ ) get_position( TB_Distance * (i + 1), 0.0f, 0.0f, vecPoints[i] );

		bool bHitSomeone = false;

		CBaseEntity@ pTarget = null;

		/*for( int i = 0; i < g_Engine.maxEntities; ++i )
		{
			edict_t@ edict = @g_EntityFuncs.IndexEnt(i);
			if( edict is null ) continue;
			if( edict is m_pPlayer.edict() ) continue;

			@pTarget = g_EntityFuncs.Instance(edict);
			if( pTarget is null ) continue;
			if( !pTarget.IsAlive() ) continue;
		}*/

		/*for( int i = 1; i <= g_Engine.maxClients; ++i )
		{
			CBasePlayer@ pTarget = g_PlayerFuncs.FindPlayerByIndex( i );

			if( pTarget is null ) continue;
			if( !pTarget.IsConnected() ) continue;
			if( !pTarget.IsAlive() ) continue;
		}*/
	
		while( (@pTarget = g_EntityFuncs.FindEntityInSphere(pTarget, m_pPlayer.pev.origin, CSOW_RADIUS1, "*", "classname")) !is null )
		{
			if( pTarget.edict() is m_pPlayer.edict() or (!pTarget.IsMonster() and !pTarget.IsPlayer()) or !pTarget.IsAlive() )
				continue;

			vecTargetOrigin = pTarget.pev.origin;

			if( is_wall_between_points(vecMyOrigin, vecTargetOrigin, m_pPlayer.edict()) ) continue;

			if( (vecTargetOrigin - vecPoints[0]).Length() <= Point_Dis
			or (vecTargetOrigin - vecPoints[1]).Length() <= Point_Dis
			or (vecTargetOrigin - vecPoints[2]).Length() <= Point_Dis
			or (vecTargetOrigin - vecPoints[3]).Length() <= Point_Dis )
			{
				bHitSomeone = true;

				TraceResult tr;

				Math.MakeVectors( m_pPlayer.pev.v_angle );
				g_Utility.TraceLine( vecMyOrigin, vecTargetOrigin, dont_ignore_monsters, m_pPlayer.edict(), tr );

				g_WeaponFuncs.ClearMultiDamage();
				pTarget.TraceAttack( m_pPlayer.pev, CSOW_DAMAGE_A, g_Engine.v_forward, tr, (DMG_NEVERGIB|DMG_BULLET) );
				g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );

				//pTarget.TakeDamage( m_pPlayer.pev, m_pPlayer.pev, CSOW_DAMAGE_A, (DMG_NEVERGIB|DMG_BULLET) ); 
			}
		}

		if( bHitSomeone )
		{
			//this comment is here so that the if-else doesn't look like shit :joy:
			g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_STATIC, pCSOWSounds[SND_HIT], VOL_NORM, ATTN_NORM );
		}
		else
		{
			vecMyOrigin.z += 26.0f;
			get_position( CSOW_RADIUS1 - 5.0f, 0.0f, 0.0f, vecPoints[0] );

			//if( is_wall_between_points(vecMyOrigin, vecPoints[0], m_pPlayer.edict()) )
			TraceResult tr;

			g_Utility.TraceLine( vecMyOrigin, vecPoints[0], ignore_monsters, m_pPlayer.edict(), tr );

			if( (vecPoints[0] - tr.vecEndPos).Length() > 0 )
			{
				CBaseEntity@ pEntity = g_EntityFuncs.Instance(tr.pHit);

				if( pEntity !is null and pEntity.IsBSPModel() )
				{
					g_WeaponFuncs.ClearMultiDamage();
					pEntity.TraceAttack( m_pPlayer.pev, CSOW_DAMAGE_A, g_Engine.v_forward, tr, (DMG_NEVERGIB|DMG_BULLET) );
					g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );

					//pEntity.TakeDamage( m_pPlayer.pev, m_pPlayer.pev, CSOW_DAMAGE_A, (DMG_NEVERGIB|DMG_BULLET) ); 
				}

				g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_STATIC, pCSOWSounds[SND_HIT_WALL], VOL_NORM, ATTN_NORM );
			}
		}
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_thanatos9::weapon_thanatos9", "weapon_thanatos9" );
	g_ItemRegistry.RegisterWeapon( "weapon_thanatos9", "custom_weapons/cso" );
}

} //namespace cso_thanatos9 END

/*
Todo
Fix W model so it doesn't sink into the floor
*/