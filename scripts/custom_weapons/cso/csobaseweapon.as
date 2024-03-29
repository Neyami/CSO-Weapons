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

	protected EHandle m_eDropEffect;
	/*protected EHandle m_hDropEffect;
	protected CBaseEntity@ m_pDropEffect
	{
		get const { return cast<CBaseEntity@>(m_hDropEffect.GetEntity()); }
		set { m_hDropEffect = EHandle(@value); }
	}*/

	int m_iWeaponType;
	int m_iShell;
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
			vecVelocity = m_pPlayer.pev.velocity + g_Engine.v_right * Math.RandomFloat(50, 70) + g_Engine.v_up * flUpBoost + g_Engine.v_forward * 25;
		else
			vecVelocity = m_pPlayer.pev.velocity - g_Engine.v_right * Math.RandomFloat(50, 70) + g_Engine.v_up * flUpBoost + g_Engine.v_forward * 25;

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
			m1.WriteByte( 7 );
		m1.End();
	}

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

	void DoMuzzleflash( string szSprite, float flForward, float flRight, float flUp, float flScale, float flRenderamt, float flFramerate, float flRotation = 0.0 )
	{
		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		CSprite@ pMuzzle = g_EntityFuncs.CreateSprite( szSprite, m_pPlayer.GetGunPosition() + g_Engine.v_forward * flForward + g_Engine.v_right * flRight + g_Engine.v_up * flUp, true );
		@pMuzzle.pev.owner = m_pPlayer.edict();
		pMuzzle.SetScale( flScale );
		pMuzzle.SetTransparency( kRenderTransAdd, 255, 255, 255, int(flRenderamt), kRenderFxNone );

		if( flRotation > 0.0 )
		{
			pMuzzle.KeyValue( "vp_type", "VP_TYPE::VP_ORIENTATED" );
			pMuzzle.pev.angles = Vector( 0.0, 0.0, flRotation );
		}

		//pMuzzle.pev.sequence = VP_TYPE::VP_ORIENTATED; //next update ??
		//pMuzzle.pev.effects = EF_SPRITE_CUSTOM_VP; //next update ??
		pMuzzle.AnimateAndDie( flFramerate );
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

	void Think()
	{
		if( cso::bUseDroppedItemEffect )
		{
			if( pev.owner is null and m_eDropEffect.GetEntity() is null and pev.velocity == g_vecZero )
			{
				CBaseEntity@ cbeGunDrop = g_EntityFuncs.Create( "ef_gundrop", pev.origin, g_vecZero, false, self.edict() );
				m_eDropEffect = EHandle( cbeGunDrop );
				cso::ef_gundrop@ pGunDrop = cast<cso::ef_gundrop@>(CastToScriptClass(cbeGunDrop));
				pGunDrop.m_hOwner = EHandle( self );
				pGunDrop.pev.movetype	= MOVETYPE_FOLLOW;
				@pGunDrop.pev.aiment	= self.edict();

				g_EntityFuncs.DispatchSpawn( pGunDrop.self.edict() );
			}
		}

		BaseClass.Think();
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

	//legacy support only
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