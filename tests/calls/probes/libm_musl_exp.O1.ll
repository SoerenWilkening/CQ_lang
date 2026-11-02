; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.exp_data = type { double, double, double, double, [4 x double], double, [5 x double], [256 x i64] }

@__exp_data = hidden local_unnamed_addr constant %struct.exp_data { double 0x40671547652B82FE, double 0x4338000000000000, double 0xBF762E42FEFA0000, double 0xBD0CF79ABC9E3B3A, [4 x double] [double 0x3FDFFFFFFFFFFDBD, double 0x3FC555555555543C, double 0x3FA55555CF172B91, double 0x3F81111167A4D017], double 0x42C8000000000000, [5 x double] [double 0x3FE62E42FEFA39EF, double 0x3FCEBFBDFF82C424, double 0x3FAC6B08D70CF4B5, double 0x3F83B2ABD24650CC, double 0x3F55D7E09B4E3A84], [256 x i64] [i64 0, i64 4607182418800017408, i64 4367149474599452526, i64 4607171688528556853, i64 -4868004084858692515, i64 4607161091040444513, i64 -4859280119576434991, i64 4607150627056680837, i64 4363093389540324883, i64 4607140297302181236, i64 -4860564323061625094, i64 4607130102505797342, i64 4350749156061923425, i64 4607120043400338376, i64 4364168240100004761, i64 4607110120722592643, i64 4366128403083131757, i64 4607100335213349135, i64 4363624214708482044, i64 4607090687617419255, i64 4341116261916187857, i64 4607081178683658658, i64 -4870076522866643445, i64 4607071809164989211, i64 -4857881712154133234, i64 4607062579818421073, i64 -4877256630102726059, i64 4607053491405074892, i64 -4858881367677209578, i64 4607044544690204128, i64 4359717415120819631, i64 4607035740443217489, i64 -4863857816615152824, i64 4607027079437701499, i64 -4859630355816238531, i64 4607018562451443178, i64 4362731899485115327, i64 4607010190266452853, i64 -4857455882053489882, i64 4607001963668987092, i64 4367063335334195040, i64 4606993883449571754, i64 -4859410923963139939, i64 4606985950403025181, i64 4362421515177083789, i64 4606978165328481494, i64 4359618604155798653, i64 4606970529029414038, i64 4365834109879625876, i64 4606963042313658936, i64 4361558225371547773, i64 4606955705993438783, i64 4359562691856033778, i64 4606948520885386461, i64 -4857492308587640738, i64 4606941487810569089, i64 4360319936817113905, i64 4606934607594512097, i64 -4882709470952570886, i64 4606927881067223440, i64 4362641697437125300, i64 4606921309063217931, i64 4354440509323660175, i64 4606914892421541718, i64 4360414030434708406, i64 4606908631985796885, i64 4361245865020257356, i64 4606902528604166193, i64 4363949802402347082, i64 4606896583129437951, i64 -4862018976549545212, i64 4606890796419031025, i64 -4858738662784151448, i64 4606885169335019979, i64 -4856841960950780530, i64 4606879702744160358, i64 -4867878926798276910, i64 4606874397517914103, i64 -4856823124960863467, i64 4606869254532475109, i64 4361066948569222253, i64 4606864274668794914, i64 -4858519367427004022, i64 4606859458812608540, i64 -4874962362796897957, i64 4606854807854460458, i64 -4864964451502548453, i64 4606850322689730711, i64 4342424336897059857, i64 4606846004218661165, i64 4365789078613288175, i64 4606841853346381911, i64 4354643160121541497, i64 4606837870982937808, i64 4365113450260533808, i64 4606834058043315166, i64 4356828907110576048, i64 4606830415447468583, i64 4364865165386375287, i64 4606826944120347917, i64 -4859502521842818162, i64 4606823644991925415, i64 -4861672301267803319, i64 4606820518997222978, i64 -4865894452217038753, i64 4606817567076339586, i64 -4862178651875353354, i64 4606814790174478863, i64 4364890759862540174, i64 4606812189241976794, i64 4358244976955136773, i64 4606809765234329597, i64 4364097860734309385, i64 4606807519112221737, i64 4338311716453074666, i64 4606805451841554103, i64 4365169902980743221, i64 4606803564393472328, i64 -4860258889723447649, i64 4606801857744395273, i64 -4860452975632495192, i64 4606800332876043653, i64 -4862669920490755666, i64 4606798990775468832, i64 -4858312122400614312, i64 4606797832435081765, i64 4347962289735735652, i64 4606796858852682099, i64 -4858341730713460184, i64 4606796071031487437, i64 -4870059510540748414, i64 4606795469980162751, i64 -4871936092595705362, i64 4606795056712849967, i64 -4863645441585018799, i64 4606794832249197700, i64 -4866104880896786737, i64 4606794797614391156, i64 -4861936742874514000, i64 4606794953839182196, i64 -4862171044651866486, i64 4606795301959919561, i64 4364160436192007379, i64 4606795843018579263, i64 -4865239048860621539, i64 4606796578062795143, i64 4365374511615819883, i64 4606797508145889586, i64 4352143969406577749, i64 4606798634326904418, i64 -4861457929465508030, i64 4606799957670631954, i64 -4858423338550479052, i64 4606801479247646227, i64 -4863783675556659426, i64 4606803200134334381, i64 -4858024654332078226, i64 4606805121412928237, i64 4364178698342926848, i64 4606807244171536025, i64 4363345029737015988, i64 4606809569504174299, i64 -4871286895867992065, i64 4606812098510800012, i64 4358348108421357380, i64 4606814832297342774, i64 -4858529541450220157, i64 4606817771975737286, i64 -4873552611666813399, i64 4606820918663955941, i64 -4869477542650660519, i64 4606824273486041615, i64 -4858747092350994006, i64 4606827837572140624, i64 -4862257653857481141, i64 4606831612058535866, i64 4355455812241575463, i64 4606835598087680144, i64 4354367543587795899, i64 4606839796808229667, i64 -4861700651175763357, i64 4606844209375077733, i64 4362612029712904661, i64 4606848836949388595, i64 -4858896013081134315, i64 4606853680698631517, i64 4364212552380330450, i64 4606858741796615000, i64 4360726356711135923, i64 4606864021423521215, i64 -4863078573502718540, i64 4606869520765940602, i64 4362891239881388935, i64 4606875241016906669, i64 -4859248142566958598, i64 4606881183375930982, i64 -4875775683326071110, i64 4606887349049038331, i64 -4859203616861915584, i64 4606893739248802106, i64 -4870406652589927628, i64 4606900355194379847, i64 -4858839866725070283, i64 4606907198111549002, i64 4356388038631218637, i64 4606914269232742866, i64 -4858893633017702228, i64 4606921569797086729, i64 4355946959017544883, i64 4606929101050434204, i64 4363674894410448276, i64 4606936864245403770, i64 4360857247493478828, i64 4606944860641415499, i64 4351547817417644647, i64 4606953091504727989, i64 4352565403421120872, i64 4606961558108475497, i64 -4863735759665056302, i64 4606970261732705274, i64 -4859474856892171665, i64 4606979203664415100, i64 -4859368956010059447, i64 4606988385197591026, i64 4356286533989107623, i64 4606997807633245319, i64 -4863164539274780145, i64 4607007472279454616, i64 4363524392198705836, i64 4607017380451398277, i64 4360674496013757259, i64 4607027533471396960, i64 -4863090309766824417, i64 4607037932668951391, i64 -4861307347717911095, i64 4607048579380781353, i64 4356306869484685523, i64 4607059474950864886, i64 4360546482996998769, i64 4607070620730477699, i64 -4859393813814996496, i64 4607082018078232794, i64 -4860036451210660739, i64 4607093668360120305, i64 4363640302291525640, i64 4607105572949547559, i64 4360658257139329842, i64 4607117733227379351, i64 4362409866909812206, i64 4607130150581978432, i64 -4859885672053611539, i64 4607142826409246228, i64 4357102052301720989, i64 4607155762112663768, i64 4346824392926350473, i64 4607168959103332849] }, align 8

