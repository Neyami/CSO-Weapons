//From cstrike Vector CBaseEntity::FireBullets3(Vector vecSrc, Vector vecDirShooting, float flSpread, float flDistance, int iPenetration, int iBulletType, int iDamage, float flRangeModifier, entvars_t *pevAttacker, bool bPistol, int shared_rand)
namespace PENETRATE
{

enum eBulletType
{
	BULLET_PLAYER_45ACP = 18,
	BULLET_PLAYER_50AE,
	BULLET_PLAYER_762MM,
	BULLET_PLAYER_556MM,
	BULLET_PLAYER_338MAG,
	BULLET_PLAYER_57MM,
	BULLET_PLAYER_357SIG
};

//Bullet-Proof Textures
const array<string> pBPTextures = 
{
	"c2a2_dr",	//Blast Door
	"c2a5_dr"	//Secure Access
};
//FirePenetratingBullets( vecSrc, vecAiming, 0, 4096, 2, BULLET_PLAYER_50AE, 54, 0.81f, m_pPlayer.edict(), true, m_pPlayer.random_seed );
Vector FirePenetratingBullets( Vector vecSrc, Vector vecDirShooting, float flSpread, float flDistance, int iPenetration, int iBulletType, float flDamage, float flRangeModifier, EHandle &in ePlayer, bool bPistol, int shared_rand )
{
	CBasePlayer@ pPlayer = null;

	if( ePlayer.IsValid() ) @pPlayer = cast<CBasePlayer@>( ePlayer.GetEntity() );

	const int HITGROUP_SHIELD = HITGROUP_RIGHTLEG + 1;
	float flPenetrationPower;
	float flPenetrationDistance;
	float flCurrentDamage = flDamage;
	float flCurrentDistance;
	TraceResult tr, tr2;
	Vector vecRight = g_Engine.v_right;
	Vector vecUp = g_Engine.v_up;
	CBaseEntity@ pEntity;
	bool bHitMetal = false;
	int iSparksAmount;

	switch( iBulletType )
	{
		case BULLET_PLAYER_9MM:
		{
			flPenetrationPower = 21;
			flPenetrationDistance = 800;
			iSparksAmount = 15;
			flCurrentDamage += (-4 + Math.RandomLong(0, 10));
			break;
		}

		case BULLET_PLAYER_45ACP:
		{
			flPenetrationPower = 15;
			flPenetrationDistance = 500;
			iSparksAmount = 20;
			flCurrentDamage += (-2 + Math.RandomLong(0, 4));
			break;
		}

		case BULLET_PLAYER_50AE:
		{
			flPenetrationPower = 30;
			flPenetrationDistance = 1000;
			iSparksAmount = 20;
			flCurrentDamage += (-4 + Math.RandomLong(0, 10));
			break;
		}

		case BULLET_PLAYER_762MM:
		{
			flPenetrationPower = 39;
			flPenetrationDistance = 5000;
			iSparksAmount = 30;
			flCurrentDamage += (-2 + Math.RandomLong(0, 4));
			break;
		}

		case BULLET_PLAYER_556MM:
		{
			flPenetrationPower = 35;
			flPenetrationDistance = 4000;
			iSparksAmount = 30;
			flCurrentDamage += (-3 + Math.RandomLong(0, 6));
			break;
		}

		case BULLET_PLAYER_338MAG:
		{
			flPenetrationPower = 45;
			flPenetrationDistance = 8000;
			iSparksAmount = 30;
			flCurrentDamage += (-4 + Math.RandomLong(0, 8));
			break;
		}

		case BULLET_PLAYER_57MM:
		{
			flPenetrationPower = 30;
			flPenetrationDistance = 2000;
			iSparksAmount = 20;
			flCurrentDamage += (-4 + Math.RandomLong(0, 10));
			break;
		}

		case BULLET_PLAYER_357SIG:
		{
			flPenetrationPower = 25;
			flPenetrationDistance = 800;
			iSparksAmount = 20;
			flCurrentDamage += (-4 + Math.RandomLong(0, 10));
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

	x = g_PlayerFuncs.SharedRandomFloat(shared_rand, -0.5f, 0.5f) + g_PlayerFuncs.SharedRandomFloat(shared_rand + 1, -0.5f, 0.5f);
	y = g_PlayerFuncs.SharedRandomFloat(shared_rand + 2, -0.5f, 0.5f) + g_PlayerFuncs.SharedRandomFloat(shared_rand + 3, -0.5f, 0.5f);

	Vector vecDir = vecDirShooting + x * flSpread * vecRight + y * flSpread * vecUp;
	Vector vecEnd = vecSrc + vecDir * flDistance;
	Vector vecOldSrc;
	Vector vecNewSrc;
	float flDamageModifier = 0.5f;

	while( iPenetration != 0 )
	{
		g_WeaponFuncs.ClearMultiDamage();
		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, pPlayer.edict(), tr );

		//char cTextureType = UTIL_TextureHit( tr, vecSrc, vecEnd );
		string sTexture = g_Utility.TraceTexture( null, vecSrc, vecEnd );
		char cTextureType = g_SoundSystem.FindMaterialType(sTexture);
		bool bSparks = false;

		if( pBPTextures.find( sTexture ) != -1 )
		{
			g_Utility.Ricochet( tr.vecEndPos, 1.0f );
			return tr.vecEndPos;
		}

		if( cTextureType == CHAR_TEX_METAL )
		{
			bSparks = true;
			bHitMetal = true;
			flPenetrationPower *= 0.15f;
			flDamageModifier = 0.2f;
		}
		else if( cTextureType == CHAR_TEX_CONCRETE )
		{
			flPenetrationPower *= 0.25f;
			flDamageModifier = 0.25f;
		}
		else if( cTextureType == CHAR_TEX_GRATE )
		{
			bSparks = true;
			bHitMetal = true;
			flPenetrationPower *= 0.5f;
			flDamageModifier = 0.4f;
		}
		else if( cTextureType == CHAR_TEX_VENT )
		{
			bSparks = true;
			bHitMetal = true;
			flPenetrationPower *= 0.5f;
			flDamageModifier = 0.45f;
		}
		else if( cTextureType == CHAR_TEX_TILE )
		{
			flPenetrationPower *= 0.65f;
			flDamageModifier = 0.3f;
		}
		else if( cTextureType == CHAR_TEX_COMPUTER )
		{
			bSparks = true;
			bHitMetal = true;
			flPenetrationPower *= 0.4f;
			flDamageModifier = 0.45f;
		}
		else if( cTextureType == CHAR_TEX_WOOD )
		{
			flPenetrationPower *= 1;
			flDamageModifier = 0.6f;
		}
		else
			bSparks = false;

		if( tr.flFraction != 1.0f )
		{
			@pEntity = g_EntityFuncs.Instance(tr.pHit);
			iPenetration--;
			flCurrentDistance = tr.flFraction * flDistance;
			flCurrentDamage *= pow(flRangeModifier, flCurrentDistance / 500);

			if( flCurrentDistance > flPenetrationDistance )
				iPenetration = 0;

			if( tr.iHitgroup == HITGROUP_SHIELD )
			{
				iPenetration = 0;

				if( tr.flFraction != 1.0f )
				{
					if( Math.RandomLong(0, 1) == 1 )
						g_SoundSystem.EmitSound( pEntity.edict(), CHAN_VOICE, "custom_weapons/cso/ric_metal-1.wav", 1, ATTN_NORM );
					else
						g_SoundSystem.EmitSound( pEntity.edict(), CHAN_VOICE, "custom_weapons/cso/ric_metal-2.wav", 1, ATTN_NORM );

					g_Utility.Sparks( tr.vecEndPos );

					pEntity.pev.punchangle.x = flCurrentDamage * Math.RandomFloat(-0.15f, 0.15f);
					pEntity.pev.punchangle.z = flCurrentDamage * Math.RandomFloat(-0.15f, 0.15f);

					if( pEntity.pev.punchangle.x < 4 )
						pEntity.pev.punchangle.x = 4;

					if( pEntity.pev.punchangle.z < -5 )
						pEntity.pev.punchangle.z = -5;
					else if( pEntity.pev.punchangle.z > 5 )
						pEntity.pev.punchangle.z = 5;
				}

				break;
			}

			if( tr.pHit.vars.solid == SOLID_BSP and iPenetration != 0 )
			{
				if( bPistol )
					g_WeaponFuncs.DecalGunshot( tr, iBulletType/*, false, pev, bHitMetal*/ );
				else if( Math.RandomLong(0, 3) == 1 )
					g_WeaponFuncs.DecalGunshot( tr, iBulletType/*, true, pev, bHitMetal*/ );

				vecSrc = tr.vecEndPos + (vecDir * flPenetrationPower);
				flDistance = (flDistance - flCurrentDistance) * 0.5f;
				vecEnd = vecSrc + (vecDir * flDistance);

				pEntity.TraceAttack( pPlayer.pev, flCurrentDamage, vecDir, tr, (DMG_BULLET|DMG_NEVERGIB) );
				g_Game.AlertMessage( at_console, "Hit SOLID_BSP: %1 with damage: %2\n", tr.pHit.vars.classname, flCurrentDamage );

				flCurrentDamage *= flDamageModifier;
			}
			else
			{
				if( bPistol )
					g_WeaponFuncs.DecalGunshot( tr, iBulletType/*, false, pev, bHitMetal*/ );
				else if( Math.RandomLong(0, 3) == 1 )
					g_WeaponFuncs.DecalGunshot( tr, iBulletType/*, true, pev, bHitMetal*/ );

				vecSrc = tr.vecEndPos + (vecDir * 42);
				flDistance = (flDistance - flCurrentDistance) * 0.75f;
				vecEnd = vecSrc + (vecDir * flDistance);

				pEntity.TraceAttack( pPlayer.pev, flCurrentDamage, vecDir, tr, (DMG_BULLET|DMG_NEVERGIB) );
				g_Game.AlertMessage( at_console, "Hit entity: %1 with damage: %2\n", tr.pHit.vars.classname, flCurrentDamage );

				flCurrentDamage *= 0.75f;
			}
		}
		else
			iPenetration = 0;

		g_WeaponFuncs.ApplyMultiDamage( pPlayer.pev, pPlayer.pev );
	}

	return Vector(x * flSpread, y * flSpread, 0);
}

} //namespace PENETRATE END