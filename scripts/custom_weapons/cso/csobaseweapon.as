int g_iCSOWHands = 0;

class CBaseCSOWeapon : ScriptBasePlayerWeaponEntity
{
	// Possible workaround for the SendWeaponAnim() access violation crash.
	// According to R4to0 this seems to provide at least some improvement.
	// GeckoN: TODO: Remove this once the core issue is addressed.
	protected CBasePlayer@ m_pPlayer
	{
		get const { return cast<CBasePlayer@>(self.m_hPlayer.GetEntity()); }
		set { self.m_hPlayer = EHandle(@value); }
	}

	protected EHandle m_hDropEffect;

	int m_iWeaponType;
	int m_iShell;
	private int tracerCount = 0;
	bool m_bSwitchHands = false; //limit to models with all 3 hands for now

	//For CS-Like
	int m_iShotsFired;
	bool m_bDirection;
	bool m_bDelayFire;
	float m_flDecreaseShotsFired;
	float m_flSpreadJumping;
	float m_flSpreadRunning;
	float m_flSpreadWalking;
	float m_flSpreadStanding;
	float m_flSpreadDucking;

	void TertiaryAttack()
	{
		if( m_bSwitchHands )
		{
			g_iCSOWHands++;
			if( g_iCSOWHands == HANDS_SVENCOOP+1 ) g_iCSOWHands = HANDS_MALE;

			self.SendWeaponAnim( 0, 0, g_iCSOWHands );

			if( g_iCSOWHands == HANDS_SVENCOOP )
				g_PlayerFuncs.ClientPrint( m_pPlayer, HUD_PRINTCENTER, "HANDS SET TO SVENCOOP" );
			else if( g_iCSOWHands == HANDS_MALE )
				g_PlayerFuncs.ClientPrint( m_pPlayer, HUD_PRINTCENTER, "HANDS SET TO CSO MALE" );
			else if( g_iCSOWHands == HANDS_FEMALE )
				g_PlayerFuncs.ClientPrint( m_pPlayer, HUD_PRINTCENTER, "HANDS SET TO CSO FEMALE" );

			self.m_flNextTertiaryAttack = g_Engine.time + 0.5;
		}
	}

	void EjectBrass( Vector vecOrigin, int iShell, int iBounce = TE_BOUNCE_SHELL, bool bRight = true, bool bUpBoost = false )
	{
		Vector vecVelocity;
		float flUpBoost;

		if( bUpBoost )
			flUpBoost = Math.RandomFloat(100, 150);
		else
			flUpBoost = Math.RandomFloat(50, 75);

		if( bRight )
			vecVelocity = m_pPlayer.pev.velocity + g_Engine.v_right * Math.RandomFloat(100, 150) + g_Engine.v_up * flUpBoost + g_Engine.v_forward * 25;
		else
			vecVelocity = m_pPlayer.pev.velocity - g_Engine.v_right * Math.RandomFloat(100, 150) + g_Engine.v_up * flUpBoost + g_Engine.v_forward * 25;

		NetworkMessage m1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
			m1.WriteByte( TE_MODEL );
			m1.WriteCoord( vecOrigin.x );
			m1.WriteCoord( vecOrigin.y );
			m1.WriteCoord( vecOrigin.z );
			m1.WriteCoord( vecVelocity.x ); 
			m1.WriteCoord( vecVelocity.y );
			m1.WriteCoord( vecVelocity.z );
			m1.WriteAngle( Math.RandomLong(0, 360) );
			m1.WriteShort( iShell );
			m1.WriteByte( iBounce );
			m1.WriteByte( 25 );
		m1.End();
	}

	//TODO: remove
	void DoDecalGunshot( Vector vecSrc, Vector vecAiming, float flConeX, float flConeY, int iBulletType, EHandle &in ePlayer, bool bSmokePuff = false )
	{
		CBasePlayer@ pPlayer = null;

		if( ePlayer.IsValid() ) @pPlayer = cast<CBasePlayer@>( ePlayer.GetEntity() );
		if( pPlayer !is null ) DoDecalGunshot( vecSrc, vecAiming, flConeX, flConeY, iBulletType, pPlayer, bSmokePuff );
	}

	void DoDecalGunshot( Vector vecSrc, Vector vecAiming, float flConeX, float flConeY, int iBulletType, bool bSmokePuff = false )
	{
		TraceResult tr;
		
		float x, y;
		
		g_Utility.GetCircularGaussianSpread( x, y );
		
		Vector vecDir = vecAiming 
						+ x * flConeX * g_Engine.v_right 
						+ y * flConeY * g_Engine.v_up;

		Vector vecEnd	= vecSrc + vecDir * 8192;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );
		