; Function Attrs: nounwind ssp uwtable
define double @f_exp(double noundef %0) local_unnamed_addr #0 {
  %2 = tail call double @cq_theta_f64(double noundef %0, double noundef 3.000000e-01) #10
  %3 = tail call double @llvm.exp.f64(double %2)
  %4 = tail call double @cq_measure_f64(double noundef %3) #11
  ret double %4
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.exp.f64(double) #2

declare double @cq_measure_f64(double noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp strictfp
define double @exp(double noundef %0) local_unnamed_addr #3 {
  %2 = bitcast double %0 to i64
  %3 = lshr i64 %2, 52
  %4 = trunc nuw nsw i64 %3 to i32
  %5 = and i32 %4, 2047
  %6 = add nsw i32 %5, -969
  %7 = icmp ult i32 %6, 63
  br i1 %7, label %32, label %8, !prof !6

8:                                                ; preds = %1
  %9 = icmp ult i32 %5, 969
  br i1 %9, label %10, label %12

10:                                               ; preds = %8
  %11 = tail call double @llvm.experimental.constrained.fadd.f64(double 1.000000e+00, double %0, metadata !"round.dynamic", metadata !"fpexcept.ignore") #12
  br label %70

12:                                               ; preds = %8
  %13 = icmp ult i32 %5, 1033
  br i1 %13, label %32, label %14

14:                                               ; preds = %12
  %15 = tail call double @llvm.experimental.constrained.fpext.f64.f32(float 0xFFF0000000000000, metadata !"fpexcept.ignore") #12
  %16 = bitcast double %15 to i64
  %17 = icmp eq i64 %2, %16
  br i1 %17, label %70, label %18

18:                                               ; preds = %14
  %19 = tail call double @llvm.experimental.constrained.fpext.f64.f32(float 0x7FF0000000000000, metadata !"fpexcept.ignore") #12
  %20 = bitcast double %19 to i64
  %21 = lshr i64 %20, 52
  %22 = trunc nuw nsw i64 %21 to i32
  %23 = icmp ult i32 %5, %22
  br i1 %23, label %26, label %24

24:                                               ; preds = %18
  %25 = tail call double @llvm.experimental.constrained.fadd.f64(double 1.000000e+00, double %0, metadata !"round.dynamic", metadata !"fpexcept.ignore") #12
  br label %70

26:                                               ; preds = %18
  %27 = icmp sgt i64 %2, -1
  br i1 %27, label %30, label %28

28:                                               ; preds = %26
  %29 = tail call double @__math_uflow(i32 noundef 0) #13
  br label %70

30:                                               ; preds = %26
  %31 = tail call double @__math_oflow(i32 noundef 0) #13
  br label %70

32:                                               ; preds = %12, %1
  %33 = phi i32 [ %5, %1 ], [ 0, %12 ]
  %34 = load double, ptr @__exp_data, align 8
  %35 = tail call double @llvm.experimental.constrained.fmul.f64(double %34, double %0, metadata !"round.dynamic", metadata !"fpexcept.ignore") #12
  %36 = load double, ptr getelementptr inbounds (i8, ptr @__exp_data, i64 8), align 8
  %37 = tail call double @llvm.experimental.constrained.fadd.f64(double %35, double %36, metadata !"round.dynamic", metadata !"fpexcept.ignore") #12
  %38 = bitcast double %37 to i64
  %39 = tail call double @llvm.experimental.constrained.fsub.f64(double %37, double %36, metadata !"round.dynamic", metadata !"fpexcept.ignore") #12
  %40 = load double, ptr getelementptr inbounds (i8, ptr @__exp_data, i64 16), align 8
  %41 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %39, double %40, double %0, metadata !"round.dynamic", metadata !"fpexcept.ignore") #12
  %42 = load double, ptr getelementptr inbounds (i8, ptr @__exp_data, i64 24), align 8
  %43 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %39, double %42, double %41, metadata !"round.dynamic", metadata !"fpexcept.ignore") #12
  %44 = shl i64 %38, 1
  %45 = and i64 %44, 254
  %46 = shl i64 %38, 45
  %47 = getelementptr inbounds [256 x i64], ptr getelementptr inbounds (i8, ptr @__exp_data, i64 112), i64 0, i64 %45
  %48 = load double, ptr %47, align 8
  %49 = or disjoint i64 %45, 1
  %50 = getelementptr inbounds [256 x i64], ptr getelementptr inbounds (i8, ptr @__exp_data, i64 112), i64 0, i64 %49
  %51 = load i64, ptr %50, align 8
  %52 = add i64 %51, %46
  %53 = tail call double @llvm.experimental.constrained.fmul.f64(double %43, double %43, metadata !"round.dynamic", metadata !"fpexcept.ignore") #12
  %54 = tail call double @llvm.experimental.constrained.fadd.f64(double %48, double %43, metadata !"round.dynamic", metadata !"fpexcept.ignore") #12
  %55 = load double, ptr getelementptr inbounds (i8, ptr @__exp_data, i64 32), align 8
  %56 = load double, ptr getelementptr inbounds (i8, ptr @__exp_data, i64 40), align 8
  %57 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %43, double %56, double %55, metadata !"round.dynamic", metadata !"fpexcept.ignore") #12
  %58 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %53, double %57, double %54, metadata !"round.dynamic", metadata !"fpexcept.ignore") #12
  %59 = tail call double @llvm.experimental.constrained.fmul.f64(double %53, double %53, metadata !"round.dynamic", metadata !"fpexcept.ignore") #12
  %60 = load double, ptr getelementptr inbounds (i8, ptr @__exp_data, i64 48), align 8
  %61 = load double, ptr getelementptr inbounds (i8, ptr @__exp_data, i64 56), align 8
  %62 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %43, double %61, double %60, metadata !"round.dynamic", metadata !"fpexcept.ignore") #12
  %63 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %59, double %62, double %58, metadata !"round.dynamic", metadata !"fpexcept.ignore") #12
  %64 = icmp eq i32 %33, 0
  br i1 %64, label %65, label %67, !prof !7

