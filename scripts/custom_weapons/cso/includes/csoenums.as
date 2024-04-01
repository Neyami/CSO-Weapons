enum csowtypes_e
{
	TYPE_PRIMARY = 0,
	TYPE_SECONDARY,
	TYPE_MELEE,
	TYPE_GRENADE
};

enum eBulletType
{
	BULLET_PLAYER_45ACP = 18,
	BULLET_PLAYER_50AE,
	BULLET_PLAYER_762MM,
	BULLET_PLAYER_556MM,
	BULLET_PLAYER_338MAG,
	BULLET_PLAYER_50BMG,
	BULLET_PLAYER_57MM,
	BULLET_PLAYER_357SIG,
	BULLET_PLAYER_44MAG,
	BULLET_PLAYER_CSOBOW,
	BULLET_PLAYER_FAILNAUGHT,
	BULLET_PLAYER_M95TIGER
};
/*
From CS 1.6
{
	BULLET_NONE = 0,
	BULLET_PLAYER_9MM,
	BULLET_PLAYER_MP5,
	BULLET_PLAYER_357,
	BULLET_PLAYER_BUCKSHOT,
	BULLET_PLAYER_CROWBAR, //5

	BULLET_MONSTER_9MM,
	BULLET_MONSTER_MP5,
	BULLET_MONSTER_12MM,

	BULLET_PLAYER_45ACP,
	BULLET_PLAYER_338MAG, //10
	BULLET_PLAYER_762MM,
	BULLET_PLAYER_556MM,
	BULLET_PLAYER_50AE,
	BULLET_PLAYER_57MM,
	BULLET_PLAYER_357SIG //15
} 
*/
enum eTrailType
{
	TRAIL_NONE = 0,
	TRAIL_CSOBOW,
	TRAIL_FAILNAUGHT,
	TRAIL_M95TIGER
};

enum SMOKETYPE
{
	SMOKE_RIFLE = 0,
	SMOKE_WALL1,
	SMOKE_WALL2,
	SMOKE_WALL3,
	SMOKE_WALL4
};

enum csowhands_e
{
	HANDS_MALE = 0,
	HANDS_FEMALE,
	HANDS_SVENCOOP
};

enum csowmeleehit_e
{
	HIT_NOTHING = 0,
	HIT_ENEMY,
	HIT_WALL
};

enum sniperZoom
{
	MODE_NOZOOM,
	MODE_ZOOM1,
	MODE_ZOOM2
};

enum cso_dmg
{
	DMG_ANTIZOMBIE = 268435456
};

enum cso_firebulletsflags
{
	CSOF_HITMARKER = 1,
	CSOF_ALWAYSDECAL = 2,
	CSOF_TRACER = 4,
	CSOF_ETHEREAL = 8
};


