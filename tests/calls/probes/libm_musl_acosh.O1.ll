; ModuleID = '/tmp/babj/libm_musl_acosh.full.ll'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.log_data = type { double, double, [5 x double], [11 x double], [128 x %struct.anon], [128 x %struct.anon] }
%struct.anon = type { double, double }

@__log_data = hidden local_unnamed_addr constant %struct.log_data { double 0x3FE62E42FEFA3800, double 0x3D2EF35793C76730, [5 x double] [double 0xBFE0000000000001, double 0x3FD555555551305B, double 0xBFCFFFFFFFEB4590, double 0x3FC999B324F10111, double 0xBFC55575E506C89F], [11 x double] [double -5.000000e-01, double 0x3FD5555555555577, double 0xBFCFFFFFFFFFFDCB, double 0x3FC999999995DD0C, double 0xBFC55555556745A7, double 0x3FC24924A344DE30, double 0xBFBFFFFFA4423D65, double 0x3FBC7184282AD6CA, double 0xBFB999EB43B068FF, double 0x3FB78182F7AFD085, double 0xBFB5521375D145CD], [128 x %struct.anon] [%struct.anon { double 0x3FF734F0C3E0DE9F, double 0xBFD7CC7F79E69000 }, %struct.anon { double 0x3FF713786A2CE91F, double 0xBFD76FEEC20D0000 }, %struct.anon { double 0x3FF6F26008FAB5A0, double 0xBFD713E31351E000 }, %struct.anon { double 0x3FF6D1A61F138C7D, double 0xBFD6B85B38287800 }, %struct.anon { double 0x3FF6B1490BC5B4D1, double 0xBFD65D5590807800 }, %struct.anon { double 0x3FF69147332F0CBA, double 0xBFD602D076180000 }, %struct.anon { double 0x3FF6719F18224223, double 0xBFD5A8CA86909000 }, %struct.anon { double 0x3FF6524F99A51ED9, double 0xBFD54F4356035000 }, %struct.anon { double 0x3FF63356AA8F24C4, double 0xBFD4F637C36B4000 }, %struct.anon { double 0x3FF614B36B9DDC14, double 0xBFD49DA7FDA85000 }, %struct.anon { double 0x3FF5F66452C65C4C, double 0xBFD445923989A800 }, %struct.anon { double 0x3FF5D867B5912C4F, double 0xBFD3EDF439B0B800 }, %struct.anon { double 0x3FF5BABCCB5B90DE, double 0xBFD396CE448F7000 }, %struct.anon { double 0x3FF59D61F2D91A78, double 0xBFD3401E17BDA000 }, %struct.anon { double 0x3FF5805612465687, double 0xBFD2E9E2EF468000 }, %struct.anon { double 0x3FF56397CEE76BD3, double 0xBFD2941B3830E000 }, %struct.anon { double 0x3FF54725E2A77F93, double 0xBFD23EC58CDA8800 }, %struct.anon { double 0x3FF52AFF42064583, double 0xBFD1E9E129279000 }, %struct.anon { double 0x3FF50F22DBB2BDDF, double 0xBFD1956D2B48F800 }, %struct.anon { double 0x3FF4F38F4734DED7, double 0xBFD141679AB9F800 }, %struct.anon { double 0x3FF4D843CFDE2840, double 0xBFD0EDD094EF9800 }, %struct.anon { double 0x3FF4BD3EC078A3C8, double 0xBFD09AA518DB1000 }, %struct.anon { double 0x3FF4A27FC3E0258A, double 0xBFD047E65263B800 }, %struct.anon { double 0x3FF4880524D48434, double 0xBFCFEB224586F000 }, %struct.anon { double 0x3FF46DCE1B192D0B, double 0xBFCF474A7517B000 }, %struct.anon { double 0x3FF453D9D3391854, double 0xBFCEA4443D103000 }, %struct.anon { double 0x3FF43A2744B4845A, double 0xBFCE020D44E9B000 }, %struct.anon { double 0x3FF420B54115F8FB, double 0xBFCD60A22977F000 }, %struct.anon { double 0x3FF40782DA3EF4B1, double 0xBFCCC00104959000 }, %struct.anon { double 0x3FF3EE8F5D57FE8F, double 0xBFCC202956891000 }, %struct.anon { double 0x3FF3D5D9A00B4CE9, double 0xBFCB81178D811000 }, %struct.anon { double 0x3FF3BD60C010C12B, double 0xBFCAE2C9CCD3D000 }, %struct.anon { double 0x3FF3A5242B75DAB8, double 0xBFCA45402E129000 }, %struct.anon { double 0x3FF38D22CD9FD002, double 0xBFC9A877681DF000 }, %struct.anon { double 0x3FF3755BC5847A1C, double 0xBFC90C6D69483000 }, %struct.anon { double 0x3FF35DCE49AD36E2, double 0xBFC87120A645C000 }, %struct.anon { double 0x3FF34679984DD440, double 0xBFC7D68FB4143000 }, %struct.anon { double 0x3FF32F5CCEFFCB24, double 0xBFC73CB83C627000 }, %struct.anon { double 0x3FF3187775A10D49, double 0xBFC6A39A9B376000 }, %struct.anon { double 0x3FF301C8373E3990, double 0xBFC60B3154B7A000 }, %struct.anon { double 0x3FF2EB4EBB95F841, double 0xBFC5737D76243000 }, %struct.anon { double 0x3FF2D50A0219A9D1, double 0xBFC4DC7B8FC23000 }, %struct.anon { double 0x3FF2BEF9A8B7FD2A, double 0xBFC4462C51D20000 }, %struct.anon { double 0x3FF2A91C7A0C1BAB, double 0xBFC3B08ABC830000 }, %struct.anon { double 0x3FF293726014B530, double 0xBFC31B996B490000 }, %struct.anon { double 0x3FF27DFA5757A1F5, double 0xBFC2875490A44000 }, %struct.anon { double 0x3FF268B39B1D3BBF, double 0xBFC1F3B9F879A000 }, %struct.anon { double 0x3FF2539D838FF5BD, double 0xBFC160C8252CA000 }, %struct.anon { double 0x3FF23EB7AAC9083B, double 0xBFC0CE7F57F72000 }, %struct.anon { double 0x3FF22A012BA940B6, double 0xBFC03CDC49FEA000 }, %struct.anon { double 0x3FF2157996CC4132, double 0xBFBF57BDBC4B8000 }, %struct.anon { double 0x3FF201201DD2FC9B, double 0xBFBE370896404000 }, %struct.anon { double 0x3FF1ECF4494D480B, double 0xBFBD17983EF94000 }, %struct.anon { double 0x3FF1D8F5528F6569, double 0xBFBBF9674ED8A000 }, %struct.anon { double 0x3FF1C52311577E7C, double 0xBFBADC79202F6000 }, %struct.anon { double 0x3FF1B17C74CB26E9, double 0xBFB9C0C3E7288000 }, %struct.anon { double 0x3FF19E010C2C1AB6, double 0xBFB8A646B372C000 }, %struct.anon { double 0x3FF18AB07BB670BD, double 0xBFB78D01B3AC0000 }, %struct.anon { double 0x3FF1778A25EFBCB6, double 0xBFB674F145380000 }, %struct.anon { double 0x3FF1648D354C31DA, double 0xBFB55E0E6D878000 }, %struct.anon { double 0x3FF151B990275FDD, double 0xBFB4485CDEA1E000 }, %struct.anon { double 0x3FF13F0EA432D24C, double 0xBFB333D94D6AA000 }, %struct.anon { double 0x3FF12C8B7210F9DA, double 0xBFB22079F8C56000 }, %struct.anon { double 0x3FF11A3028ECB531, double 0xBFB10E4698622000 }, %struct.anon { double 0x3FF107FBDA8434AF, double 0xBFAFFA6C6AD20000 }, %struct.anon { double 0x3FF0F5EE0F4E6BB3, double 0xBFADDA8D4A774000 }, %struct.anon { double 0x3FF0E4065D2A9FCE, double 0xBFABBCECE4850000 }, %struct.anon { double 0x3FF0D244632CA521, double 0xBFA9A1894012C000 }, %struct.anon { double 0x3FF0C0A77CE2981A, double 0xBFA788583302C000 }, %struct.anon { double 0x3FF0AF2F83C636D1, double 0xBFA5715E67D68000 }, %struct.anon { double 0x3FF09DDB98A01339, double 0xBFA35C8A49658000 }, %struct.anon { double 0x3FF08CABAF52E7DF, double 0xBFA149E364154000 }, %struct.anon { double 0x3FF07B9F2F4E28FB, double 0xBF9E72C082EB8000 }, %struct.anon { double 0x3FF06AB58C358F19, double 0xBF9A55F152528000 }, %struct.anon { double 0x3FF059EEA5ECF92C, double 0xBF963D62CF818000 }, %struct.anon { double 0x3FF04949CDD12C90, double 0xBF9228FB8CAA0000 }, %struct.anon { double 0x3FF038C6C6F0ADA9, double 0xBF8C317B20F90000 }, %struct.anon { double 0x3FF02865137932A9, double 0xBF8419355DAA0000 }, %struct.anon { double 0x3FF0182427EA7348, double 0xBF781203C2EC0000 }, %struct.anon { double 0x3FF008040614B195, double 0xBF60040979240000 }, %struct.anon { double 0x3FEFE01FF726FA1A, double 0x3F6FEFF384900000 }, %struct.anon { double 0x3FEFA11CC261EA74, double 0x3F87DC41353D0000 }, %struct.anon { double 0x3FEF6310B081992E, double 0x3F93CEA3C4C28000 }, %struct.anon { double 0x3FEF25F63CEEADCD, double 0x3F9B9FC114890000 }, %struct.anon { double 0x3FEEE9C8039113E7, double 0x3FA1B0D8CE110000 }, %struct.anon { double 0x3FEEAE8078CBB1AB, double 0x3FA58A5BD001C000 }, %struct.anon { double 0x3FEE741AA29D0C9B, double 0x3FA95C8340D88000 }, %struct.anon { double 0x3FEE3A91830A99B5, double 0x3FAD276AEF578000 }, %struct.anon { double 0x3FEE01E009609A56, double 0x3FB07598E598C000 }, %struct.anon { double 0x3FEDCA01E577BB98, double 0x3FB253F5E30D2000 }, %struct.anon { double 0x3FED92F20B7C9103, double 0x3FB42EDD8B380000 }, %struct.anon { double 0x3FED5CAC66FB5CCE, double 0x3FB606598757C000 }, %struct.anon { double 0x3FED272CAA5EDE9D, double 0x3FB7DA76356A0000 }, %struct.anon { double 0x3FECF26E3E6B2CCD, double 0x3FB9AB434E1C6000 }, %struct.anon { double 0x3FECBE6DA2A77902, double 0x3FBB78C7BB0D6000 }, %struct.anon { double 0x3FEC8B266D37086D, double 0x3FBD431332E72000 }, %struct.anon { double 0x3FEC5894BD5D5804, double 0x3FBF0A3171DE6000 }, %struct.anon { double 0x3FEC26B533BB9F8C, double 0x3FC067152B914000 }, %struct.anon { double 0x3FEBF583EEECE73F, double 0x3FC147858292B000 }, %struct.anon { double 0x3FEBC4FD75DB96C1, double 0x3FC2266ECDCA3000 }, %struct.anon { double 0x3FEB951E0C864A28, double 0x3FC303D7A6C55000 }, %struct.anon { double 0x3FEB65E2C5EF3E2C, double 0x3FC3DFC33C331000 }, %struct.anon { double 0x3FEB374867C9888B, double 0x3FC4BA366B7A8000 }, %struct.anon { double 0x3FEB094B211D304A, double 0x3FC5933928D1F000 }, %struct.anon { double 0x3FEADBE885F2EF7E, double 0x3FC66ACD2418F000 }, %struct.anon { double 0x3FEAAF1D31603DA2, double 0x3FC740F8EC669000 }, %struct.anon { double 0x3FEA82E63FD358A7, double 0x3FC815C0F51AF000 }, %struct.anon { double 0x3FEA5740EF09738B, double 0x3FC8E92954F68000 }, %struct.anon { double 0x3FEA2C2A90AB4B27, double 0x3FC9BB3602F84000 }, %struct.anon { double 0x3FEA01A01393F2D1, double 0x3FCA8BED1C2C0000 }, %struct.anon { double 0x3FE9D79F24DB3C1B, double 0x3FCB5B515C01D000 }, %struct.anon { double 0x3FE9AE2505C7B190, double 0x3FCC2967CCBCC000 }, %struct.anon { double 0x3FE9852EF297CE2F, double 0x3FCCF635D5486000 }, %struct.anon { double 0x3FE95CBAEEA44B75, double 0x3FCDC1BD3446C000 }, %struct.anon { double 0x3FE934C69DE74838, double 0x3FCE8C01B8CFE000 }, %struct.anon { double 0x3FE90D4F2F6752E6, double 0x3FCF5509C0179000 }, %struct.anon { double 0x3FE8E6528EFFD79D, double 0x3FD00E6C121FB800 }, %struct.anon { double 0x3FE8BFCE9FCC007C, double 0x3FD071B80E93D000 }, %struct.anon { double 0x3FE899C0DABEC30E, double 0x3FD0D46B9E867000 }, %struct.anon { double 0x3FE87427AA2317FB, double 0x3FD13687334BD000 }, %struct.anon { double 0x3FE84F00ACB39A08, double 0x3FD1980D67234800 }, %struct.anon { double 0x3FE82A49E8653E55, double 0x3FD1F8FFE0CC8000 }, %struct.anon { double 0x3FE8060195F40260, double 0x3FD2595FD7636800 }, %struct.anon { double 0x3FE7E22563E0A329, double 0x3FD2B9300914A800 }, %struct.anon { double 0x3FE7BEB377DCB5AD, double 0x3FD3187210436000 }, %struct.anon { double 0x3FE79BAA679725C2, double 0x3FD377266DEC1800 }, %struct.anon { double 0x3FE77907F2170657, double 0x3FD3D54FFBAF3000 }, %struct.anon { double 0x3FE756CADBD6130C, double 0x3FD432EEE32FE000 }], [128 x %struct.anon] [%struct.anon { double 0x3FE61000014FB66B, double 0x3C7E026C91425B3C }, %struct.anon { double 0x3FE63000034DB495, double 0x3C8DBFEA48005D41 }, %struct.anon { double 0x3FE650000D94D478, double 0x3C8E7FA786D6A5B7 }, %struct.anon { double 0x3FE67000074E6FAD, double 0x3C61FCEA6B54254C }, %struct.anon { double 0x3FE68FFFFEDF0FAE, double 0xBC7C7E274C590EFD }, %struct.anon { double 0x3FE6B0000763C5BC, double 0xBC8AC16848DCDA01 }, %struct.anon { double 0x3FE6D0001E5CC1F6, double 0x3C833F1C9D499311 }, %struct.anon { double 0x3FE6EFFFEB05F63E, double 0xBC7E80041AE22D53 }, %struct.anon { double 0x3FE710000E869780, double 0x3C7BFF6671097952 }, %struct.anon { double 0x3FE72FFFFC67E912, double 0x3C8C00E226BD8724 }, %struct.anon { double 0x3FE74FFFDF81116A, double 0xBC6E02916EF101D2 }, %struct.anon { double 0x3FE770000F679C90, double 0xBC67FC71CD549C74 }, %struct.anon { double 0x3FE78FFFFA7EC835, double 0x3C81BEC19EF50483 }, %struct.anon { double 0x3FE7AFFFFE20C2E6, double 0xBC707E1729CC6465 }, %struct.anon { double 0x3FE7CFFFED3FC900, double 0xBC808072087B8B1C }, %struct.anon { double 0x3FE7EFFFE9261A76, double 0x3C8DC0286D9DF9AE }, %struct.anon { double 0x3FE81000049CA3E8, double 0x3C897FD251E54C33 }, %struct.anon { double 0x3FE8300017932C8F, double 0xBC8AFEE9B630F381 }, %struct.anon { double 0x3FE850000633739C, double 0x3C89BFBF6B6535BC }, %struct.anon { double 0x3FE87000204289C6, double 0xBC8BBF65F3117B75 }, %struct.anon { double 0x3FE88FFFEBF57904, double 0xBC89006EA23DCB57 }, %struct.anon { double 0x3FE8B00022BC04DF, double 0xBC7D00DF38E04B0A }, %struct.anon { double 0x3FE8CFFFE50C1B8A, double 0xBC88007146FF9F05 }, %struct.anon { double 0x3FE8EFFFFC918E43, double 0x3C83817BD07A7038 }, %struct.anon { double 0x3FE910001EFA5FC7, double 0x3C893E9176DFB403 }, %struct.anon { double 0x3FE9300013467BB9, double 0x3C7F804E4B980276 }, %struct.anon { double 0x3FE94FFFE6EE076F, double 0xBC8F7EF0D9FF622E }, %struct.anon { double 0x3FE96FFFDE3C12D1, double 0xBC7082AA962638BA }, %struct.anon { double 0x3FE98FFFF4458A0D, double 0xBC87801B9164A8EF }, %struct.anon { double 0x3FE9AFFFDD982E3E, double 0xBC8740E08A5A9337 }, %struct.anon { double 0x3FE9CFFFED49FB66, double 0x3C3FCE08C19BE000 }, %struct.anon { double 0x3FE9F00020F19C51, double 0xBC8A3FAA27885B0A }, %struct.anon { double 0x3FEA10001145B006, double 0x3C74FF489958DA56 }, %struct.anon { double 0x3FEA300007BBF6FA, double 0x3C8CBEAB8A2B6D18 }, %struct.anon { double 0x3FEA500010971D79, double 0x3C88FECADD787930 }, %struct.anon { double 0x3FEA70001DF52E48, double 0xBC8F41763DD8ABDB }, %struct.anon { double 0x3FEA90001C593352, double 0xBC8EBF0284C27612 }, %struct.anon { double 0x3FEAB0002A4F3E4B, double 0xBC69FD043CFF3F5F }, %struct.anon { double 0x3FEACFFFD7AE1ED1, double 0xBC823EE7129070B4 }, %struct.anon { double 0x3FEAEFFFEE510478, double 0x3C6A063EE00EDEA3 }, %struct.anon { double 0x3FEB0FFFDB650D5B, double 0x3C5A06C8381F0AB9 }, %struct.anon { double 0x3FEB2FFFFEAACA57, double 0xBC79011E74233C1D }, %struct.anon { double 0x3FEB4FFFD995BADC, double 0xBC79FF1068862A9F }, %struct.anon { double 0x3FEB7000249E659C, double 0x3C8AFF45D0864F3E }, %struct.anon { double 0x3FEB8FFFF9871640, double 0x3C7CFE7796C2C3F9 }, %struct.anon { double 0x3FEBAFFFD204CB4F, double 0xBC63FF27EEF22BC4 }, %struct.anon { double 0x3FEBCFFFD2415C45, double 0xBC6CFFB7EE3BEA21 }, %struct.anon { double 0x3FEBEFFFF86309DF, double 0xBC814103972E0B5C }, %struct.anon { double 0x3FEC0FFFE1B57653, double 0x3C8BC16494B76A19 }, %struct.anon { double 0x3FEC2FFFF1FA57E3, double 0xBC64FEEF8D30C6ED }, %struct.anon { double 0x3FEC4FFFDCBFE424, double 0xBC843F68BCEC4775 }, %struct.anon { double 0x3FEC6FFFED54B9F7, double 0x3C847EA3F053E0EC }, %struct.anon { double 0x3FEC8FFFEB998FD5, double 0x3C7383068DF992F1 }, %struct.anon { double 0x3FECB0002125219A, double 0xBC68FD8E64180E04 }, %struct.anon { double 0x3FECCFFFDD94469C, double 0x3C8E7EBE1CC7EA72 }, %struct.anon { double 0x3FECEFFFEAFDC476, double 0x3C8EBE39AD9F88FE }, %struct.anon { double 0x3FED1000169AF82B, double 0x3C757D91A8B95A71 }, %struct.anon { double 0x3FED30000D0FF71D, double 0x3C89C1906970C7DA }, %struct.anon { double 0x3FED4FFFEA790FC4, double 0xBC580E37C558FE0C }, %struct.anon { double 0x3FED70002EDC87E5, double 0xBC7F80D64DC10F44 }, %struct.anon { double 0x3FED900021DC82AA, double 0xBC747C8F94FD5C5C }, %struct.anon { double 0x3FEDAFFFD86B0283, double 0x3C8C7F1DC521617E }, %struct.anon { double 0x3FEDD000296C4739, double 0x3C88019EB2FFB153 }, %struct.anon { double 0x3FEDEFFFE54490F5, double 0x3C6E00D2C652CC89 }, %struct.anon { double 0x3FEE0FFFCDABF694, double 0xBC7F8340202D69D2 }, %struct.anon { double 0x3FEE2FFFDB52C8DD, double 0x3C7B00C1CA1B0864 }, %struct.anon { double 0x3FEE4FFFF24216EF, double 0x3C72FFA8B094AB51 }, %struct.anon { double 0x3FEE6FFFE88A5E11, double 0xBC57F673B1EFBE59 }, %struct.anon { double 0x3FEE9000119EFF0D, double 0xBC84808D5E0BC801 }, %struct.anon { double 0x3FEEAFFFDFA51744, double 0x3C780006D54320B5 }, %struct.anon { double 0x3FEED0001A127FA1, double 0xBC5002F860565C92 }, %struct.anon { double 0x3FEEF00007BABCC4, double 0xBC8540445D35E611 }, %struct.anon { double 0x3FEF0FFFF57A8D02, double 0xBC4FFB3139EF9105 }, %struct.anon { double 0x3FEF30001EE58AC7, double 0x3C8A81ACF2731155 }, %struct.anon { double 0x3FEF4FFFF5823494, double 0x3C8A3F41D4D7C743 }, %struct.anon { double 0x3FEF6FFFFCA94C6B, double 0xBC6202F41C987875 }, %struct.anon { double 0x3FEF8FFFE1F9C441, double 0x3C777DD1F477E74B }, %struct.anon { double 0x3FEFAFFFD2E0E37E, double 0xBC6F01199A7CA331 }, %struct.anon { double 0x3FEFD0001C77E49E, double 0x3C7181EE4BCEACB1 }, %struct.anon { double 0x3FEFEFFFF7E0C331, double 0xBC6E05370170875A }, %struct.anon { double 0x3FF00FFFF465606E, double 0xBC8A7EAD491C0ADA }, %struct.anon { double 0x3FF02FFFF3867A58, double 0xBC977F69C3FCB2E0 }, %struct.anon { double 0x3FF04FFFFDFC0D17, double 0x3C97BFFE34CB945B }, %struct.anon { double 0x3FF0700003CD4D82, double 0x3C820083C0E456CB }, %struct.anon { double 0x3FF08FFFF9F2CBE8, double 0xBC6DFFDFBE37751A }, %struct.anon { double 0x3FF0B000010CDA65, double 0xBC913F7FAEE626EB }, %struct.anon { double 0x3FF0D00001A4D338, double 0x3C807DFA79489FF7 }, %struct.anon { double 0x3FF0EFFFFADAFDFD, double 0xBC77040570D66BC0 }, %struct.anon { double 0x3FF110000BBAFD96, double 0x3C8E80D4846D0B62 }, %struct.anon { double 0x3FF12FFFFAE5F45D, double 0x3C9DBFFA64FD36EF }, %struct.anon { double 0x3FF150000DD59AD9, double 0x3C9A0077701250AE }, %struct.anon { double 0x3FF170000F21559A, double 0x3C8DFDF9E2E3DEEE }, %struct.anon { double 0x3FF18FFFFC275426, double 0x3C910030DC3B7273 }, %struct.anon { double 0x3FF1B000123D3C59, double 0x3C997F7980030188 }, %struct.anon { double 0x3FF1CFFFF8299EB7, double 0xBC65F932AB9F8C67 }, %struct.anon { double 0x3FF1EFFFF48AD400, double 0x3C937FBF9DA75BEB }, %struct.anon { double 0x3FF210000C8B86A4, double 0x3C9F806B91FD5B22 }, %struct.anon { double 0x3FF2300003854303, double 0x3C93FFC2EB9FBF33 }, %struct.anon { double 0x3FF24FFFFFBCF684, double 0x3C7601E77E2E2E72 }, %struct.anon { double 0x3FF26FFFF52921D9, double 0x3C7FFCBB767F0C61 }, %struct.anon { double 0x3FF2900014933A3C, double 0xBC7202CA3C02412B }, %struct.anon { double 0x3FF2B00014556313, double 0xBC92808233F21F02 }, %struct.anon { double 0x3FF2CFFFEBFE523B, double 0xBC88FF7E384FDCF2 }, %struct.anon { double 0x3FF2F0000BB8AD96, double 0xBC85FF51503041C5 }, %struct.anon { double 0x3FF30FFFFB7AE2AF, double 0xBC810071885E289D }, %struct.anon { double 0x3FF32FFFFEAC5F7F, double 0xBC91FF5D3FB7B715 }, %struct.anon { double 0x3FF350000CA66756, double 0x3C957F82228B82BD }, %struct.anon { double 0x3FF3700011FBF721, double 0x3C8000BAC40DD5CC }, %struct.anon { double 0x3FF38FFFF9592FB9, double 0xBC943F9D2DB2A751 }, %struct.anon { double 0x3FF3B00004DDD242, double 0x3C857F6B707638E1 }, %struct.anon { double 0x3FF3CFFFF5B2C957, double 0x3C7A023A10BF1231 }, %struct.anon { double 0x3FF3EFFFEAB0B418, double 0x3C987F6D66B152B0 }, %struct.anon { double 0x3FF410001532AFF4, double 0x3C67F8375F198524 }, %struct.anon { double 0x3FF4300017478B29, double 0x3C8301E672DC5143 }, %struct.anon { double 0x3FF44FFFE795B463, double 0x3C89FF69B8B2895A }, %struct.anon { double 0x3FF46FFFE80475E0, double 0xBC95C0B19BC2F254 }, %struct.anon { double 0x3FF48FFFEF6FC1E7, double 0x3C9B4009F23A2A72 }, %struct.anon { double 0x3FF4AFFFE5BEA704, double 0xBC94FFB7BF0D7D45 }, %struct.anon { double 0x3FF4D000171027DE, double 0xBC99C06471DC6A3D }, %struct.anon { double 0x3FF4F0000FF03EE2, double 0x3C977F890B85531C }, %struct.anon { double 0x3FF5100012DC4BD1, double 0x3C6004657166A436 }, %struct.anon { double 0x3FF530001605277A, double 0xBC96BFCECE233209 }, %struct.anon { double 0x3FF54FFFECDB704C, double 0xBC8902720505A1D7 }, %struct.anon { double 0x3FF56FFFEF5F54A9, double 0x3C9BBFE60EC96412 }, %struct.anon { double 0x3FF5900017E61012, double 0x3C887EC581AFEF90 }, %struct.anon { double 0x3FF5B00003C93E92, double 0xBC9F41080ABF0CC0 }, %struct.anon { double 0x3FF5D0001D4919BC, double 0xBC98812AFB254729 }, %struct.anon { double 0x3FF5EFFFE7B87A89, double 0xBC947EB780ED6904 }] }, align 8
@__rsqrt_tab = hidden local_unnamed_addr constant [128 x i16] [i16 -19375, i16 -19728, i16 -20074, i16 -20412, i16 -20743, i16 -21066, i16 -21383, i16 -21693, i16 -21996, i16 -22293, i16 -22584, i16 -22870, i16 -23150, i16 -23424, i16 -23693, i16 -23957, i16 -24216, i16 -24470, i16 -24720, i16 -24965, i16 -25206, i16 -25443, i16 -25675, i16 -25903, i16 -26128, i16 -26349, i16 -26566, i16 -26779, i16 -26989, i16 -27196, i16 -27400, i16 -27600, i16 -27797, i16 -27991, i16 -28182, i16 -28370, i16 -28555, i16 -28738, i16 -28918, i16 -29095, i16 -29270, i16 -29442, i16 -29612, i16 -29780, i16 -29945, i16 -30108, i16 -30268, i16 -30427, i16 -30583, i16 -30738, i16 -30890, i16 -31040, i16 -31189, i16 -31335, i16 -31480, i16 -31623, i16 -31764, i16 -31903, i16 -32040, i16 -32176, i16 -32311, i16 -32443, i16 -32574, i16 -32704, i16 -254, i16 -754, i16 -1243, i16 -1721, i16 -2189, i16 -2646, i16 -3094, i16 -3532, i16 -3961, i16 -4381, i16 -4793, i16 -5197, i16 -5593, i16 -5981, i16 -6361, i16 -6734, i16 -7101, i16 -7460, i16 -7814, i16 -8160, i16 -8501, i16 -8835, i16 -9164, i16 -9487, i16 -9805, i16 -10117, i16 -10424, i16 -10726, i16 -11023, i16 -11315, i16 -11603, i16 -11886, i16 -12165, i16 -12439, i16 -12709, i16 -12975, i16 -13238, i16 -13496, i16 -13750, i16 -14001, i16 -14248, i16 -14492, i16 -14732, i16 -14969, i16 -15203, i16 -15433, i16 -15660, i16 -15884, i16 -16106, i16 -16324, i16 -16539, i16 -16752, i16 -16962, i16 -17169, i16 -17373, i16 -17575, i16 -17775, i16 -17972, i16 -18166, i16 -18358, i16 -18548, i16 -18736, i16 -18921, i16 -19104], align 16