65:                                               ; preds = %32
  %66 = tail call fastcc double @specialcase(double noundef %63, i64 noundef %52, i64 noundef %38) #14
  br label %70

67:                                               ; preds = %32
  %68 = bitcast i64 %52 to double
  %69 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %68, double %63, double %68, metadata !"round.dynamic", metadata !"fpexcept.ignore") #12
  br label %70

70:                                               ; preds = %67, %65, %30, %28, %24, %14, %10
  %71 = phi double [ %11, %10 ], [ %25, %24 ], [ %29, %28 ], [ %31, %30 ], [ %66, %65 ], [ %69, %67 ], [ 0.000000e+00, %14 ]
  ret double %71
}

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fadd.f64(double, double, metadata, metadata) #4

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fpext.f64.f32(float, metadata) #4

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fmul.f64(double, double, metadata, metadata) #4

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fsub.f64(double, double, metadata, metadata) #4

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fmuladd.f64(double, double, double, metadata, metadata) #4

; Function Attrs: inlinehint nofree norecurse nounwind ssp strictfp memory(inaccessiblemem: readwrite)
define internal fastcc double @specialcase(double noundef %0, i64 noundef %1, i64 noundef %2) unnamed_addr #5 {
  %4 = alloca double, align 8
  %5 = alloca double, align 8
  %6 = and i64 %2, 2147483648
  %7 = icmp eq i64 %6, 0
  br i1 %7, label %8, label %13