namespace cso
{

const array<string> g_arrsKnockbackImmuneMobs =
{
	"monster_nihilanth",
	"monster_bigmomma",
	"monster_gargantua",
	"monster_apache",
	"monster_miniturret",
	"monster_turret",
	"monster_barnacle",
	"monster_blkop_apache",
	"monster_blkop_osprey",
	"monster_furniture",
	"monster_handgrenade",
	"monster_ichthyosaur",
	"monster_kingpin",
	"monster_mortar",
	"monster_op4loader",
	"monster_osprey",
	"monster_tentacle",
	"monster_tentaclemaw",
	"monster_tripmine",
	"monster_vortigaunt",
	"npc_fallentitan"
};

const array<string> g_arrsFemaleModels =
{
	"latexchicknero",
	"latex_chick",
	"barniel",
	"colette",
	"fassn",
	"gina",
	"kate",
	"ta_support",
	"th_nurse",
	"40k_Sisters_Tenshi",
	"alyx_hd",
	"backbeard",
	"bluebikini",
	"bluecoat",
	"bunny_Gumi",
	"bunny_Haku",
	"bunny_IA",
	"bunny_Luka",
	"bunny_Meko",
	"bunny_Miku",
	"bunny_Rin",
	"bunny_Teto",
	"bunny_yukari_v2",
	"BWTGS_sana",
	"GS_Ethel_FairyF",
	"GS_Miku",
	"GS_Miku_1",
	"GS_MikuPanda",
	"GS_SoldierGirl_v2",
	"HatsuneMiku1",
	"KC_Hibiki_N",
	"kurumi_tokisaki",
	"KZ_LoliMiku",
	"mikuaction",
	"MikuAngel",
	"MikuHatsune_v2",
	"kate",
	"latexchicknero",
	"mikofox",
	"Monogatari_hanekawa_0B",
	"Monogatari_hanekawa_1B",
	"Monogatari_hanekawa_B",
	"Monogatari_Shinobu",
	"naruto_Hinata",
	"naruto_Hinata2",
	"naruto_Sakura",
	"riko_nude",
	"rohani_sc50",
	"samus",
	"SPP_018RZrem",
	"touhou_aya",
	"touhou_chen",
	"touhou_cirno",
	"touhou_daiyousei",
	"touhou_flandre_scarlet",
	"touhou_hieda_no_akyuu",
	"touhou_hinanawi_tenshi",
	"touhou_inaba_tewi",
	"touhou_izayoi_sakuya",
	"touhou_kagerou_v2",
	"touhou_kazami_yuuka_1",
	"touhou_kazami_yuuka_2",
	"touhou_kazami_yuuka_4",
	"touhou_kazami_yuuka_5",
	"touhou_keine",
	"touhou_kirisame_marisa",
	"touhou_Koakuma",
	"touhou_kochiya_sanae",
	"touhou_konpaku_youmu",
	"touhou_mokou",
	"touhou_nagae_iku",
	"touhou_patchouli",
	"touhou_reimu_mmd",
	"touhou_Remilia_Scarlet",
	"touhou_Rinnosuke",
	"touhou_rumia",
	"touhou_tenko",
	"touhou_udongein_gta",
	"touhou_udongein_mmd",
	"touhou_yagokoro_eirin",
	"touhou_yakumo_ran",
	"touhou_yakumo_yukari",
	"victoria",
	"xmas_pussy",
	"youmu_test",
	"yuffie",
	"Yuri"
};

const array<string> g_arrsMaleModels =
{
	"player",
	"aswat",
	"barney",
	"barney2",
	"betagordon",
	"boris",
	"BS_Unarmored_Barney_1",
	"BS_Unarmored_Barney_2",
	"cannibal",
	"cl_suit",
	"DGF_robogrunt",
	"etac",
	"gman",
	"gordon",
	"helmet",
	"hevbarney",
	"hevbarney2",
	"hevscientist",
	"hevscientist2",
	"hevscientist3",
	"hevscientist4",
	"hevscientist5",
	"HL_Construction",
	"HL_Gus",
	"madscientist",
	"massn",
	"massn_blue",
	"massn_green",
	"massn_normal",
	"massn_red",
	"massn_yell",
	"obi09",
	"OP4_Cigar",
	"OP4_Grunt",
	"OP4_Grunt2",
	"OP4_Heavy",
	"OP4_Lance",
	"OP4_Medic",
	"OP4_Medic2",
	"OP4_MP",
	"OP4_MP2",
	"OP4_Recon",
	"OP4_Recon2",
	"OP4_Robot",
	"OP4_Rocket",
	"OP4_Rocket2",
	"OP4_Scientist_Einstein",
	"OP4_Scientist_Luther",
	"OP4_Scientist_Slick",
	"OP4_Scientist_Walter",
	"OP4_Shephard",
	"OP4_Shotgun",
	"OP4_Shotgun2",
	"OP4_Sniper",
	"OP4_Sniper2",
	"OP4_Torch",
	"OP4_Torch2",
	"OP4_Tower",
	"OP4_Tower2"
	"otis",
	"rgrunt",
	"robo",
	"scientist",
	"scientist2",
	"scientist3",
	"scientist4",
	"scientist5",
	"scientist6",
	"ta_assault",
	"ta_flanker",
	"ta_marine",
	"ta_operative",
	"ta_research",
	"ta_tank",
	"th_civpaul",
	"th_cl_suit",
	"th_dave",
	"th_einar",
	"th_einstein",
	"th_gangster",
	"th_host",
	"th_jack",
	"th_neil",
	"th_nypdcop",
	"th_orderly",
	"th_patient",
	"th_paul",
	"th_slick",
	"th_worker",
	"zombie"
};

} //namespace cso END