; Function Attrs: nounwind ssp uwtable
define double @f_acosh(double noundef %0) local_unnamed_addr #0 {
  %2 = tail call double @cq_theta_f64(double noundef %0, double noundef 3.000000e-01) #8
  %3 = tail call double @acosh(double noundef %2) #9
  %4 = tail call double @cq_measure_f64(double noundef %3) #10
  ret double %4
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #1

declare double @cq_measure_f64(double noundef) local_unnamed_addr #1

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fmul.f64(double, double, metadata, metadata) #2

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fmuladd.f64(double, double, double, metadata, metadata) #2

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fsub.f64(double, double, metadata, metadata) #2

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fadd.f64(double, double, metadata, metadata) #2

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare float @llvm.experimental.constrained.fptrunc.f32.f64(double, metadata, metadata) #2

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fpext.f64.f32(float, metadata) #2

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare i1 @llvm.experimental.constrained.fcmp.f64(double, double, metadata, metadata) #2

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #3

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #3

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.sitofp.f64.i32(i32, metadata, metadata) #2

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i1 @llvm.is.fpclass.f64(double, i32 immarg) #4

; Function Attrs: nofree norecurse nounwind ssp strictfp memory(inaccessiblemem: readwrite)
define hidden double @__math_divzero(i32 noundef %0) local_unnamed_addr #5 {
  %2 = alloca double, align 8
  %3 = icmp eq i32 %0, 0
  %4 = select i1 %3, double 1.000000e+00, double -1.000000e+00
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %2)
  store volatile double %4, ptr %2, align 8
  %5 = load volatile double, ptr %2, align 8
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %2)
  %6 = tail call double @llvm.experimental.constrained.fdiv.f64(double %5, double 0.000000e+00, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  ret double %6
}

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fdiv.f64(double, double, metadata, metadata) #2

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp strictfp willreturn memory(inaccessiblemem: readwrite)
define hidden double @__math_invalid(double noundef %0) local_unnamed_addr #6 {
  %2 = tail call double @llvm.experimental.constrained.fsub.f64(double %0, double %0, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %3 = tail call double @llvm.experimental.constrained.fsub.f64(double %0, double %0, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %4 = tail call double @llvm.experimental.constrained.fdiv.f64(double %2, double %3, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  ret double %4
}

; Function Attrs: nounwind ssp strictfp
define double @sqrt(double noundef %0) local_unnamed_addr #7 {
  %2 = bitcast double %0 to i64
  %3 = lshr i64 %2, 52
  %4 = add nsw i64 %3, -2047
  %5 = icmp ult i64 %4, -2046
  br i1 %5, label %6, label %19, !prof !7

6:                                                ; preds = %1
  %7 = tail call i1 @llvm.is.fpclass.f64(double %0, i32 96)
  %8 = icmp eq i64 %2, 9218868437227405312
  %9 = or i1 %7, %8
  br i1 %9, label %96, label %10

10:                                               ; preds = %6
  %11 = icmp ugt i64 %2, 9218868437227405312
  br i1 %11, label %12, label %14

12:                                               ; preds = %10
  %13 = tail call double @__math_invalid(double noundef %0) #12
  br label %96

14:                                               ; preds = %10
  %15 = tail call double @llvm.experimental.constrained.fmul.f64(double %0, double 0x4330000000000000, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %16 = bitcast double %15 to i64
  %17 = lshr i64 %16, 52
  %18 = add nsw i64 %17, -52
  br label %19

19:                                               ; preds = %14, %1
  %20 = phi i64 [ %18, %14 ], [ %3, %1 ]
  %21 = phi i64 [ %16, %14 ], [ %2, %1 ]
  %22 = shl i64 %21, 11
  %23 = or i64 %22, -9223372036854775808
  %24 = and i64 %20, 1
  %25 = lshr exact i64 %23, %24
  %26 = lshr i64 %21, 46
  %27 = and i64 %26, 127
  %28 = getelementptr inbounds [128 x i16], ptr @__rsqrt_tab, i64 0, i64 %27
  %29 = load i16, ptr %28, align 2
  %30 = zext i16 %29 to i64
  %31 = shl nuw nsw i64 %30, 16
  %32 = lshr i64 %25, 32
  %33 = mul nuw i64 %32, %31
  %34 = lshr i64 %33, 32
  %35 = mul nuw i64 %34, %31
  %36 = lshr i64 %35, 32
  %37 = sub nsw i64 3221225472, %36
  %38 = and i64 %37, 4294967295
  %39 = mul nuw i64 %38, %31
  %40 = lshr i64 %39, 31
  %41 = and i64 %40, 4294967294
  %42 = mul nuw i64 %38, %34
  %43 = lshr i64 %42, 31
  %44 = and i64 %43, 4294967294
  %45 = mul nuw i64 %41, %44
  %46 = lshr i64 %45, 32
  %47 = sub nsw i64 3221225472, %46
  %48 = and i64 %47, 4294967295
  %49 = mul nuw i64 %48, %41
  %50 = lshr i64 %49, 31
  %51 = and i64 %50, 4294967294
  %52 = and i64 %25, 4294966272
  %53 = mul nuw i64 %51, %32
  %54 = mul nuw i64 %51, %52
  %55 = lshr i64 %54, 32
  %56 = add nuw i64 %55, %53
  %57 = lshr i64 %56, 32
  %58 = and i64 %56, 4294967295
  %59 = mul nuw i64 %57, %51
  %60 = mul nuw i64 %58, %51
  %61 = lshr i64 %60, 32
  %62 = add nuw i64 %59, %61
  %63 = sub i64 -4611686018427387904, %62
  %64 = lshr i64 %63, 32
  %65 = and i64 %63, 4294967295
  %66 = mul nuw i64 %64, %57
  %67 = mul nuw i64 %65, %57
  %68 = lshr i64 %67, 32
  %69 = mul nuw i64 %64, %58
  %70 = lshr i64 %69, 32
  %71 = add i64 %66, -2
  %72 = add i64 %71, %68
  %73 = add i64 %72, %70
  %74 = lshr i64 %73, 9
  %75 = shl i64 %25, 42
  %76 = mul i64 %74, %74
  %77 = sub i64 %76, %75
  %78 = add i64 %77, %74
  %79 = add nuw nsw i64 %74, 1
  %80 = add i64 %79, %78
  %81 = lshr i64 %78, 63
  %82 = add nuw nsw i64 %81, %74
  %83 = and i64 %82, 4503599627370495
  %84 = shl nsw i64 %20, 51
  %85 = add i64 %84, 2303591209400008704
  %86 = and i64 %85, -4503599627370496
  %87 = or disjoint i64 %83, %86
  %88 = bitcast i64 %87 to double
  %89 = icmp eq i64 %80, 0
  %90 = select i1 %89, i64 0, i64 4503599627370496, !prof !7
  %91 = xor i64 %80, %78
  %92 = and i64 %91, -9223372036854775808
  %93 = or disjoint i64 %90, %92
  %94 = bitcast i64 %93 to double
  %95 = tail call double @llvm.experimental.constrained.fadd.f64(double %88, double %94, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  br label %96

96:                                               ; preds = %19, %12, %6
  %97 = phi double [ %13, %12 ], [ %95, %19 ], [ %0, %6 ]
  ret double %97
}

; Function Attrs: nounwind ssp strictfp
define double @acosh(double noundef %0) local_unnamed_addr #7 {
  %2 = bitcast double %0 to i64
  %3 = icmp ult i64 %2, 4611686018427387904
  br i1 %3, label %4, label %19

4:                                                ; preds = %1
  %5 = tail call double @llvm.experimental.constrained.sitofp.f64.i32(i32 1, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %6 = tail call double @llvm.experimental.constrained.fsub.f64(double %0, double %5, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %7 = tail call double @llvm.experimental.constrained.sitofp.f64.i32(i32 1, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %8 = tail call double @llvm.experimental.constrained.fsub.f64(double %0, double %7, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %9 = tail call double @llvm.experimental.constrained.sitofp.f64.i32(i32 1, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %10 = tail call double @llvm.experimental.constrained.fsub.f64(double %0, double %9, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %11 = tail call double @llvm.experimental.constrained.sitofp.f64.i32(i32 2, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %12 = tail call double @llvm.experimental.constrained.sitofp.f64.i32(i32 1, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %13 = tail call double @llvm.experimental.constrained.fsub.f64(double %0, double %12, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %14 = tail call double @llvm.experimental.constrained.fmul.f64(double %11, double %13, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %15 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %8, double %10, double %14, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %16 = tail call double @sqrt(double noundef %15) #12
  %17 = tail call double @llvm.experimental.constrained.fadd.f64(double %6, double %16, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %18 = tail call double @log1p(double noundef %17) #12
  br label %42

19:                                               ; preds = %1
  %20 = icmp ult i64 %2, 4724276009111650304
  br i1 %20, label %21, label %33

21:                                               ; preds = %19
  %22 = tail call double @llvm.experimental.constrained.sitofp.f64.i32(i32 2, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %23 = tail call double @llvm.experimental.constrained.sitofp.f64.i32(i32 1, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %24 = tail call double @llvm.experimental.constrained.sitofp.f64.i32(i32 1, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %25 = fneg double %24
  %26 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %0, double %0, double %25, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %27 = tail call double @sqrt(double noundef %26) #12
  %28 = tail call double @llvm.experimental.constrained.fadd.f64(double %0, double %27, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %29 = tail call double @llvm.experimental.constrained.fdiv.f64(double %23, double %28, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %30 = fneg double %29
  %31 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %22, double %0, double %30, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %32 = tail call double @log(double noundef %31) #12
  br label %42

33:                                               ; preds = %19
  %34 = icmp sgt i64 %2, -1
  br i1 %34, label %39, label %35

35:                                               ; preds = %33
  %36 = tail call double @llvm.experimental.constrained.fsub.f64(double %0, double %0, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %37 = tail call double @llvm.experimental.constrained.fsub.f64(double %0, double %0, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %38 = tail call double @llvm.experimental.constrained.fdiv.f64(double %36, double %37, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  br label %42

39:                                               ; preds = %33
  %40 = tail call double @log(double noundef %0) #12
  %41 = tail call double @llvm.experimental.constrained.fadd.f64(double %40, double 0x3FE62E42FEFA39EF, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  br label %42

42:                                               ; preds = %39, %35, %21, %4
  %43 = phi double [ %18, %4 ], [ %32, %21 ], [ %38, %35 ], [ %41, %39 ]
  ret double %43
}

; Function Attrs: nofree norecurse nounwind ssp strictfp memory(inaccessiblemem: readwrite)
define double @log1p(double noundef %0) local_unnamed_addr #5 {
  %2 = alloca float, align 4
  %3 = bitcast double %0 to i64
  %4 = lshr i64 %3, 32
  %5 = trunc nuw i64 %4 to i32
  %6 = icmp sgt i64 %3, 4601133429810003967
  br i1 %6, label %29, label %7

7:                                                ; preds = %1
  %8 = icmp ugt i64 %3, -4616189618054758401
  br i1 %8, label %9, label %17

9:                                                ; preds = %7
  %10 = tail call double @llvm.experimental.constrained.sitofp.f64.i32(i32 -1, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %11 = tail call i1 @llvm.experimental.constrained.fcmp.f64(double %0, double %10, metadata !"oeq", metadata !"fpexcept.ignore") #11
  br i1 %11, label %12, label %14

12:                                               ; preds = %9
  %13 = tail call double @llvm.experimental.constrained.fdiv.f64(double %0, double 0.000000e+00, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  br label %90

14:                                               ; preds = %9
  %15 = tail call double @llvm.experimental.constrained.fsub.f64(double %0, double %0, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %16 = tail call double @llvm.experimental.constrained.fdiv.f64(double %15, double 0.000000e+00, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  br label %90

17:                                               ; preds = %7
  %18 = shl i32 %5, 1
  %19 = icmp ult i32 %18, 2034237440
  br i1 %19, label %20, label %25

20:                                               ; preds = %17
  %21 = and i32 %5, 2146435072
  %22 = icmp eq i32 %21, 0
  br i1 %22, label %23, label %90

23:                                               ; preds = %20
  %24 = tail call float @llvm.experimental.constrained.fptrunc.f32.f64(double %0, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %2)
  store volatile float %24, ptr %2, align 4
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %2)
  br label %90

25:                                               ; preds = %17
  %26 = icmp ult i64 %3, -4624424114038243328
  br i1 %26, label %27, label %31

27:                                               ; preds = %25
  %28 = tail call double @llvm.experimental.constrained.sitofp.f64.i32(i32 0, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  br label %31

29:                                               ; preds = %1
  %30 = icmp ugt i64 %3, 9218868437227405311
  br i1 %30, label %90, label %31

31:                                               ; preds = %29, %27, %25
  %32 = phi double [ %28, %27 ], [ undef, %25 ], [ undef, %29 ]
  %33 = phi i1 [ true, %27 ], [ false, %25 ], [ false, %29 ]
  br i1 %33, label %65, label %34

34:                                               ; preds = %31
  %35 = tail call double @llvm.experimental.constrained.sitofp.f64.i32(i32 1, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %36 = tail call double @llvm.experimental.constrained.fadd.f64(double %35, double %0, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %37 = bitcast double %36 to i64
  %38 = lshr i64 %37, 32
  %39 = trunc nuw i64 %38 to i32
  %40 = add i32 %39, 614242
  %41 = lshr i32 %40, 20
  %42 = add nsw i32 %41, -1023
  %43 = icmp ult i32 %40, 1129316352
  br i1 %43, label %44, label %52

44:                                               ; preds = %34
  %45 = icmp ugt i32 %40, 1074790399
  %46 = tail call double @llvm.experimental.constrained.sitofp.f64.i32(i32 1, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %47 = select i1 %45, double %0, double %46
  %48 = select i1 %45, double %46, double %0
  %49 = tail call double @llvm.experimental.constrained.fsub.f64(double %36, double %47, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %50 = tail call double @llvm.experimental.constrained.fsub.f64(double %48, double %49, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %51 = tail call double @llvm.experimental.constrained.fdiv.f64(double %50, double %36, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  br label %54

52:                                               ; preds = %34
  %53 = tail call double @llvm.experimental.constrained.sitofp.f64.i32(i32 0, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  br label %54

54:                                               ; preds = %52, %44
  %55 = phi double [ %51, %44 ], [ %53, %52 ]
  %56 = and i32 %40, 1048575
  %57 = add nuw nsw i32 %56, 1072079006
  %58 = zext nneg i32 %57 to i64
  %59 = shl nuw nsw i64 %58, 32
  %60 = and i64 %37, 4294967295
  %61 = or disjoint i64 %59, %60
  %62 = bitcast i64 %61 to double
  %63 = tail call double @llvm.experimental.constrained.sitofp.f64.i32(i32 1, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %64 = tail call double @llvm.experimental.constrained.fsub.f64(double %62, double %63, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  br label %65

65:                                               ; preds = %54, %31
  %66 = phi double [ %55, %54 ], [ %32, %31 ]
  %67 = phi double [ %64, %54 ], [ %0, %31 ]
  %68 = phi i32 [ %42, %54 ], [ 0, %31 ]
  %69 = tail call double @llvm.experimental.constrained.fmul.f64(double 5.000000e-01, double %67, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %70 = tail call double @llvm.experimental.constrained.fmul.f64(double %69, double %67, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %71 = tail call double @llvm.experimental.constrained.fadd.f64(double 2.000000e+00, double %67, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %72 = tail call double @llvm.experimental.constrained.fdiv.f64(double %67, double %71, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %73 = tail call double @llvm.experimental.constrained.fmul.f64(double %72, double %72, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %74 = tail call double @llvm.experimental.constrained.fmul.f64(double %73, double %73, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %75 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %74, double 0x3FC39A09D078C69F, double 0x3FCC71C51D8E78AF, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %76 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %74, double %75, double 0x3FD999999997FA04, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %77 = tail call double @llvm.experimental.constrained.fmul.f64(double %74, double %76, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %78 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %74, double 0x3FC2F112DF3E5244, double 0x3FC7466496CB03DE, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %79 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %74, double %78, double 0x3FD2492494229359, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %80 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %74, double %79, double 0x3FE5555555555593, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %81 = tail call double @llvm.experimental.constrained.fmul.f64(double %73, double %80, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %82 = tail call double @llvm.experimental.constrained.fadd.f64(double %81, double %77, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %83 = tail call double @llvm.experimental.constrained.sitofp.f64.i32(i32 %68, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %84 = tail call double @llvm.experimental.constrained.fadd.f64(double %70, double %82, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %85 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %83, double 0x3DEA39EF35793C76, double %66, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %86 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %72, double %84, double %85, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %87 = tail call double @llvm.experimental.constrained.fsub.f64(double %86, double %70, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %88 = tail call double @llvm.experimental.constrained.fadd.f64(double %87, double %67, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %89 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %83, double 0x3FE62E42FEE00000, double %88, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  br label %90

90:                                               ; preds = %65, %29, %23, %20, %14, %12
  %91 = phi double [ %13, %12 ], [ %16, %14 ], [ %89, %65 ], [ %0, %23 ], [ %0, %20 ], [ %0, %29 ]
  ret double %91
}

; Function Attrs: nounwind ssp strictfp
define double @log(double noundef %0) local_unnamed_addr #7 {
  %2 = bitcast double %0 to i64
  %3 = lshr i64 %2, 48
  %4 = trunc nuw nsw i64 %3 to i32
  %5 = add i64 %2, -4606619468846596096
  %6 = icmp ult i64 %5, 854320534781952
  br i1 %6, label %7, label %50, !prof !7

7:                                                ; preds = %1
  %8 = icmp eq i64 %2, 4607182418800017408
  br i1 %8, label %9, label %11, !prof !7

9:                                                ; preds = %7
  %10 = tail call double @llvm.experimental.constrained.sitofp.f64.i32(i32 0, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  br label %114

11:                                               ; preds = %7
  %12 = tail call double @llvm.experimental.constrained.fsub.f64(double %0, double 1.000000e+00, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %13 = tail call double @llvm.experimental.constrained.fmul.f64(double %12, double %12, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %14 = tail call double @llvm.experimental.constrained.fmul.f64(double %12, double %13, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %15 = load double, ptr getelementptr inbounds (i8, ptr @__log_data, i64 64), align 8
  %16 = load double, ptr getelementptr inbounds (i8, ptr @__log_data, i64 72), align 8
  %17 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %12, double %16, double %15, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %18 = load double, ptr getelementptr inbounds (i8, ptr @__log_data, i64 80), align 8
  %19 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %13, double %18, double %17, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %20 = load double, ptr getelementptr inbounds (i8, ptr @__log_data, i64 88), align 8
  %21 = load double, ptr getelementptr inbounds (i8, ptr @__log_data, i64 96), align 8
  %22 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %12, double %21, double %20, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %23 = load double, ptr getelementptr inbounds (i8, ptr @__log_data, i64 104), align 8
  %24 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %13, double %23, double %22, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %25 = load double, ptr getelementptr inbounds (i8, ptr @__log_data, i64 112), align 8
  %26 = load double, ptr getelementptr inbounds (i8, ptr @__log_data, i64 120), align 8
  %27 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %12, double %26, double %25, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %28 = load double, ptr getelementptr inbounds (i8, ptr @__log_data, i64 128), align 8
  %29 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %13, double %28, double %27, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %30 = load double, ptr getelementptr inbounds (i8, ptr @__log_data, i64 136), align 8
  %31 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %14, double %30, double %29, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %32 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %14, double %31, double %24, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %33 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %14, double %32, double %19, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %34 = tail call double @llvm.experimental.constrained.fmul.f64(double %14, double %33, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %35 = tail call double @llvm.experimental.constrained.fmul.f64(double %12, double 0x41A0000000000000, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %36 = tail call double @llvm.experimental.constrained.fadd.f64(double %12, double %35, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %37 = tail call double @llvm.experimental.constrained.fsub.f64(double %36, double %35, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %38 = tail call double @llvm.experimental.constrained.fsub.f64(double %12, double %37, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %39 = tail call double @llvm.experimental.constrained.fmul.f64(double %37, double %37, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %40 = load double, ptr getelementptr inbounds (i8, ptr @__log_data, i64 56), align 8
  %41 = tail call double @llvm.experimental.constrained.fmul.f64(double %39, double %40, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %42 = tail call double @llvm.experimental.constrained.fadd.f64(double %12, double %41, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %43 = tail call double @llvm.experimental.constrained.fsub.f64(double %12, double %42, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %44 = tail call double @llvm.experimental.constrained.fadd.f64(double %43, double %41, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %45 = tail call double @llvm.experimental.constrained.fmul.f64(double %40, double %38, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %46 = tail call double @llvm.experimental.constrained.fadd.f64(double %37, double %12, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %47 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %45, double %46, double %44, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %48 = tail call double @llvm.experimental.constrained.fadd.f64(double %34, double %47, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %49 = tail call double @llvm.experimental.constrained.fadd.f64(double %48, double %42, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  br label %114

50:                                               ; preds = %1
  %51 = add nsw i32 %4, -32752
  %52 = icmp ult i32 %51, -32736
  br i1 %52, label %53, label %72, !prof !7

53:                                               ; preds = %50
  %54 = tail call i1 @llvm.is.fpclass.f64(double %0, i32 96)
  br i1 %54, label %55, label %57

55:                                               ; preds = %53
  %56 = tail call double @__math_divzero(i32 noundef 1) #12
  br label %114

57:                                               ; preds = %53
  %58 = tail call double @llvm.experimental.constrained.fpext.f64.f32(float 0x7FF0000000000000, metadata !"fpexcept.ignore") #11
  %59 = bitcast double %58 to i64
  %60 = icmp eq i64 %2, %59
  br i1 %60, label %114, label %61

61:                                               ; preds = %57
  %62 = icmp slt i64 %2, 0
  %63 = and i32 %4, 32752
  %64 = icmp eq i32 %63, 32752
  %65 = or i1 %62, %64
  br i1 %65, label %66, label %68

66:                                               ; preds = %61
  %67 = tail call double @__math_invalid(double noundef %0) #12
  br label %114

68:                                               ; preds = %61
  %69 = tail call double @llvm.experimental.constrained.fmul.f64(double %0, double 0x4330000000000000, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %70 = bitcast double %69 to i64
  %71 = add i64 %70, -234187180623265792
  br label %72

72:                                               ; preds = %68, %50
  %73 = phi i64 [ %71, %68 ], [ %2, %50 ]
  %74 = add i64 %73, -4604367669032910848
  %75 = lshr i64 %74, 45
  %76 = and i64 %75, 127
  %77 = ashr i64 %74, 52
  %78 = trunc nsw i64 %77 to i32
  %79 = and i64 %74, -4503599627370496
  %80 = sub i64 %73, %79
  %81 = getelementptr inbounds [128 x %struct.anon], ptr getelementptr inbounds (i8, ptr @__log_data, i64 144), i64 0, i64 %76
  %82 = load double, ptr %81, align 8
  %83 = getelementptr inbounds i8, ptr %81, i64 8
  %84 = load double, ptr %83, align 8
  %85 = bitcast i64 %80 to double
  %86 = getelementptr inbounds [128 x %struct.anon], ptr getelementptr inbounds (i8, ptr @__log_data, i64 2192), i64 0, i64 %76
  %87 = load double, ptr %86, align 8
  %88 = tail call double @llvm.experimental.constrained.fsub.f64(double %85, double %87, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %89 = getelementptr inbounds i8, ptr %86, i64 8
  %90 = load double, ptr %89, align 8
  %91 = tail call double @llvm.experimental.constrained.fsub.f64(double %88, double %90, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %92 = tail call double @llvm.experimental.constrained.fmul.f64(double %91, double %82, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %93 = tail call double @llvm.experimental.constrained.sitofp.f64.i32(i32 %78, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %94 = load double, ptr @__log_data, align 8
  %95 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %93, double %94, double %84, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %96 = tail call double @llvm.experimental.constrained.fadd.f64(double %95, double %92, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %97 = tail call double @llvm.experimental.constrained.fsub.f64(double %95, double %96, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %98 = tail call double @llvm.experimental.constrained.fadd.f64(double %97, double %92, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %99 = load double, ptr getelementptr inbounds (i8, ptr @__log_data, i64 8), align 8
  %100 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %93, double %99, double %98, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %101 = tail call double @llvm.experimental.constrained.fmul.f64(double %92, double %92, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %102 = load double, ptr getelementptr inbounds (i8, ptr @__log_data, i64 16), align 8
  %103 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %101, double %102, double %100, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %104 = tail call double @llvm.experimental.constrained.fmul.f64(double %92, double %101, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %105 = load double, ptr getelementptr inbounds (i8, ptr @__log_data, i64 24), align 8
  %106 = load double, ptr getelementptr inbounds (i8, ptr @__log_data, i64 32), align 8
  %107 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %92, double %106, double %105, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %108 = load double, ptr getelementptr inbounds (i8, ptr @__log_data, i64 40), align 8
  %109 = load double, ptr getelementptr inbounds (i8, ptr @__log_data, i64 48), align 8
  %110 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %92, double %109, double %108, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %111 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %101, double %110, double %107, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %112 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %104, double %111, double %103, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %113 = tail call double @llvm.experimental.constrained.fadd.f64(double %112, double %96, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  br label %114

114:                                              ; preds = %72, %66, %57, %55, %11, %9
  %115 = phi double [ %10, %9 ], [ %49, %11 ], [ %56, %55 ], [ %67, %66 ], [ %113, %72 ], [ %0, %57 ]
  ret double %115
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite) }
attributes #3 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #4 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #5 = { nofree norecurse nounwind ssp strictfp memory(inaccessiblemem: readwrite) "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #6 = { mustprogress nofree norecurse nosync nounwind ssp strictfp willreturn memory(inaccessiblemem: readwrite) "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #7 = { nounwind ssp strictfp "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #8 = { nomerge nounwind }
attributes #9 = { nounwind willreturn memory(none) }
attributes #10 = { nounwind }
attributes #11 = { strictfp }
attributes #12 = { nobuiltin nounwind strictfp "no-builtins" }

!llvm.ident = !{!0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5, !6}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = !{i32 7, !"PIE Level", i32 2}
!7 = !{!"branch_weights", !"expected", i32 1, i32 2000}