8:                                                ; preds = %3
  %9 = add i64 %1, -4544132024016830464
  %10 = bitcast i64 %9 to double
  %11 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %10, double %0, double %10, metadata !"round.dynamic", metadata !"fpexcept.ignore") #12
  %12 = tail call double @llvm.experimental.constrained.fmul.f64(double 0x7F00000000000000, double %11, metadata !"round.dynamic", metadata !"fpexcept.ignore") #12
  br label %34

13:                                               ; preds = %3
  %14 = add i64 %1, 4602678819172646912
  %15 = bitcast i64 %14 to double
  %16 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %15, double %0, double %15, metadata !"round.dynamic", metadata !"fpexcept.ignore") #12
  %17 = tail call i1 @llvm.experimental.constrained.fcmps.f64(double %16, double 1.000000e+00, metadata !"olt", metadata !"fpexcept.ignore") #12
  br i1 %17, label %18, label %31

18:                                               ; preds = %13
  %19 = tail call double @llvm.experimental.constrained.fsub.f64(double %15, double %16, metadata !"round.dynamic", metadata !"fpexcept.ignore") #12
  %20 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %15, double %0, double %19, metadata !"round.dynamic", metadata !"fpexcept.ignore") #12
  %21 = tail call double @llvm.experimental.constrained.fadd.f64(double 1.000000e+00, double %16, metadata !"round.dynamic", metadata !"fpexcept.ignore") #12
  %22 = tail call double @llvm.experimental.constrained.fsub.f64(double 1.000000e+00, double %21, metadata !"round.dynamic", metadata !"fpexcept.ignore") #12
  %23 = tail call double @llvm.experimental.constrained.fadd.f64(double %22, double %16, metadata !"round.dynamic", metadata !"fpexcept.ignore") #12
  %24 = tail call double @llvm.experimental.constrained.fadd.f64(double %23, double %20, metadata !"round.dynamic", metadata !"fpexcept.ignore") #12
  %25 = tail call double @llvm.experimental.constrained.fadd.f64(double %21, double %24, metadata !"round.dynamic", metadata !"fpexcept.ignore") #12
  %26 = tail call double @llvm.experimental.constrained.fsub.f64(double %25, double 1.000000e+00, metadata !"round.dynamic", metadata !"fpexcept.ignore") #12
  %27 = tail call i1 @llvm.experimental.constrained.fcmp.f64(double %26, double 0.000000e+00, metadata !"oeq", metadata !"fpexcept.ignore") #12
  %28 = select i1 %27, double 0.000000e+00, double %26
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %5)
  store volatile double 0x10000000000000, ptr %5, align 8
  %29 = load volatile double, ptr %5, align 8
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %5)
  %30 = tail call double @llvm.experimental.constrained.fmul.f64(double %29, double 0x10000000000000, metadata !"round.dynamic", metadata !"fpexcept.ignore") #12
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %4)
  store volatile double %30, ptr %4, align 8
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %4)
  br label %31