		if( tr.flFraction < 1.0 )
		{
			if( tr.pHit !is null )
			{
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				
				if( pHit is null || pHit.IsBSPModel() == true )
				{
					g_WeaponFuncs.DecalGunshot( tr, iBulletType );

					if( bSmokePuff )
					{
						NetworkMessage m1( MSG_PAS, NetworkMessages::SVC_TEMPENTITY, tr.vecEndPos );
							m1.WriteByte( TE_EXPLOSION );
							m1.WriteCoord( tr.vecEndPos.x );
							m1.WriteCoord( tr.vecEndPos.y );
							m1.WriteCoord( tr.vecEndPos.z - 10.0 );
							m1.WriteShort( g_EngineFuncs.ModelIndex(cso::pSmokeSprites[Math.RandomLong(1, 4)]) );
							m1.WriteByte( 2 );
							m1.WriteByte( 50 );
							m1.WriteByte( TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES );
						m1.End();
					}
				}
			}
		}
	}

	void DoMuzzleflash( string szSprite, float flForward, float flRight, float flUp, float flScale, float flRenderamt, float flFramerate, float flRotation = 0.0, int iRenderMode = kRenderTransAdd )
	{
		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		CSprite@ pMuzzle = g_EntityFuncs.CreateSprite( szSprite, m_pPlayer.GetGunPosition() + g_Engine.v_forward * flForward + g_Engine.v_right * flRight + g_Engine.v_up * flUp, true );
		@pMuzzle.pev.owner = m_pPlayer.edict();
		pMuzzle.SetScale( flScale );
		pMuzzle.SetTransparency( iRenderMode, 255, 255, 255, int(flRenderamt), kRenderFxNone );

		if( flRotation > 0.0 )
		{
			pMuzzle.KeyValue( "vp_type", "VP_TYPE::VP_ORIENTATED" );
			pMuzzle.pev.angles = Vector( 0.0, 0.0, flRotation );
		}

		//pMuzzle.pev.sequence = VP_TYPE::VP_ORIENTATED; //next update ??
		//pMuzzle.pev.effects = EF_SPRITE_CUSTOM_VP; //next update ??
		pMuzzle.AnimateAndDie( flFramerate );
	}

	void DoMuzzleflash2( string szSprite, float flForward, float flRight, float flUp, int iScale, int iFramerate, int iFlags )
	{
		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		Vector vecOrigin = m_pPlayer.GetGunPosition() + g_Engine.v_forward * flForward + g_Engine.v_right * flRight + g_Engine.v_up * flUp;

		NetworkMessage m1( MSG_ONE, NetworkMessages::SVC_TEMPENTITY, m_pPlayer.edict() );
			m1.WriteByte( TE_EXPLOSION );
			m1.WriteCoord( vecOrigin.x );
			m1.WriteCoord( vecOrigin.y );
			m1.WriteCoord( vecOrigin.z );
			m1.WriteShort( g_EngineFuncs.ModelIndex(szSprite) );
			m1.WriteByte( iScale ); //scale
			m1.WriteByte( iFramerate ); //framerate
			m1.WriteByte( iFlags );
		m1.End();
	}

	void HandleAmmoReduction( int iPrimaryClip = 0, int iPrimaryAmmo = 0, int iSecondaryClip = 0, int iSecondaryAmmo = 0 )
	{
		if( iPrimaryClip > 0 )
		{
			self.m_iClip -= iPrimaryClip;

			if( self.m_iClip <= 0 and m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
				m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );
		}
		else if( iPrimaryAmmo > 0 )
		{
			m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) - iPrimaryAmmo );

			if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
				m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );
		}
		else if( iSecondaryClip > 0 )
		{
			self.m_iClip2 -= iSecondaryClip;

			if( self.m_iClip2 <= 0 and m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType ) <= 0 )
				m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );
		}
		else if( iSecondaryAmmo > 0 )
		{
			m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType, m_pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType) - iSecondaryAmmo );

			if( m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType ) <= 0 )
				m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );
		}
	}

	void HandleRecoil( Vector2D vec2dRecoilStandingX, Vector2D vec2dRecoilStandingY, Vector2D vec2dRecoilDuckingX, Vector2D vec2dRecoilDuckingY )
	{
		Vector2D vec2dRecoilX = (m_pPlayer.pev.flags & FL_DUCKING != 0) ? vec2dRecoilDuckingX : vec2dRecoilStandingX;
		Vector2D vec2dRecoilY = (m_pPlayer.pev.flags & FL_DUCKING != 0) ? vec2dRecoilDuckingY : vec2dRecoilStandingY;

		m_pPlayer.pev.punchangle.x = Math.RandomFloat( vec2dRecoilX.x, vec2dRecoilX.y );
		m_pPlayer.pev.punchangle.y = Math.RandomFloat( vec2dRecoilY.x, vec2dRecoilY.y );
	}

	//For CS-Like
	void KickBack( float up_base, float lateral_base, float up_modifier, float lateral_modifier, float up_max, float lateral_max, int direction_change )
	{
		float flFront, flSide;

		if( m_iShotsFired == 1 )
		{
			flFront = up_base;
			flSide = lateral_base;
		}
		else
		{
			flFront = m_iShotsFired * up_modifier + up_base;
			flSide = m_iShotsFired * lateral_modifier + lateral_base;
		}

		m_pPlayer.pev.punchangle.x -= flFront;

		if( m_pPlayer.pev.punchangle.x < -up_max )
			m_pPlayer.pev.punchangle.x = -up_max;

		if( m_bDirection )
		{
			m_pPlayer.pev.punchangle.y += flSide;

			if( m_pPlayer.pev.punchangle.y > lateral_max )
				m_pPlayer.pev.punchangle.y = lateral_max;
		}
		else
		{
			m_pPlayer.pev.punchangle.y -= flSide;

			if( m_pPlayer.pev.punchangle.y < -lateral_max )
				m_pPlayer.pev.punchangle.y = -lateral_max;
		}

		if( Math.RandomLong(0, direction_change) == 0 )
			m_bDirection = !m_bDirection;
	}

	float GetWeaponSpread()
	{
		if( !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) )
			return m_flSpreadJumping;
		else if( m_pPlayer.pev.velocity.Length2D() > 140 )
			return m_flSpreadRunning;
		else if( m_pPlayer.pev.velocity.Length2D() > 10 )
			return m_flSpreadWalking;
		else if( m_pPlayer.pev.FlagBitSet(FL_DUCKING) )
			return m_flSpreadDucking;
		else
			return m_flSpreadStanding;
	}

	CBasePlayerItem@ DropItem()
	{
		if( cso::bUseDroppedItemEffect )
		{
			if( m_hDropEffect.GetEntity() is null )
			{
				CBaseEntity@ cbeGunDrop = g_EntityFuncs.Create( "ef_gundrop", pev.origin, g_vecZero, false, self.edict() );
				m_hDropEffect = EHandle( cbeGunDrop );
				cso::ef_gundrop@ pGunDrop = cast<cso::ef_gundrop@>(CastToScriptClass(cbeGunDrop));
				pGunDrop.m_hOwner = EHandle( self );
				pGunDrop.pev.movetype	= MOVETYPE_FOLLOW;
				@pGunDrop.pev.aiment	= self.edict();

				g_EntityFuncs.DispatchSpawn( pGunDrop.self.edict() );
			}
		}

		return BaseClass.DropItem();
	}

	//From cstrike combat.cpp Vector CBaseEntity::FireBullets3(Vector vecSrc, Vector vecDirShooting, float flSpread, float flDistance, int iPenetration, int iBulletType, int iDamage, float flRangeModifier, entvars_t *pevAttacker, bool bPistol, int shared_rand)
	//FireBullets3( vecSrc, vecAiming, 0, 4096, 2, BULLET_PLAYER_50AE, 54, 0.81, m_pPlayer.edict(), true, m_pPlayer.random_seed );
	//TODO make bullet decals on the otherside of a penetrated wall
	//TODO make bullet decals and smoke when hitting a wall that is further than flCurrentDistance ??
	int FireBullets3( Vector vecSrc, Vector vecDirShooting, float flSpread, int iPenetration, int iBulletType, int iTracerFreq, float flDamage, float flRangeModifier, int iFlags = 0, Vector vecMuzzleOrigin = g_vecZero )
	{
		float flDistance = 8192.0;

		const int HITGROUP_SHIELD = HITGROUP_RIGHTLEG + 1;
		float flPenetrationPower;
		float flPenetrationDistance;
		float flCurrentDamage = flDamage;
		float flCurrentDistance;
		TraceResult tr, tr2;
		Vector vecRight = g_Engine.v_right;
		Vector vecUp = g_Engine.v_up;
		edict_t@ pentIgnore = m_pPlayer.edict();
		bool bHitMetal = false;
		//int iSparksAmount; //UNUSED??
		int iTrail = TRAIL_NONE;
		Vector vecTrailOrigin = vecSrc;
		if( vecMuzzleOrigin != g_vecZero )
			vecTrailOrigin = vecTrailOrigin + g_Engine.v_forward * vecMuzzleOrigin.x + g_Engine.v_right * vecMuzzleOrigin.y + g_Engine.v_up * vecMuzzleOrigin.z;

		int iBulletDecal = BULLET_NONE;
		int iEnemiesHit = 0;

		switch( iBulletType )
		{
			case BULLET_PLAYER_9MM:
			{
				flPenetrationPower = 21;
				flPenetrationDistance = 800;
				//iSparksAmount = 15;
				flCurrentDamage += (-4 + Math.RandomLong(0, 10));
				iBulletDecal = BULLET_PLAYER_9MM;
				break;
			}

			case BULLET_PLAYER_45ACP:
			{
				flPenetrationPower = 15;
				flPenetrationDistance = 500;
				//iSparksAmount = 20;
				flCurrentDamage += (-2 + Math.RandomLong(0, 4));
				break;
			}

			case BULLET_PLAYER_50AE:
			{
				flPenetrationPower = 30;
				flPenetrationDistance = 1000;
				//iSparksAmount = 20;
				flCurrentDamage += (-4 + Math.RandomLong(0, 10));
				iBulletDecal = BULLET_PLAYER_EAGLE;
				break;
			}

			case BULLET_PLAYER_762MM:
			{
				flPenetrationPower = 39;
				flPenetrationDistance = 5000;
				//iSparksAmount = 30;
				flCurrentDamage += (-2 + Math.RandomLong(0, 4));
				iBulletDecal = BULLET_PLAYER_SNIPER;
				break;
			}

			case BULLET_PLAYER_556MM:
			{
				flPenetrationPower = 35;
				flPenetrationDistance = 4000;
				//iSparksAmount = 30;
				flCurrentDamage += (-3 + Math.RandomLong(0, 6));
				iBulletDecal = BULLET_PLAYER_SAW;
				break;
			}

			case BULLET_PLAYER_338MAG:
			{
				flPenetrationPower = 45;
				flPenetrationDistance = 8000;
				//iSparksAmount = 30;
				flCurrentDamage += (-4 + Math.RandomLong(0, 8));
				iBulletDecal = BULLET_PLAYER_SNIPER;
				break;
			}

			case BULLET_PLAYER_50BMG:
			{
				flPenetrationPower = 112;
				flPenetrationDistance = 8000;
				//iSparksAmount = 35;
				flCurrentDamage += (-2 + Math.RandomLong(4, 12));
				iBulletDecal = BULLET_PLAYER_SNIPER;
				break;
			}

			case BULLET_PLAYER_57MM:
			{
				flPenetrationPower = 30;
				flPenetrationDistance = 2000;
				//iSparksAmount = 20;
				flCurrentDamage += (-4 + Math.RandomLong(0, 10));
				iBulletDecal = BULLET_PLAYER_EAGLE;
				break;
			}

			case BULLET_PLAYER_357SIG:
			{
				flPenetrationPower = 25;
				flPenetrationDistance = 800;
				//iSparksAmount = 20;
				flCurrentDamage += (-4 + Math.RandomLong(0, 10));
				iBulletDecal = BULLET_PLAYER_357;
				break;
			}

			case BULLET_PLAYER_44MAG:
			{
				flPenetrationPower = 25;
				flPenetrationDistance = 800;
				//iSparksAmount = 20;
				//flCurrentDamage += (-4 + Math.RandomLong(0, 8));
				iBulletDecal = BULLET_PLAYER_EAGLE;
				break;
			}

			case BULLET_PLAYER_CSOBOW:
			{
				flPenetrationPower = 30;
				flPenetrationDistance = 1500;
				//iSparksAmount = 20;
				flCurrentDamage += (-2 + Math.RandomLong(0, 4));
				iTrail = TRAIL_CSOBOW;
				iBulletDecal = BULLET_PLAYER_MP5;
				break;
			}

			case BULLET_PLAYER_FAILNAUGHT:
			{
				flPenetrationPower = 35;
				flPenetrationDistance = 2000;
				//iSparksAmount = 20;
				flCurrentDamage += (-2 + Math.RandomLong(0, 4));
				iTrail = TRAIL_FAILNAUGHT;
				iBulletDecal = BULLET_PLAYER_MP5;
				break;
			}

			case BULLET_PLAYER_M95TIGER:
			{
				flPenetrationPower = 112;
				flPenetrationDistance = 8000;
				//iSparksAmount = 35;
				flCurrentDamage += (-2 + Math.RandomLong(4, 12));
				iTrail = TRAIL_M95TIGER;
				iBulletDecal = BULLET_PLAYER_SNIPER;
				break;
			}

			default:
			{
				flPenetrationPower = 0;
				flPenetrationDistance = 0;
				break;
			}
		}

		float x, y;

		x = g_PlayerFuncs.SharedRandomFloat(m_pPlayer.random_seed, -0.5, 0.5) + g_PlayerFuncs.SharedRandomFloat(m_pPlayer.random_seed + 1, -0.5, 0.5);
		y = g_PlayerFuncs.SharedRandomFloat(m_pPlayer.random_seed + 2, -0.5, 0.5) + g_PlayerFuncs.SharedRandomFloat(m_pPlayer.random_seed + 3, -0.5, 0.5);

		Vector vecDir = vecDirShooting + x * flSpread * vecRight + y * flSpread * vecUp;
		Vector vecEnd = vecSrc + vecDir * flDistance;
		Vector vecOldSrc;
		Vector vecNewSrc;
		float flDamageModifier = 0.5;

		while( iPenetration > 0 ) //!= 0 seems unsafe
		{
			g_WeaponFuncs.ClearMultiDamage();
			g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, pentIgnore, tr );

			//char cTextureType = UTIL_TextureHit( tr, vecSrc, vecEnd );
			string sTexture = g_Utility.TraceTexture( null, vecSrc, vecEnd );
			char cTextureType = g_SoundSystem.FindMaterialType(sTexture);
			bool bSparks = false;

			if( cso::pBPTextures.find( sTexture ) != -1 )
			{
				g_Utility.Ricochet( tr.vecEndPos, 1.0 );
				return 0;
				//return tr.vecEndPos;
			}

			if( cTextureType == CHAR_TEX_METAL )
			{
				bSparks = true;
				bHitMetal = true;
				flPenetrationPower *= 0.15;
				flDamageModifier = 0.2;
			}
			else if( cTextureType == CHAR_TEX_CONCRETE )
			{
				flPenetrationPower *= 0.25;
				flDamageModifier = 0.25;
			}
			else if( cTextureType == CHAR_TEX_GRATE )
			{
				bSparks = true;
				bHitMetal = true;
				flPenetrationPower *= 0.5;
				flDamageModifier = 0.4;
			}
			else if( cTextureType == CHAR_TEX_VENT )
			{
				bSparks = true;
				bHitMetal = true;
				flPenetrationPower *= 0.5;
				flDamageModifier = 0.45;
			}
			else if( cTextureType == CHAR_TEX_TILE )
			{
				flPenetrationPower *= 0.65;
				flDamageModifier = 0.3;
			}
			else if( cTextureType == CHAR_TEX_COMPUTER )
			{
				bSparks = true;
				bHitMetal = true;
				flPenetrationPower *= 0.4;
				flDamageModifier = 0.45;
			}
			else if( cTextureType == CHAR_TEX_WOOD )
			{
				flPenetrationPower *= 1;
				flDamageModifier = 0.6;
			}
			else
				bSparks = false;

			if( tr.flFraction != 1.0 )
			{
				CBaseEntity@ pEntity = g_EntityFuncs.Instance(tr.pHit);
				iPenetration--;

				flCurrentDistance = tr.flFraction * flDistance;
				flCurrentDamage *= pow(flRangeModifier, flCurrentDistance / 500);

				if( flCurrentDistance > flPenetrationDistance )
					iPenetration = 0;

				if( tr.iHitgroup == HITGROUP_SHIELD )
				{
					iPenetration = 0;

					if( tr.flFraction != 1.0 )
					{
						if( Math.RandomLong(0, 1) == 1 )
							g_SoundSystem.EmitSound( pEntity.edict(), CHAN_VOICE, "custom_weapons/cso/ric_metal-1.wav", 1, ATTN_NORM );
						else
							g_SoundSystem.EmitSound( pEntity.edict(), CHAN_VOICE, "custom_weapons/cso/ric_metal-2.wav", 1, ATTN_NORM );

						g_Utility.Sparks( tr.vecEndPos );

						pEntity.pev.punchangle.x = flCurrentDamage * Math.RandomFloat(-0.15, 0.15);
						pEntity.pev.punchangle.z = flCurrentDamage * Math.RandomFloat(-0.15, 0.15);

						if( pEntity.pev.punchangle.x < 4 )
							pEntity.pev.punchangle.x = 4;

						if( pEntity.pev.punchangle.z < -5 )
							pEntity.pev.punchangle.z = -5;
						else if( pEntity.pev.punchangle.z > 5 )
							pEntity.pev.punchangle.z = 5;
					}

					break;
				}

				if( tr.pHit.vars.solid == SOLID_BSP /*and iPenetration != 0*/ ) //prevents the last hit from causing decals
				{
					if( (iFlags & CSOF_ALWAYSDECAL) != 0 )
						g_WeaponFuncs.DecalGunshot( tr, iBulletDecal/*, false, pev, bHitMetal*/ );
					else if( Math.RandomLong(0, 3) == 1 )
						g_WeaponFuncs.DecalGunshot( tr, iBulletDecal/*, true, pev, bHitMetal*/ );

					vecSrc = tr.vecEndPos + (vecDir * flPenetrationPower);
					flDistance = (flDistance - flCurrentDistance) * 0.5;
					vecEnd = vecSrc + (vecDir * flDistance);

					pEntity.TraceAttack( m_pPlayer.pev, flCurrentDamage, vecDir, tr, (DMG_BULLET|DMG_NEVERGIB) );

					//Wall smoke puff
					if( iTrail == TRAIL_NONE )
					{
						NetworkMessage m1( MSG_PAS, NetworkMessages::SVC_TEMPENTITY, tr.vecEndPos );
							m1.WriteByte( TE_EXPLOSION );
							m1.WriteCoord( tr.vecEndPos.x );
							m1.WriteCoord( tr.vecEndPos.y );
							m1.WriteCoord( tr.vecEndPos.z - 10.0 );
							m1.WriteShort( g_EngineFuncs.ModelIndex(cso::pSmokeSprites[Math.RandomLong(1, 4)]) );
							m1.WriteByte( 2 ); //scale
							m1.WriteByte( 50 ); //framerate
							m1.WriteByte( TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES );
						m1.End();

						if( (iFlags & CSOF_ETHEREAL) != 0 )
						{
							NetworkMessage m2( MSG_PAS, NetworkMessages::SVC_TEMPENTITY, tr.vecEndPos );
								m2.WriteByte( TE_STREAK_SPLASH );
								m2.WriteCoord( tr.vecEndPos.x );
								m2.WriteCoord( tr.vecEndPos.y );
								m2.WriteCoord( tr.vecEndPos.z );
								m2.WriteCoord( tr.vecPlaneNormal.x * Math.RandomFloat(25.0, 30.0) );
								m2.WriteCoord( tr.vecPlaneNormal.y * Math.RandomFloat(25.0, 30.0) );
								m2.WriteCoord( tr.vecPlaneNormal.z * Math.RandomFloat(25.0, 30.0) );
								m2.WriteByte( 0 ); //color
								m2.WriteShort( 20 ); //count
								m2.WriteShort( 3 ); //speed
								m2.WriteShort( 90 ); //velocity
							m2.End();
						}
					}
					else
						DoTrailExplosion( iTrail, tr.vecEndPos );

					//g_Game.AlertMessage( at_notice, "Hit SOLID_BSP: %1 with damage: %2\n", tr.pHit.vars.classname, flCurrentDamage );

					flCurrentDamage *= flDamageModifier;
				}
				else if( pEntity.pev.takedamage != DAMAGE_NO )
				{
					if( (iFlags & CSOF_HITMARKER) != 0 and (pEntity.pev.flags & FL_CLIENT) == 0 )
					{
						Vector vecOrigin = m_pPlayer.pev.origin;
						get_position( 50.0, -0.05, 1.0, vecOrigin );

						CBaseEntity@ pHitConfirm = g_EntityFuncs.Create( "cso_buffhit", vecOrigin, g_vecZero, false, m_pPlayer.edict() );
					}

					vecSrc = tr.vecEndPos + (vecDir * 42);
					flDistance = (flDistance - flCurrentDistance) * 0.75;
					vecEnd = vecSrc + (vecDir * flDistance);

					int iDmgType = (DMG_BULLET|DMG_NEVERGIB);

					if( (iFlags & CSOF_ARMORPEN) != 0 ) iDmgType = (DMG_GENERIC|DMG_BLAST|DMG_NEVERGIB);

					pEntity.TraceAttack( m_pPlayer.pev, flCurrentDamage, vecDir, tr, iDmgType );
					//TEMPTEST
					/*if( (iFlags & CSOF_ETHEREAL) != 0 )
					{
						//check for existing dotent
						CBaseEntity@ pDotEnt = g_EntityFuncs.Create( "cso_dotent", pEntity.pev.origin, g_vecZero, true, pEntity.edict() );

						if( pDotEnt !is null )
						{
							@pDotEnt.pev.aiment = pEntity.edict();
							pDotEnt.pev.dmgtime = 6.0;
							pDotEnt.pev.dmg = 15;
							g_EntityFuncs.DispatchSpawn( pDotEnt.edict() );
						}
					}*/
					//TEMPTEST

					if( iTrail > TRAIL_NONE )
						DoTrailExplosion( iTrail, tr.vecEndPos );

					iEnemiesHit++;
					//g_Game.AlertMessage( at_notice, "Hit entity: %1 with damage: %2\n", tr.pHit.vars.classname, flCurrentDamage );

					flCurrentDamage *= 0.75;

					@pentIgnore = pEntity.edict();
				}
			}
			else
				iPenetration = 0;

			g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );
		}

		if( iTrail > TRAIL_NONE )
		{
			if( iPenetration <= 0 )
				DoTrail( iTrail, vecTrailOrigin, tr.vecEndPos );
		}

		if( (iFlags & CSOF_ETHEREAL) != 0 )
			DoTracerEthereal( vecTrailOrigin, vecDir );
		else if( iTracerFreq != 0 and (tracerCount++ % iTracerFreq) == 0 )
			DoTracer( vecTrailOrigin, tr.vecEndPos );

		return iEnemiesHit;
		//return Vector(x * flSpread, y * flSpread, 0);
	}

	void DoTrail( int iTrail, Vector vecTrailstart, Vector vecTrailend )
	{
		switch( iTrail )
		{
			case TRAIL_CSOBOW:
			{
				NetworkMessage m1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
					m1.WriteByte( TE_BEAMPOINTS );
					m1.WriteCoord( vecTrailstart.x );//start position
					m1.WriteCoord( vecTrailstart.y );
					m1.WriteCoord( vecTrailstart.z );
					m1.WriteCoord( vecTrailend.x );//end position
					m1.WriteCoord( vecTrailend.y );
					m1.WriteCoord( vecTrailend.z );
					m1.WriteShort( g_EngineFuncs.ModelIndex(cso::SPRITE_TRAIL_CSOBOW) );//sprite index
					m1.WriteByte( 0 );//starting frame
					m1.WriteByte( 0 );//framerate in 0.1's
					m1.WriteByte( 20 );//life in 0.1's
					m1.WriteByte( 10 );//width in 0.1's
					m1.WriteByte( 0 );//noise amplitude in 0.1's
					m1.WriteByte( 255 );//red
					m1.WriteByte( 127 );//green
					m1.WriteByte( 127 );//blue
					m1.WriteByte( 127 );//brightness
					m1.WriteByte( 0 );//scroll speed
				m1.End();

				break;
			}

			case TRAIL_FAILNAUGHT:
			{
				NetworkMessage m1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
					m1.WriteByte( TE_BEAMPOINTS );
					m1.WriteCoord( vecTrailstart.x );//start position
					m1.WriteCoord( vecTrailstart.y );
					m1.WriteCoord( vecTrailstart.z );
					m1.WriteCoord( vecTrailend.x );//end position
					m1.WriteCoord( vecTrailend.y );
					m1.WriteCoord( vecTrailend.z );
					m1.WriteShort( g_EngineFuncs.ModelIndex(cso::SPRITE_TRAIL_FAILNAUGHT) );//sprite index
					m1.WriteByte( 0 );//starting frame
					m1.WriteByte( 1);//framerate in 0.1's
					m1.WriteByte( 20 );//life in 0.1's
					m1.WriteByte( 84 );//width in 0.1's
					m1.WriteByte( 0 );//noise amplitude in 0.1's
					m1.WriteByte( 219 );//red
					m1.WriteByte( 180 );//green
					m1.WriteByte( 12 );//blue
					m1.WriteByte( 127 );//brightness
					m1.WriteByte( 1 );//scroll speed
				m1.End();

				break;
			}

			case TRAIL_M95TIGER:
			{
				NetworkMessage m1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
					m1.WriteByte( TE_BEAMPOINTS );
					m1.WriteCoord( vecTrailstart.x );//start position
					m1.WriteCoord( vecTrailstart.y );
					m1.WriteCoord( vecTrailstart.z );
					m1.WriteCoord( vecTrailend.x );//end position
					m1.WriteCoord( vecTrailend.y );
					m1.WriteCoord( vecTrailend.z );
					m1.WriteShort( g_EngineFuncs.ModelIndex(cso::SPRITE_TRAIL_CSOBOW) );//sprite index
					m1.WriteByte( 0 );//starting frame
					m1.WriteByte( 0 );//framerate in 0.1's
					m1.WriteByte( 5 );//life in 0.1's
					m1.WriteByte( 4 );//width in 0.1's
					m1.WriteByte( 0 );//noise amplitude in 0.1's
					m1.WriteByte( 213 );//red
					m1.WriteByte( 213 );//green
					m1.WriteByte( 0 );//blue
					m1.WriteByte( 190 );//brightness
					m1.WriteByte( 0 );//scroll speed
				m1.End();

				break;
			}
		}
	}

	void DoTrailExplosion( int iTrail, Vector vecTrailend )
	{
		switch( iTrail )
		{
			case TRAIL_FAILNAUGHT:
			{
				NetworkMessage m1( MSG_PAS, NetworkMessages::SVC_TEMPENTITY, vecTrailend );
					m1.WriteByte( TE_EXPLOSION );
					m1.WriteCoord( vecTrailend.x );
					m1.WriteCoord( vecTrailend.y );
					m1.WriteCoord( vecTrailend.z );
					m1.WriteShort( g_EngineFuncs.ModelIndex(cso::SPRITE_TRAIL_FAILNAUGHT_EXPLODE) );
					m1.WriteByte( 5 ); //scale
					m1.WriteByte( 30 ); //framerate
					m1.WriteByte( TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES );
				m1.End();

				break;
			}
		}
	}

	void DoTracer( Vector vecStart, Vector vecEnd )
	{
			NetworkMessage m1( MSG_PAS, NetworkMessages::SVC_TEMPENTITY, vecStart );
				m1.WriteByte( TE_TRACER );
				m1.WriteCoord( vecStart.x );
				m1.WriteCoord( vecStart.y );
				m1.WriteCoord( vecStart.z );
				m1.WriteCoord( vecEnd.x );
				m1.WriteCoord( vecEnd.y );
				m1.WriteCoord( vecEnd.z );
			m1.End();
	}

	void DoTracerEthereal( Vector vecStart, Vector vecDir )
	{
		Vector vecVelocity = vecDir * 6000.0;

		NetworkMessage m1( MSG_PAS, NetworkMessages::SVC_TEMPENTITY, vecStart );
			m1.WriteByte( TE_USERTRACER );
			m1.WriteCoord( vecStart.x );
			m1.WriteCoord( vecStart.y );
			m1.WriteCoord( vecStart.z );
			m1.WriteCoord( vecVelocity.x );
			m1.WriteCoord( vecVelocity.y );
			m1.WriteCoord( vecVelocity.z );
			m1.WriteByte( 32 ); //life
			m1.WriteByte( 0 ); //color
			m1.WriteByte( 12 ); //length
		m1.End();
	}

	// AMXX Stuff that I cba converting :ayaya:
	void get_position( float flForward, float flRight, float flUp, Vector &out vecOut )
	{
		Vector vecOrigin, vecAngle, vecForward, vecRight, vecUp;

		vecOrigin = m_pPlayer.pev.origin;
		vecUp = m_pPlayer.pev.view_ofs; //GetGunPosition() ??
		vecOrigin = vecOrigin + vecUp;

		vecAngle = m_pPlayer.pev.v_angle; //if normal entity: use pev.angles

		g_EngineFuncs.AngleVectors( vecAngle, vecForward, vecRight, vecUp );

		vecOut = vecOrigin + vecForward * flForward + vecRight * flRight + vecUp * flUp;
	}

	void get_speed_vector( const Vector origin1, const Vector origin2, float speed, Vector &out new_velocity )
	{
		new_velocity = origin2 - origin1;

		float num = sqrt( speed*speed / (new_velocity.x*new_velocity.x + new_velocity.y*new_velocity.y + new_velocity.z*new_velocity.z) );

		new_velocity = new_velocity * num;
	}

	bool is_wall_between_points( Vector start, Vector end, edict_t@ ignore_ent )
	{
		TraceResult ptr;

		g_Utility.TraceLine( start, end, ignore_monsters, ignore_ent, ptr );

		return (end - ptr.vecEndPos).Length() > 0;
	}

	//TODO: remove
	void CS16GetDefaultShellInfo( EHandle ePlayer, Vector& out ShellVelocity, Vector& out ShellOrigin, float forwardScale, float rightScale, float upScale, bool leftShell, bool downShell )
	{
		CBasePlayer@ pPlayer = null;

		if( ePlayer.IsValid() ) @pPlayer = cast<CBasePlayer@>( ePlayer.GetEntity() );
		if( pPlayer !is null ) CS16GetDefaultShellInfo( pPlayer, ShellVelocity, ShellOrigin, forwardScale, rightScale, upScale, leftShell, downShell );
	}

	void CS16GetDefaultShellInfo( CBasePlayer@ pPlayer, Vector& out ShellVelocity, Vector& out ShellOrigin, float forwardScale, float rightScale, float upScale, bool leftShell, bool downShell )
	{  
		Vector vecForward, vecRight, vecUp;

		float fR;
		float fU;

		g_EngineFuncs.AngleVectors( pPlayer.pev.v_angle, vecForward, vecRight, vecUp );

		(leftShell == true) ? fR = Math.RandomFloat( -70, -50 ) : fR = Math.RandomFloat( 50, 70 );
		(downShell == true) ? fU = Math.RandomFloat( -150, -100 ) : fU = Math.RandomFloat( 100, 150 );

		for( int i = 0; i < 3; ++i )
		{
			ShellVelocity[i] = pPlayer.pev.velocity[i] + vecRight[i] * fR + vecUp[i] * fU + vecForward[i] * 25;
			ShellOrigin[i]   = pPlayer.pev.origin[i] + pPlayer.pev.view_ofs[i] + vecUp[i] * upScale + vecForward[i] * forwardScale + vecRight[i] * rightScale;
		}
	}
}