31:                                               ; preds = %18, %13
  %32 = phi double [ %28, %18 ], [ %16, %13 ]
  %33 = tail call double @llvm.experimental.constrained.fmul.f64(double 0x10000000000000, double %32, metadata !"round.dynamic", metadata !"fpexcept.ignore") #12
  br label %34

34:                                               ; preds = %31, %8
  %35 = phi double [ %12, %8 ], [ %33, %31 ]
  ret double %35
}

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare i1 @llvm.experimental.constrained.fcmps.f64(double, double, metadata, metadata) #4

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare i1 @llvm.experimental.constrained.fcmp.f64(double, double, metadata, metadata) #4

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #6

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #6

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp strictfp willreturn memory(none)
define noundef double @fabs(double noundef %0) local_unnamed_addr #7 {
  %2 = tail call double @llvm.fabs.f64(double %0)
  ret double %2
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fabs.f64(double) #2

; Function Attrs: nounwind ssp strictfp
define hidden double @__math_oflow(i32 noundef %0) local_unnamed_addr #3 {
  %2 = tail call double @__math_xflow(i32 noundef %0, double noundef 0x7000000000000000) #13
  ret double %2
}

; Function Attrs: nounwind ssp strictfp
define hidden double @__math_uflow(i32 noundef %0) local_unnamed_addr #3 {
  %2 = tail call double @__math_xflow(i32 noundef %0, double noundef 0x1000000000000000) #13
  ret double %2
}

; Function Attrs: nofree norecurse nounwind ssp strictfp memory(inaccessiblemem: readwrite)
define hidden double @__math_xflow(i32 noundef %0, double noundef %1) local_unnamed_addr #8 {
  %3 = alloca double, align 8
  %4 = icmp eq i32 %0, 0
  %5 = fneg double %1
  %6 = select i1 %4, double %1, double %5
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %3)
  store volatile double %6, ptr %3, align 8
  %7 = load volatile double, ptr %3, align 8
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %3)
  %8 = tail call double @llvm.experimental.constrained.fmul.f64(double %7, double %1, metadata !"round.dynamic", metadata !"fpexcept.ignore") #12
  ret double %8
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp strictfp willreturn memory(inaccessiblemem: readwrite)
define hidden double @__math_invalid(double noundef %0) local_unnamed_addr #9 {
  %2 = tail call double @llvm.experimental.constrained.fsub.f64(double %0, double %0, metadata !"round.dynamic", metadata !"fpexcept.ignore") #12
  %3 = tail call double @llvm.experimental.constrained.fsub.f64(double %0, double %0, metadata !"round.dynamic", metadata !"fpexcept.ignore") #12
  %4 = tail call double @llvm.experimental.constrained.fdiv.f64(double %2, double %3, metadata !"round.dynamic", metadata !"fpexcept.ignore") #12
  ret double %4
}

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fdiv.f64(double, double, metadata, metadata) #4

; Function Attrs: nofree norecurse nounwind ssp strictfp memory(inaccessiblemem: readwrite)
define hidden double @__math_divzero(i32 noundef %0) local_unnamed_addr #8 {
  %2 = alloca double, align 8
  %3 = icmp eq i32 %0, 0
  %4 = select i1 %3, double 1.000000e+00, double -1.000000e+00
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %2)
  store volatile double %4, ptr %2, align 8
  %5 = load volatile double, ptr %2, align 8
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %2)
  %6 = tail call double @llvm.experimental.constrained.fdiv.f64(double %5, double 0.000000e+00, metadata !"round.dynamic", metadata !"fpexcept.ignore") #12
  ret double %6
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #3 = { nounwind ssp strictfp "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite) }
attributes #5 = { inlinehint nofree norecurse nounwind ssp strictfp memory(inaccessiblemem: readwrite) "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #6 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #7 = { mustprogress nofree norecurse nosync nounwind ssp strictfp willreturn memory(none) "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #8 = { nofree norecurse nounwind ssp strictfp memory(inaccessiblemem: readwrite) "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #9 = { mustprogress nofree norecurse nosync nounwind ssp strictfp willreturn memory(inaccessiblemem: readwrite) "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #10 = { nomerge nounwind }
attributes #11 = { nounwind }
attributes #12 = { strictfp }
attributes #13 = { nobuiltin nounwind strictfp "no-builtins" }
attributes #14 = { nobuiltin strictfp "no-builtins" }

!llvm.ident = !{!0, !0, !0, !0, !0, !0, !0, !0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = !{!"branch_weights", !"expected", i32 2000, i32 1}
!7 = !{!"branch_weights", !"expected", i32 1, i32 2000}
