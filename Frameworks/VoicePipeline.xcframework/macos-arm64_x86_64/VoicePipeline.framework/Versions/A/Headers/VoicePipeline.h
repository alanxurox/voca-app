#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSError.h>
#import <Foundation/NSObject.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSString.h>
#import <Foundation/NSValue.h>

@class VoicePipelineKotlinFloatArray, VoicePipelineKotlinEnumCompanion, VoicePipelineKotlinEnum<E>, VoicePipelineBackend, VoicePipelineKotlinArray<T>, VoicePipelineFilePipeline, VoicePipelineTranscriptionResult, VoicePipelineCoreMLModel, VoicePipelineSegment, VoicePipelineASRModelType, VoicePipelineCTCDecoder, VoicePipelineLFRTransform, VoicePipelineSpeakerProfileCompanion, VoicePipelineSpeakerProfile, VoicePipelineTokenMappings, VoicePipelineKotlinPair<__covariant A, __covariant B>, VoicePipelineASRResult, VoicePipelineAudioFileReader, VoicePipelineAudioProcessing, MLModel, VoicePipelineCoreMLModelCompanion, MLMultiArray, VoicePipelineVADOutput, VoicePipelineSpeakerData, VoicePipelineLibraryDataCompanion, VoicePipelineLibraryData, VoicePipelineMLArrayUtils, VoicePipelineONNXModelManagerCompanion, VoicePipelineONNXModelManagerVADOutput, VoicePipelineSpeakerDataCompanion, VoicePipelineTokenDecoder, VoicePipelineKotlinTriple<__covariant A, __covariant B, __covariant C>, VoicePipelineWhisperASRCompanion, VoicePipelineWhisperASR, VoicePipelineWhisperConfigCompanion, VoicePipelineWhisperConfig, VoicePipelineWhisperTokenizerCompanion, VoicePipelineWhisperTokenizer, VoicePipelineKotlinFloatIterator, VoicePipelineKotlinx_serialization_coreSerializersModule, VoicePipelineKotlinx_serialization_coreSerialKind, VoicePipelineKotlinNothing;

@protocol VoicePipelineKotlinComparable, VoicePipelineASRModel, VoicePipelineKotlinx_serialization_coreKSerializer, VoicePipelineKotlinIterator, VoicePipelineKotlinx_serialization_coreEncoder, VoicePipelineKotlinx_serialization_coreSerialDescriptor, VoicePipelineKotlinx_serialization_coreSerializationStrategy, VoicePipelineKotlinx_serialization_coreDecoder, VoicePipelineKotlinx_serialization_coreDeserializationStrategy, VoicePipelineKotlinx_serialization_coreCompositeEncoder, VoicePipelineKotlinAnnotation, VoicePipelineKotlinx_serialization_coreCompositeDecoder, VoicePipelineKotlinx_serialization_coreSerializersModuleCollector, VoicePipelineKotlinKClass, VoicePipelineKotlinKDeclarationContainer, VoicePipelineKotlinKAnnotatedElement, VoicePipelineKotlinKClassifier;

NS_ASSUME_NONNULL_BEGIN
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunknown-warning-option"
#pragma clang diagnostic ignored "-Wincompatible-property-type"
#pragma clang diagnostic ignored "-Wnullability"

#pragma push_macro("_Nullable_result")
#if !__has_feature(nullability_nullable_result)
#undef _Nullable_result
#define _Nullable_result _Nullable
#endif

__attribute__((swift_name("KotlinBase")))
@interface VoicePipelineBase : NSObject
- (instancetype)init __attribute__((unavailable));
+ (instancetype)new __attribute__((unavailable));
+ (void)initialize __attribute__((objc_requires_super));
@end

@interface VoicePipelineBase (VoicePipelineBaseCopying) <NSCopying>
@end

__attribute__((swift_name("KotlinMutableSet")))
@interface VoicePipelineMutableSet<ObjectType> : NSMutableSet<ObjectType>
@end

__attribute__((swift_name("KotlinMutableDictionary")))
@interface VoicePipelineMutableDictionary<KeyType, ObjectType> : NSMutableDictionary<KeyType, ObjectType>
@end

@interface NSError (NSErrorVoicePipelineKotlinException)
@property (readonly) id _Nullable kotlinException;
@end

__attribute__((swift_name("KotlinNumber")))
@interface VoicePipelineNumber : NSNumber
- (instancetype)initWithChar:(char)value __attribute__((unavailable));
- (instancetype)initWithUnsignedChar:(unsigned char)value __attribute__((unavailable));
- (instancetype)initWithShort:(short)value __attribute__((unavailable));
- (instancetype)initWithUnsignedShort:(unsigned short)value __attribute__((unavailable));
- (instancetype)initWithInt:(int)value __attribute__((unavailable));
- (instancetype)initWithUnsignedInt:(unsigned int)value __attribute__((unavailable));
- (instancetype)initWithLong:(long)value __attribute__((unavailable));
- (instancetype)initWithUnsignedLong:(unsigned long)value __attribute__((unavailable));
- (instancetype)initWithLongLong:(long long)value __attribute__((unavailable));
- (instancetype)initWithUnsignedLongLong:(unsigned long long)value __attribute__((unavailable));
- (instancetype)initWithFloat:(float)value __attribute__((unavailable));
- (instancetype)initWithDouble:(double)value __attribute__((unavailable));
- (instancetype)initWithBool:(BOOL)value __attribute__((unavailable));
- (instancetype)initWithInteger:(NSInteger)value __attribute__((unavailable));
- (instancetype)initWithUnsignedInteger:(NSUInteger)value __attribute__((unavailable));
+ (instancetype)numberWithChar:(char)value __attribute__((unavailable));
+ (instancetype)numberWithUnsignedChar:(unsigned char)value __attribute__((unavailable));
+ (instancetype)numberWithShort:(short)value __attribute__((unavailable));
+ (instancetype)numberWithUnsignedShort:(unsigned short)value __attribute__((unavailable));
+ (instancetype)numberWithInt:(int)value __attribute__((unavailable));
+ (instancetype)numberWithUnsignedInt:(unsigned int)value __attribute__((unavailable));
+ (instancetype)numberWithLong:(long)value __attribute__((unavailable));
+ (instancetype)numberWithUnsignedLong:(unsigned long)value __attribute__((unavailable));
+ (instancetype)numberWithLongLong:(long long)value __attribute__((unavailable));
+ (instancetype)numberWithUnsignedLongLong:(unsigned long long)value __attribute__((unavailable));
+ (instancetype)numberWithFloat:(float)value __attribute__((unavailable));
+ (instancetype)numberWithDouble:(double)value __attribute__((unavailable));
+ (instancetype)numberWithBool:(BOOL)value __attribute__((unavailable));
+ (instancetype)numberWithInteger:(NSInteger)value __attribute__((unavailable));
+ (instancetype)numberWithUnsignedInteger:(NSUInteger)value __attribute__((unavailable));
@end

__attribute__((swift_name("KotlinByte")))
@interface VoicePipelineByte : VoicePipelineNumber
- (instancetype)initWithChar:(char)value;
+ (instancetype)numberWithChar:(char)value;
@end

__attribute__((swift_name("KotlinUByte")))
@interface VoicePipelineUByte : VoicePipelineNumber
- (instancetype)initWithUnsignedChar:(unsigned char)value;
+ (instancetype)numberWithUnsignedChar:(unsigned char)value;
@end

__attribute__((swift_name("KotlinShort")))
@interface VoicePipelineShort : VoicePipelineNumber
- (instancetype)initWithShort:(short)value;
+ (instancetype)numberWithShort:(short)value;
@end

__attribute__((swift_name("KotlinUShort")))
@interface VoicePipelineUShort : VoicePipelineNumber
- (instancetype)initWithUnsignedShort:(unsigned short)value;
+ (instancetype)numberWithUnsignedShort:(unsigned short)value;
@end

__attribute__((swift_name("KotlinInt")))
@interface VoicePipelineInt : VoicePipelineNumber
- (instancetype)initWithInt:(int)value;
+ (instancetype)numberWithInt:(int)value;
@end

__attribute__((swift_name("KotlinUInt")))
@interface VoicePipelineUInt : VoicePipelineNumber
- (instancetype)initWithUnsignedInt:(unsigned int)value;
+ (instancetype)numberWithUnsignedInt:(unsigned int)value;
@end

__attribute__((swift_name("KotlinLong")))
@interface VoicePipelineLong : VoicePipelineNumber
- (instancetype)initWithLongLong:(long long)value;
+ (instancetype)numberWithLongLong:(long long)value;
@end

__attribute__((swift_name("KotlinULong")))
@interface VoicePipelineULong : VoicePipelineNumber
- (instancetype)initWithUnsignedLongLong:(unsigned long long)value;
+ (instancetype)numberWithUnsignedLongLong:(unsigned long long)value;
@end

__attribute__((swift_name("KotlinFloat")))
@interface VoicePipelineFloat : VoicePipelineNumber
- (instancetype)initWithFloat:(float)value;
+ (instancetype)numberWithFloat:(float)value;
@end

__attribute__((swift_name("KotlinDouble")))
@interface VoicePipelineDouble : VoicePipelineNumber
- (instancetype)initWithDouble:(double)value;
+ (instancetype)numberWithDouble:(double)value;
@end

__attribute__((swift_name("KotlinBoolean")))
@interface VoicePipelineBoolean : VoicePipelineNumber
- (instancetype)initWithBool:(BOOL)value;
+ (instancetype)numberWithBool:(BOOL)value;
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ASREngine")))
@interface VoicePipelineASREngine : VoicePipelineBase
- (instancetype)initWithModelDir:(NSString *)modelDir assetsDir:(NSString *)assetsDir __attribute__((swift_name("init(modelDir:assetsDir:)"))) __attribute__((objc_designated_initializer));
- (NSString *)getAssetsDir __attribute__((swift_name("getAssetsDir()")));
- (NSString *)getModelDir __attribute__((swift_name("getModelDir()")));
- (BOOL)initialize __attribute__((swift_name("initialize()")));
- (BOOL)isReady __attribute__((swift_name("isReady()")));
- (NSString * _Nullable)transcribeAudio:(VoicePipelineKotlinFloatArray *)audio __attribute__((swift_name("transcribe(audio:)")));
@end

__attribute__((swift_name("KotlinComparable")))
@protocol VoicePipelineKotlinComparable
@required
- (int32_t)compareToOther:(id _Nullable)other __attribute__((swift_name("compareTo(other:)")));
@end

__attribute__((swift_name("KotlinEnum")))
@interface VoicePipelineKotlinEnum<E> : VoicePipelineBase <VoicePipelineKotlinComparable>
- (instancetype)initWithName:(NSString *)name ordinal:(int32_t)ordinal __attribute__((swift_name("init(name:ordinal:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) VoicePipelineKotlinEnumCompanion *companion __attribute__((swift_name("companion")));
- (int32_t)compareToOther:(E)other __attribute__((swift_name("compareTo(other:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSString *name __attribute__((swift_name("name")));
@property (readonly) int32_t ordinal __attribute__((swift_name("ordinal")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Backend")))
@interface VoicePipelineBackend : VoicePipelineKotlinEnum<VoicePipelineBackend *>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithName:(NSString *)name ordinal:(int32_t)ordinal __attribute__((swift_name("init(name:ordinal:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
@property (class, readonly) VoicePipelineBackend *coreml __attribute__((swift_name("coreml")));
@property (class, readonly) VoicePipelineBackend *onnx __attribute__((swift_name("onnx")));
+ (VoicePipelineKotlinArray<VoicePipelineBackend *> *)values __attribute__((swift_name("values()")));
@property (class, readonly) NSArray<VoicePipelineBackend *> *entries __attribute__((swift_name("entries")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("FilePipeline")))
@interface VoicePipelineFilePipeline : VoicePipelineBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)filePipeline __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) VoicePipelineFilePipeline *shared __attribute__((swift_name("shared")));
- (NSArray<VoicePipelineTranscriptionResult *> *)processFileAudioPath:(NSString *)audioPath vadModel:(VoicePipelineCoreMLModel *)vadModel asrModel:(id<VoicePipelineASRModel>)asrModel speakerModel:(VoicePipelineCoreMLModel *)speakerModel __attribute__((swift_name("processFile(audioPath:vadModel:asrModel:speakerModel:)")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("LivePipeline")))
@interface VoicePipelineLivePipeline : VoicePipelineBase
- (instancetype)initWithVadModel:(VoicePipelineCoreMLModel *)vadModel asrModel:(id<VoicePipelineASRModel>)asrModel speakerModel:(VoicePipelineCoreMLModel *)speakerModel onResult:(void (^)(VoicePipelineTranscriptionResult *))onResult __attribute__((swift_name("init(vadModel:asrModel:speakerModel:onResult:)"))) __attribute__((objc_designated_initializer));
- (void)flush __attribute__((swift_name("flush()")));
- (void)processAudioSamples:(VoicePipelineKotlinFloatArray *)samples __attribute__((swift_name("processAudio(samples:)")));
- (void)reset __attribute__((swift_name("reset()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("LiveTranscription")))
@interface VoicePipelineLiveTranscription : VoicePipelineBase
- (instancetype)initWithVadModel:(VoicePipelineCoreMLModel *)vadModel asrModel:(id<VoicePipelineASRModel>)asrModel speakerModel:(VoicePipelineCoreMLModel *)speakerModel voiceLibraryPath:(NSString *)voiceLibraryPath __attribute__((swift_name("init(vadModel:asrModel:speakerModel:voiceLibraryPath:)"))) __attribute__((objc_designated_initializer));
- (int32_t)clusterUnknowns __attribute__((swift_name("clusterUnknowns()")));
- (void)confirmOutliers __attribute__((swift_name("confirmOutliers()")));
- (void)flush __attribute__((swift_name("flush()")));
- (NSArray<VoicePipelineSegment *> *)getSegments __attribute__((swift_name("getSegments()")));
- (void)processAudioSamples:(VoicePipelineKotlinFloatArray *)samples __attribute__((swift_name("processAudio(samples:)")));
- (void)promptNaming __attribute__((swift_name("promptNaming()")));
- (void)reset __attribute__((swift_name("reset()")));
- (void)saveLibrary __attribute__((swift_name("saveLibrary()")));
- (void)showStats __attribute__((swift_name("showStats()")));
- (void)showTranscript __attribute__((swift_name("showTranscript()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Segment")))
@interface VoicePipelineSegment : VoicePipelineBase
- (instancetype)initWithStartTime:(double)startTime endTime:(double)endTime text:(NSString *)text speakerName:(NSString * _Nullable)speakerName confidence:(NSString *)confidence isKnown:(BOOL)isKnown isConflict:(BOOL)isConflict embedding:(VoicePipelineKotlinFloatArray * _Nullable)embedding processTimeMs:(int64_t)processTimeMs learned:(BOOL)learned clusterLabel:(NSString * _Nullable)clusterLabel __attribute__((swift_name("init(startTime:endTime:text:speakerName:confidence:isKnown:isConflict:embedding:processTimeMs:learned:clusterLabel:)"))) __attribute__((objc_designated_initializer));
- (VoicePipelineSegment *)doCopyStartTime:(double)startTime endTime:(double)endTime text:(NSString *)text speakerName:(NSString * _Nullable)speakerName confidence:(NSString *)confidence isKnown:(BOOL)isKnown isConflict:(BOOL)isConflict embedding:(VoicePipelineKotlinFloatArray * _Nullable)embedding processTimeMs:(int64_t)processTimeMs learned:(BOOL)learned clusterLabel:(NSString * _Nullable)clusterLabel __attribute__((swift_name("doCopy(startTime:endTime:text:speakerName:confidence:isKnown:isConflict:embedding:processTimeMs:learned:clusterLabel:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property NSString * _Nullable clusterLabel __attribute__((swift_name("clusterLabel")));
@property (readonly) NSString *confidence __attribute__((swift_name("confidence")));
@property (readonly) VoicePipelineKotlinFloatArray * _Nullable embedding __attribute__((swift_name("embedding")));
@property (readonly) double endTime __attribute__((swift_name("endTime")));
@property (readonly) BOOL isConflict __attribute__((swift_name("isConflict")));
@property (readonly) BOOL isKnown __attribute__((swift_name("isKnown")));
@property (readonly) BOOL learned __attribute__((swift_name("learned")));
@property (readonly) int64_t processTimeMs __attribute__((swift_name("processTimeMs")));
@property (readonly) NSString * _Nullable speakerName __attribute__((swift_name("speakerName")));
@property (readonly) double startTime __attribute__((swift_name("startTime")));
@property (readonly) NSString *text __attribute__((swift_name("text")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("TranscriptionResult")))
@interface VoicePipelineTranscriptionResult : VoicePipelineBase
- (instancetype)initWithText:(NSString *)text tokens:(NSArray<VoicePipelineInt *> *)tokens speakerId:(NSString *)speakerId language:(NSString *)language emotion:(NSString *)emotion duration:(float)duration modelType:(VoicePipelineASRModelType *)modelType __attribute__((swift_name("init(text:tokens:speakerId:language:emotion:duration:modelType:)"))) __attribute__((objc_designated_initializer));
- (VoicePipelineTranscriptionResult *)doCopyText:(NSString *)text tokens:(NSArray<VoicePipelineInt *> *)tokens speakerId:(NSString *)speakerId language:(NSString *)language emotion:(NSString *)emotion duration:(float)duration modelType:(VoicePipelineASRModelType *)modelType __attribute__((swift_name("doCopy(text:tokens:speakerId:language:emotion:duration:modelType:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) float duration __attribute__((swift_name("duration")));
@property (readonly) NSString *emotion __attribute__((swift_name("emotion")));
@property (readonly) NSString *language __attribute__((swift_name("language")));
@property (readonly) VoicePipelineASRModelType *modelType __attribute__((swift_name("modelType")));
@property (readonly) NSString *speakerId __attribute__((swift_name("speakerId")));
@property (readonly) NSString *text __attribute__((swift_name("text")));
@property (readonly) NSArray<VoicePipelineInt *> *tokens __attribute__((swift_name("tokens")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("CTCDecoder")))
@interface VoicePipelineCTCDecoder : VoicePipelineBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)cTCDecoder __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) VoicePipelineCTCDecoder *shared __attribute__((swift_name("shared")));
- (NSArray<VoicePipelineInt *> *)greedyDecodeLogits:(NSArray<VoicePipelineKotlinFloatArray *> *)logits __attribute__((swift_name("greedyDecode(logits:)")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("LFRTransform")))
@interface VoicePipelineLFRTransform : VoicePipelineBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)lFRTransform __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) VoicePipelineLFRTransform *shared __attribute__((swift_name("shared")));
- (NSArray<VoicePipelineKotlinFloatArray *> *)applyMel:(NSArray<VoicePipelineKotlinFloatArray *> *)mel __attribute__((swift_name("apply(mel:)")));
- (NSArray<VoicePipelineKotlinFloatArray *> *)applyAndPadMel:(NSArray<VoicePipelineKotlinFloatArray *> *)mel __attribute__((swift_name("applyAndPad(mel:)")));
- (NSArray<VoicePipelineKotlinFloatArray *> *)padToFixedFramesFeatures:(NSArray<VoicePipelineKotlinFloatArray *> *)features __attribute__((swift_name("padToFixedFrames(features:)")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("SpeakerProfile")))
@interface VoicePipelineSpeakerProfile : VoicePipelineBase
- (instancetype)initWithName:(NSString *)name __attribute__((swift_name("init(name:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) VoicePipelineSpeakerProfileCompanion *companion __attribute__((swift_name("companion")));
- (NSString *)addEmbeddingEmbedding:(VoicePipelineKotlinFloatArray *)embedding forceBoundary:(BOOL)forceBoundary __attribute__((swift_name("addEmbedding(embedding:forceBoundary:)")));
- (NSArray<VoicePipelineFloat *> *)getAllDistances __attribute__((swift_name("getAllDistances()")));
- (NSArray<NSArray<VoicePipelineFloat *> *> *)getBoundaryEmbeddings __attribute__((swift_name("getBoundaryEmbeddings()")));
- (NSArray<VoicePipelineFloat *> * _Nullable)getCentroid __attribute__((swift_name("getCentroid()")));
- (NSArray<NSArray<VoicePipelineFloat *> *> *)getCoreEmbeddings __attribute__((swift_name("getCoreEmbeddings()")));
- (float)getStdDev __attribute__((swift_name("getStdDev()")));
- (float)maxSimilarityToBoundaryEmbedding:(VoicePipelineKotlinFloatArray *)embedding __attribute__((swift_name("maxSimilarityToBoundary(embedding:)")));
- (float)maxSimilarityToCoreEmbedding:(VoicePipelineKotlinFloatArray *)embedding __attribute__((swift_name("maxSimilarityToCore(embedding:)")));
- (void)setAllDistancesDistances:(NSArray<VoicePipelineFloat *> *)distances __attribute__((swift_name("setAllDistances(distances:)")));
- (void)setBoundaryEmbeddingsEmbeddings:(NSArray<NSArray<VoicePipelineFloat *> *> *)embeddings __attribute__((swift_name("setBoundaryEmbeddings(embeddings:)")));
- (void)setCoreEmbeddingsEmbeddings:(NSArray<NSArray<VoicePipelineFloat *> *> *)embeddings __attribute__((swift_name("setCoreEmbeddings(embeddings:)")));
- (void)setStdDevValue:(float)value __attribute__((swift_name("setStdDev(value:)")));
@property (readonly) NSString *name __attribute__((swift_name("name")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("SpeakerProfile.Companion")))
@interface VoicePipelineSpeakerProfileCompanion : VoicePipelineBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) VoicePipelineSpeakerProfileCompanion *shared __attribute__((swift_name("shared")));
- (VoicePipelineSpeakerProfile *)fromDataName:(NSString *)name core:(NSArray<NSArray<VoicePipelineFloat *> *> *)core boundary:(NSArray<NSArray<VoicePipelineFloat *> *> *)boundary centroid:(NSArray<VoicePipelineFloat *> * _Nullable)centroid stdDev:(float)stdDev allDistances:(NSArray<VoicePipelineFloat *> *)allDistances __attribute__((swift_name("fromData(name:core:boundary:centroid:stdDev:allDistances:)")));
- (id<VoicePipelineKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("TokenMappings")))
@interface VoicePipelineTokenMappings : VoicePipelineBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)tokenMappings __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) VoicePipelineTokenMappings *shared __attribute__((swift_name("shared")));
- (VoicePipelineKotlinPair<NSDictionary<NSString *, NSString *> *, NSArray<VoicePipelineInt *> *> *)decodeSpecialTokensTokens:(NSArray<VoicePipelineInt *> *)tokens __attribute__((swift_name("decodeSpecialTokens(tokens:)")));
- (BOOL)isSpecialTokenToken:(int32_t)token __attribute__((swift_name("isSpecialToken(token:)")));
@property (readonly) NSDictionary<VoicePipelineInt *, NSString *> *EMOTION_TOKENS __attribute__((swift_name("EMOTION_TOKENS")));
@property (readonly) NSDictionary<VoicePipelineInt *, NSString *> *EVENT_TOKENS __attribute__((swift_name("EVENT_TOKENS")));
@property (readonly) NSDictionary<VoicePipelineInt *, NSString *> *LANG_TOKENS __attribute__((swift_name("LANG_TOKENS")));
@property (readonly) NSDictionary<VoicePipelineInt *, NSString *> *TASK_TOKENS __attribute__((swift_name("TASK_TOKENS")));
@end

__attribute__((swift_name("ASRModel")))
@protocol VoicePipelineASRModel
@required
- (VoicePipelineASRResult * _Nullable)transcribeAudio:(VoicePipelineKotlinFloatArray *)audio __attribute__((swift_name("transcribe(audio:)")));
@property (readonly) VoicePipelineASRModelType *modelType __attribute__((swift_name("modelType")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ASRModelType")))
@interface VoicePipelineASRModelType : VoicePipelineKotlinEnum<VoicePipelineASRModelType *>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithName:(NSString *)name ordinal:(int32_t)ordinal __attribute__((swift_name("init(name:ordinal:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
@property (class, readonly) VoicePipelineASRModelType *sensevoice __attribute__((swift_name("sensevoice")));
@property (class, readonly) VoicePipelineASRModelType *whisperTurbo __attribute__((swift_name("whisperTurbo")));
+ (VoicePipelineKotlinArray<VoicePipelineASRModelType *> *)values __attribute__((swift_name("values()")));
@property (class, readonly) NSArray<VoicePipelineASRModelType *> *entries __attribute__((swift_name("entries")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ASRResult")))
@interface VoicePipelineASRResult : VoicePipelineBase
- (instancetype)initWithText:(NSString *)text tokens:(NSArray<VoicePipelineInt *> *)tokens language:(NSString * _Nullable)language __attribute__((swift_name("init(text:tokens:language:)"))) __attribute__((objc_designated_initializer));
- (VoicePipelineASRResult *)doCopyText:(NSString *)text tokens:(NSArray<VoicePipelineInt *> *)tokens language:(NSString * _Nullable)language __attribute__((swift_name("doCopy(text:tokens:language:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSString * _Nullable language __attribute__((swift_name("language")));
@property (readonly) NSString *text __attribute__((swift_name("text")));
@property (readonly) NSArray<VoicePipelineInt *> *tokens __attribute__((swift_name("tokens")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("AudioCapture")))
@interface VoicePipelineAudioCapture : VoicePipelineBase
- (instancetype)init __attribute__((swift_name("init()"))) __attribute__((objc_designated_initializer));
+ (instancetype)new __attribute__((availability(swift, unavailable, message="use object initializers instead")));
- (BOOL)checkPermission __attribute__((swift_name("checkPermission()")));
- (void)requestPermissionCallback:(void (^)(VoicePipelineBoolean *))callback __attribute__((swift_name("requestPermission(callback:)")));
- (void)startCallback:(void (^)(VoicePipelineKotlinFloatArray *))callback __attribute__((swift_name("start(callback:)")));
- (void)stop __attribute__((swift_name("stop()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("AudioFileReader")))
@interface VoicePipelineAudioFileReader : VoicePipelineBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)audioFileReader __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) VoicePipelineAudioFileReader *shared __attribute__((swift_name("shared")));
- (VoicePipelineKotlinFloatArray * _Nullable)readFilePath:(NSString *)path __attribute__((swift_name("readFile(path:)")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("AudioProcessing")))
@interface VoicePipelineAudioProcessing : VoicePipelineBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)audioProcessing __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) VoicePipelineAudioProcessing *shared __attribute__((swift_name("shared")));
- (NSArray<VoicePipelineKotlinFloatArray *> *)computeMelSpectrogramAudio:(VoicePipelineKotlinFloatArray *)audio __attribute__((swift_name("computeMelSpectrogram(audio:)")));
- (float)computeRMSSamples:(VoicePipelineKotlinFloatArray *)samples __attribute__((swift_name("computeRMS(samples:)")));
- (void)createMelFilterbank __attribute__((swift_name("createMelFilterbank()")));
- (BOOL)loadMelFilterbankPath:(NSString *)path __attribute__((swift_name("loadMelFilterbank(path:)")));
- (VoicePipelineKotlinFloatArray *)resampleAudio:(VoicePipelineKotlinFloatArray *)audio sourceSR:(int32_t)sourceSR targetSR:(int32_t)targetSR __attribute__((swift_name("resample(audio:sourceSR:targetSR:)")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("CoreMLModel")))
@interface VoicePipelineCoreMLModel : VoicePipelineBase
- (instancetype)initWithInternalModel:(MLModel *)internalModel __attribute__((swift_name("init(internalModel:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) VoicePipelineCoreMLModelCompanion *companion __attribute__((swift_name("companion")));
- (NSDictionary<NSString *, MLMultiArray *> * _Nullable)predictInputs:(NSDictionary<NSString *, MLMultiArray *> *)inputs __attribute__((swift_name("predict(inputs:)")));
- (NSArray<VoicePipelineKotlinFloatArray *> * _Nullable)runASRFeatures:(NSArray<VoicePipelineKotlinFloatArray *> *)features __attribute__((swift_name("runASR(features:)")));
- (VoicePipelineKotlinFloatArray * _Nullable)runSpeakerEmbeddingAudio:(VoicePipelineKotlinFloatArray *)audio __attribute__((swift_name("runSpeakerEmbedding(audio:)")));
- (VoicePipelineVADOutput * _Nullable)runVADAudioInput:(VoicePipelineKotlinFloatArray *)audioInput hiddenState:(VoicePipelineKotlinFloatArray *)hiddenState cellState:(VoicePipelineKotlinFloatArray *)cellState __attribute__((swift_name("runVAD(audioInput:hiddenState:cellState:)")));
@property (readonly) MLModel *internalModel __attribute__((swift_name("internalModel")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("CoreMLModel.Companion")))
@interface VoicePipelineCoreMLModelCompanion : VoicePipelineBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) VoicePipelineCoreMLModelCompanion *shared __attribute__((swift_name("shared")));
- (MLMultiArray * _Nullable)createMLMultiArrayShape:(NSArray<VoicePipelineInt *> *)shape dataType:(int64_t)dataType __attribute__((swift_name("createMLMultiArray(shape:dataType:)")));
- (VoicePipelineCoreMLModel * _Nullable)loadPath:(NSString *)path __attribute__((swift_name("load(path:)")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("LibraryData")))
@interface VoicePipelineLibraryData : VoicePipelineBase
- (instancetype)initWithSpeakers:(NSArray<VoicePipelineSpeakerData *> *)speakers __attribute__((swift_name("init(speakers:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) VoicePipelineLibraryDataCompanion *companion __attribute__((swift_name("companion")));
- (VoicePipelineLibraryData *)doCopySpeakers:(NSArray<VoicePipelineSpeakerData *> *)speakers __attribute__((swift_name("doCopy(speakers:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSArray<VoicePipelineSpeakerData *> *speakers __attribute__((swift_name("speakers")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("LibraryData.Companion")))
@interface VoicePipelineLibraryDataCompanion : VoicePipelineBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) VoicePipelineLibraryDataCompanion *shared __attribute__((swift_name("shared")));
- (id<VoicePipelineKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("MLArrayUtils")))
@interface VoicePipelineMLArrayUtils : VoicePipelineBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)mLArrayUtils __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) VoicePipelineMLArrayUtils *shared __attribute__((swift_name("shared")));
- (void)doCopyFloatArraySrc:(VoicePipelineKotlinFloatArray *)src dst:(MLMultiArray *)dst __attribute__((swift_name("doCopyFloatArray(src:dst:)")));
- (float)getFloatArray:(MLMultiArray *)array index:(int32_t)index __attribute__((swift_name("getFloat(array:index:)")));
- (NSArray<VoicePipelineInt *> *)getShapeArray:(MLMultiArray *)array __attribute__((swift_name("getShape(array:)")));
- (NSArray<VoicePipelineInt *> *)getStridesArray:(MLMultiArray *)array __attribute__((swift_name("getStrides(array:)")));
- (void)setFloatArray:(MLMultiArray *)array index:(int32_t)index value:(float)value __attribute__((swift_name("setFloat(array:index:value:)")));
- (void)setIntArray:(MLMultiArray *)array index:(int32_t)index value:(int32_t)value __attribute__((swift_name("setInt(array:index:value:)")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ModelManager")))
@interface VoicePipelineModelManager : VoicePipelineBase
- (instancetype)initWithModelDir:(NSString *)modelDir whisperModelDir:(NSString * _Nullable)whisperModelDir __attribute__((swift_name("init(modelDir:whisperModelDir:)"))) __attribute__((objc_designated_initializer));
- (NSArray<VoicePipelineASRModelType *> *)getAvailableASRModels __attribute__((swift_name("getAvailableASRModels()")));
- (void)loadModels __attribute__((swift_name("loadModels()")));
- (BOOL)setASRModelType:(VoicePipelineASRModelType *)type __attribute__((swift_name("setASRModel(type:)")));
@property (readonly) id<VoicePipelineASRModel> _Nullable asrModel __attribute__((swift_name("asrModel")));
@property (readonly) VoicePipelineASRModelType *currentASRType __attribute__((swift_name("currentASRType")));
@property (readonly) VoicePipelineCoreMLModel * _Nullable senseVoiceCoreML __attribute__((swift_name("senseVoiceCoreML")));
@property (readonly) VoicePipelineCoreMLModel * _Nullable speakerModel __attribute__((swift_name("speakerModel")));
@property (readonly) VoicePipelineCoreMLModel * _Nullable vadModel __attribute__((swift_name("vadModel")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ONNXModel")))
@interface VoicePipelineONNXModel : VoicePipelineBase
- (instancetype)initWithModelPath:(NSString *)modelPath modelName:(NSString *)modelName __attribute__((swift_name("init(modelPath:modelName:)"))) __attribute__((objc_designated_initializer));
- (BOOL)isLoaded __attribute__((swift_name("isLoaded()")));
- (void)release_ __attribute__((swift_name("release()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ONNXModelManager")))
@interface VoicePipelineONNXModelManager : VoicePipelineBase
- (instancetype)initWithModelsDir:(NSString *)modelsDir __attribute__((swift_name("init(modelsDir:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) VoicePipelineONNXModelManagerCompanion *companion __attribute__((swift_name("companion")));
- (BOOL)loadModels __attribute__((swift_name("loadModels()")));
- (void)release_ __attribute__((swift_name("release()")));
- (void)resetVADState __attribute__((swift_name("resetVADState()")));
- (VoicePipelineKotlinFloatArray * _Nullable)runASRMelLFR:(NSArray<VoicePipelineKotlinFloatArray *> *)melLFR __attribute__((swift_name("runASR(melLFR:)")));
- (VoicePipelineKotlinFloatArray * _Nullable)runSpeakerEmbeddingAudio:(VoicePipelineKotlinFloatArray *)audio __attribute__((swift_name("runSpeakerEmbedding(audio:)")));
- (VoicePipelineONNXModelManagerVADOutput * _Nullable)runVADAudio:(VoicePipelineKotlinFloatArray *)audio hiddenState:(VoicePipelineKotlinFloatArray *)hiddenState cellState:(VoicePipelineKotlinFloatArray *)cellState __attribute__((swift_name("runVAD(audio:hiddenState:cellState:)")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ONNXModelManager.Companion")))
@interface VoicePipelineONNXModelManagerCompanion : VoicePipelineBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) VoicePipelineONNXModelManagerCompanion *shared __attribute__((swift_name("shared")));
@property (readonly) int32_t ONNX_VAD_CHUNK_SIZE __attribute__((swift_name("ONNX_VAD_CHUNK_SIZE")));
@property (readonly) int32_t ONNX_VAD_CONTEXT_SIZE __attribute__((swift_name("ONNX_VAD_CONTEXT_SIZE")));
@property (readonly) int32_t ONNX_VAD_INPUT_SIZE __attribute__((swift_name("ONNX_VAD_INPUT_SIZE")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ONNXModelManager.VADOutput")))
@interface VoicePipelineONNXModelManagerVADOutput : VoicePipelineBase
- (instancetype)initWithProbability:(float)probability hiddenState:(VoicePipelineKotlinFloatArray *)hiddenState cellState:(VoicePipelineKotlinFloatArray *)cellState __attribute__((swift_name("init(probability:hiddenState:cellState:)"))) __attribute__((objc_designated_initializer));
- (VoicePipelineONNXModelManagerVADOutput *)doCopyProbability:(float)probability hiddenState:(VoicePipelineKotlinFloatArray *)hiddenState cellState:(VoicePipelineKotlinFloatArray *)cellState __attribute__((swift_name("doCopy(probability:hiddenState:cellState:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) VoicePipelineKotlinFloatArray *cellState __attribute__((swift_name("cellState")));
@property (readonly) VoicePipelineKotlinFloatArray *hiddenState __attribute__((swift_name("hiddenState")));
@property (readonly) float probability __attribute__((swift_name("probability")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("SenseVoiceASR")))
@interface VoicePipelineSenseVoiceASR : VoicePipelineBase <VoicePipelineASRModel>
- (instancetype)initWithModel:(VoicePipelineCoreMLModel *)model debug:(BOOL)debug __attribute__((swift_name("init(model:debug:)"))) __attribute__((objc_designated_initializer));
- (VoicePipelineASRResult * _Nullable)transcribeAudio:(VoicePipelineKotlinFloatArray *)audio __attribute__((swift_name("transcribe(audio:)")));
@property (readonly) VoicePipelineASRModelType *modelType __attribute__((swift_name("modelType")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("SpeakerData")))
@interface VoicePipelineSpeakerData : VoicePipelineBase
- (instancetype)initWithName:(NSString *)name core:(NSArray<NSArray<VoicePipelineFloat *> *> *)core boundary:(NSArray<NSArray<VoicePipelineFloat *> *> *)boundary centroid:(NSArray<VoicePipelineFloat *> * _Nullable)centroid stdDev:(float)stdDev allDistances:(NSArray<VoicePipelineFloat *> *)allDistances __attribute__((swift_name("init(name:core:boundary:centroid:stdDev:allDistances:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) VoicePipelineSpeakerDataCompanion *companion __attribute__((swift_name("companion")));
- (VoicePipelineSpeakerData *)doCopyName:(NSString *)name core:(NSArray<NSArray<VoicePipelineFloat *> *> *)core boundary:(NSArray<NSArray<VoicePipelineFloat *> *> *)boundary centroid:(NSArray<VoicePipelineFloat *> * _Nullable)centroid stdDev:(float)stdDev allDistances:(NSArray<VoicePipelineFloat *> *)allDistances __attribute__((swift_name("doCopy(name:core:boundary:centroid:stdDev:allDistances:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSArray<VoicePipelineFloat *> *allDistances __attribute__((swift_name("allDistances")));
@property (readonly) NSArray<NSArray<VoicePipelineFloat *> *> *boundary __attribute__((swift_name("boundary")));
@property (readonly) NSArray<VoicePipelineFloat *> * _Nullable centroid __attribute__((swift_name("centroid")));
@property (readonly) NSArray<NSArray<VoicePipelineFloat *> *> *core __attribute__((swift_name("core")));
@property (readonly) NSString *name __attribute__((swift_name("name")));
@property (readonly) float stdDev __attribute__((swift_name("stdDev")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("SpeakerData.Companion")))
@interface VoicePipelineSpeakerDataCompanion : VoicePipelineBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) VoicePipelineSpeakerDataCompanion *shared __attribute__((swift_name("shared")));
- (id<VoicePipelineKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("TokenDecoder")))
@interface VoicePipelineTokenDecoder : VoicePipelineBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)tokenDecoder __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) VoicePipelineTokenDecoder *shared __attribute__((swift_name("shared")));
- (NSString *)decodeTokenIds:(NSArray<VoicePipelineInt *> *)tokenIds __attribute__((swift_name("decode(tokenIds:)")));
- (NSString *)decodeTextTokensTextTokens:(NSArray<VoicePipelineInt *> *)textTokens __attribute__((swift_name("decodeTextTokens(textTokens:)")));
- (BOOL)isLoaded __attribute__((swift_name("isLoaded()")));
- (BOOL)loadVocabularyPath:(NSString *)path __attribute__((swift_name("loadVocabulary(path:)")));
- (int32_t)vocabularySize __attribute__((swift_name("vocabularySize()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("VADOutput")))
@interface VoicePipelineVADOutput : VoicePipelineBase
- (instancetype)initWithProbability:(float)probability newHiddenState:(VoicePipelineKotlinFloatArray *)newHiddenState newCellState:(VoicePipelineKotlinFloatArray *)newCellState __attribute__((swift_name("init(probability:newHiddenState:newCellState:)"))) __attribute__((objc_designated_initializer));
- (VoicePipelineVADOutput *)doCopyProbability:(float)probability newHiddenState:(VoicePipelineKotlinFloatArray *)newHiddenState newCellState:(VoicePipelineKotlinFloatArray *)newCellState __attribute__((swift_name("doCopy(probability:newHiddenState:newCellState:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly, getter=doNewCellState) VoicePipelineKotlinFloatArray *newCellState __attribute__((swift_name("newCellState")));
@property (readonly, getter=doNewHiddenState) VoicePipelineKotlinFloatArray *newHiddenState __attribute__((swift_name("newHiddenState")));
@property (readonly) float probability __attribute__((swift_name("probability")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("VoiceLibrary")))
@interface VoicePipelineVoiceLibrary : VoicePipelineBase
- (instancetype)initWithPath:(NSString *)path __attribute__((swift_name("init(path:)"))) __attribute__((objc_designated_initializer));
- (NSString *)addEmbeddingName:(NSString *)name embedding:(VoicePipelineKotlinFloatArray *)embedding forceBoundary:(BOOL)forceBoundary __attribute__((swift_name("addEmbedding(name:embedding:forceBoundary:)")));
- (BOOL)autoLearnName:(NSString *)name embedding:(VoicePipelineKotlinFloatArray *)embedding score:(float)score __attribute__((swift_name("autoLearn(name:embedding:score:)")));
- (BOOL)enrollSpeakerName:(NSString *)name embedding:(VoicePipelineKotlinFloatArray *)embedding __attribute__((swift_name("enrollSpeaker(name:embedding:)")));
- (NSArray<NSString *> *)getSpeakerNames __attribute__((swift_name("getSpeakerNames()")));
- (BOOL)hasSpeakerName:(NSString *)name __attribute__((swift_name("hasSpeaker(name:)")));
- (VoicePipelineKotlinTriple<NSString *, VoicePipelineFloat *, NSString *> *)matchEmbedding:(VoicePipelineKotlinFloatArray *)embedding __attribute__((swift_name("match(embedding:)")));
- (void)save __attribute__((swift_name("save()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("WhisperASR")))
@interface VoicePipelineWhisperASR : VoicePipelineBase <VoicePipelineASRModel>
@property (class, readonly, getter=companion) VoicePipelineWhisperASRCompanion *companion __attribute__((swift_name("companion")));
- (VoicePipelineASRResult * _Nullable)transcribeAudio:(VoicePipelineKotlinFloatArray *)audio __attribute__((swift_name("transcribe(audio:)")));
@property (readonly) VoicePipelineASRModelType *modelType __attribute__((swift_name("modelType")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("WhisperASR.Companion")))
@interface VoicePipelineWhisperASRCompanion : VoicePipelineBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) VoicePipelineWhisperASRCompanion *shared __attribute__((swift_name("shared")));
- (VoicePipelineWhisperASR * _Nullable)loadModelDir:(NSString *)modelDir __attribute__((swift_name("load(modelDir:)")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("WhisperConfig")))
@interface VoicePipelineWhisperConfig : VoicePipelineBase
- (instancetype)initWithNumMelBins:(int32_t)numMelBins maxSourcePositions:(int32_t)maxSourcePositions maxLength:(int32_t)maxLength vocabSize:(int32_t)vocabSize decoderStartTokenId:(int32_t)decoderStartTokenId eosTokenId:(int32_t)eosTokenId noTimestampsTokenId:(int32_t)noTimestampsTokenId langToId:(NSDictionary<NSString *, VoicePipelineInt *> *)langToId taskToId:(NSDictionary<NSString *, VoicePipelineInt *> *)taskToId suppressTokens:(NSSet<VoicePipelineInt *> *)suppressTokens __attribute__((swift_name("init(numMelBins:maxSourcePositions:maxLength:vocabSize:decoderStartTokenId:eosTokenId:noTimestampsTokenId:langToId:taskToId:suppressTokens:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) VoicePipelineWhisperConfigCompanion *companion __attribute__((swift_name("companion")));
- (VoicePipelineWhisperConfig *)doCopyNumMelBins:(int32_t)numMelBins maxSourcePositions:(int32_t)maxSourcePositions maxLength:(int32_t)maxLength vocabSize:(int32_t)vocabSize decoderStartTokenId:(int32_t)decoderStartTokenId eosTokenId:(int32_t)eosTokenId noTimestampsTokenId:(int32_t)noTimestampsTokenId langToId:(NSDictionary<NSString *, VoicePipelineInt *> *)langToId taskToId:(NSDictionary<NSString *, VoicePipelineInt *> *)taskToId suppressTokens:(NSSet<VoicePipelineInt *> *)suppressTokens __attribute__((swift_name("doCopy(numMelBins:maxSourcePositions:maxLength:vocabSize:decoderStartTokenId:eosTokenId:noTimestampsTokenId:langToId:taskToId:suppressTokens:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) int32_t decoderStartTokenId __attribute__((swift_name("decoderStartTokenId")));
@property (readonly) int32_t eosTokenId __attribute__((swift_name("eosTokenId")));
@property (readonly) NSDictionary<NSString *, VoicePipelineInt *> *langToId __attribute__((swift_name("langToId")));
@property (readonly) int32_t maxLength __attribute__((swift_name("maxLength")));
@property (readonly) int32_t maxSourcePositions __attribute__((swift_name("maxSourcePositions")));
@property (readonly) int32_t noTimestampsTokenId __attribute__((swift_name("noTimestampsTokenId")));
@property (readonly) int32_t numMelBins __attribute__((swift_name("numMelBins")));
@property (readonly) NSSet<VoicePipelineInt *> *suppressTokens __attribute__((swift_name("suppressTokens")));
@property (readonly) NSDictionary<NSString *, VoicePipelineInt *> *taskToId __attribute__((swift_name("taskToId")));
@property (readonly) int32_t vocabSize __attribute__((swift_name("vocabSize")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("WhisperConfig.Companion")))
@interface VoicePipelineWhisperConfigCompanion : VoicePipelineBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) VoicePipelineWhisperConfigCompanion *shared __attribute__((swift_name("shared")));
- (VoicePipelineWhisperConfig * _Nullable)loadConfigPath:(NSString *)configPath generationConfigPath:(NSString *)generationConfigPath __attribute__((swift_name("load(configPath:generationConfigPath:)")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("WhisperTokenizer")))
@interface VoicePipelineWhisperTokenizer : VoicePipelineBase
@property (class, readonly, getter=companion) VoicePipelineWhisperTokenizerCompanion *companion __attribute__((swift_name("companion")));
- (NSString *)decodeTokens:(NSArray<VoicePipelineInt *> *)tokens __attribute__((swift_name("decode(tokens:)")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("WhisperTokenizer.Companion")))
@interface VoicePipelineWhisperTokenizerCompanion : VoicePipelineBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) VoicePipelineWhisperTokenizerCompanion *shared __attribute__((swift_name("shared")));
- (VoicePipelineWhisperTokenizer * _Nullable)loadPath:(NSString *)path __attribute__((swift_name("load(path:)")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("BenchmarkKt")))
@interface VoicePipelineBenchmarkKt : VoicePipelineBase
+ (void)runBenchmarkAudioPath:(NSString * _Nullable)audioPath __attribute__((swift_name("runBenchmark(audioPath:)")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ConfigKt")))
@interface VoicePipelineConfigKt : VoicePipelineBase
@property (class, readonly) NSString *ALT_TEST_AUDIO_PATH __attribute__((swift_name("ALT_TEST_AUDIO_PATH")));
@property (class, readonly) NSString *ASSETS_DIR __attribute__((swift_name("ASSETS_DIR")));
@property (class, readonly) NSString *MODEL_DIR __attribute__((swift_name("MODEL_DIR")));
@property (class, readonly) NSString *ONNX_MODEL_DIR __attribute__((swift_name("ONNX_MODEL_DIR")));
@property (class, readonly) NSString *TEST_AUDIO_PATH __attribute__((swift_name("TEST_AUDIO_PATH")));
@property (class, readonly) NSString *VAD_MODEL_PATH __attribute__((swift_name("VAD_MODEL_PATH")));
@property (class, readonly) NSString *VOICE_LIBRARY_PATH __attribute__((swift_name("VOICE_LIBRARY_PATH")));
@property (class, readonly) NSString *WHISPER_TURBO_MODEL_DIR __attribute__((swift_name("WHISPER_TURBO_MODEL_DIR")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ConstantsKt")))
@interface VoicePipelineConstantsKt : VoicePipelineBase
@property (class, readonly) float AUTO_LEARN_THRESHOLD __attribute__((swift_name("AUTO_LEARN_THRESHOLD")));
@property (class, readonly) float BOUNDARY_THRESHOLD __attribute__((swift_name("BOUNDARY_THRESHOLD")));
@property (class, readonly) int32_t CHUNK_SIZE __attribute__((swift_name("CHUNK_SIZE")));
@property (class, readonly) float CONFLICT_MARGIN __attribute__((swift_name("CONFLICT_MARGIN")));
@property (class, readonly) float CORE_THRESHOLD __attribute__((swift_name("CORE_THRESHOLD")));
@property (class, readonly) int32_t FEATURE_DIM __attribute__((swift_name("FEATURE_DIM")));
@property (class, readonly) int32_t FIXED_FRAMES __attribute__((swift_name("FIXED_FRAMES")));
@property (class, readonly) int32_t HOP_LENGTH __attribute__((swift_name("HOP_LENGTH")));
@property (class, readonly) int32_t LFR_M __attribute__((swift_name("LFR_M")));
@property (class, readonly) int32_t LFR_N __attribute__((swift_name("LFR_N")));
@property (class, readonly) int32_t MAX_BOUNDARY __attribute__((swift_name("MAX_BOUNDARY")));
@property (class, readonly) int32_t MAX_CORE __attribute__((swift_name("MAX_CORE")));
@property (class, readonly) float MIN_DIVERSITY __attribute__((swift_name("MIN_DIVERSITY")));
@property (class, readonly) double MIN_SILENCE_DURATION __attribute__((swift_name("MIN_SILENCE_DURATION")));
@property (class, readonly) double MIN_SPEECH_DURATION __attribute__((swift_name("MIN_SPEECH_DURATION")));
@property (class, readonly) int32_t N_FFT __attribute__((swift_name("N_FFT")));
@property (class, readonly) int32_t N_MELS __attribute__((swift_name("N_MELS")));
@property (class, readonly) int32_t SAMPLE_RATE __attribute__((swift_name("SAMPLE_RATE")));
@property (class, readonly) double SAMPLE_RATE_DOUBLE __attribute__((swift_name("SAMPLE_RATE_DOUBLE")));
@property (class, readonly) int32_t VAD_CHUNK_SIZE __attribute__((swift_name("VAD_CHUNK_SIZE")));
@property (class, readonly) int32_t VAD_CONTEXT_SIZE __attribute__((swift_name("VAD_CONTEXT_SIZE")));
@property (class, readonly) int32_t VAD_MODEL_INPUT_SIZE __attribute__((swift_name("VAD_MODEL_INPUT_SIZE")));
@property (class, readonly) float VAD_SPEECH_THRESHOLD __attribute__((swift_name("VAD_SPEECH_THRESHOLD")));
@property (class, readonly) int32_t VAD_STATE_SIZE __attribute__((swift_name("VAD_STATE_SIZE")));
@property (class, readonly) int32_t XVECTOR_DIM __attribute__((swift_name("XVECTOR_DIM")));
@property (class, readonly) int32_t XVECTOR_SAMPLES __attribute__((swift_name("XVECTOR_SAMPLES")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("LiveTranscriptionKt")))
@interface VoicePipelineLiveTranscriptionKt : VoicePipelineBase
+ (NSArray<VoicePipelineSegment *> *)processFileTranscriptionAudioPath:(NSString *)audioPath vadModel:(VoicePipelineCoreMLModel *)vadModel asrModel:(id<VoicePipelineASRModel>)asrModel speakerModel:(VoicePipelineCoreMLModel *)speakerModel voiceLibraryPath:(NSString *)voiceLibraryPath __attribute__((swift_name("processFileTranscription(audioPath:vadModel:asrModel:speakerModel:voiceLibraryPath:)")));
+ (void)runLiveTranscriptionVadModel:(VoicePipelineCoreMLModel *)vadModel asrModel:(id<VoicePipelineASRModel>)asrModel speakerModel:(VoicePipelineCoreMLModel *)speakerModel voiceLibraryPath:(NSString *)voiceLibraryPath __attribute__((swift_name("runLiveTranscription(vadModel:asrModel:speakerModel:voiceLibraryPath:)")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("MainKt")))
@interface VoicePipelineMainKt : VoicePipelineBase
+ (void)mainArgs:(VoicePipelineKotlinArray<NSString *> *)args __attribute__((swift_name("main(args:)")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("TestsKt")))
@interface VoicePipelineTestsKt : VoicePipelineBase
+ (void)runTests __attribute__((swift_name("runTests()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("VectorOpsKt")))
@interface VoicePipelineVectorOpsKt : VoicePipelineBase
+ (VoicePipelineKotlinFloatArray * _Nullable)computeCentroidVectors:(NSArray<VoicePipelineKotlinFloatArray *> *)vectors __attribute__((swift_name("computeCentroid(vectors:)")));
+ (float)computeStdDevDistances:(NSArray<VoicePipelineFloat *> *)distances __attribute__((swift_name("computeStdDev(distances:)")));
+ (float)cosineDistanceA:(VoicePipelineKotlinFloatArray *)a b:(VoicePipelineKotlinFloatArray *)b __attribute__((swift_name("cosineDistance(a:b:)")));
+ (float)cosineSimilarityA:(VoicePipelineKotlinFloatArray *)a b:(VoicePipelineKotlinFloatArray *)b __attribute__((swift_name("cosineSimilarity(a:b:)")));
+ (float)l2NormV:(VoicePipelineKotlinFloatArray *)v __attribute__((swift_name("l2Norm(v:)")));
+ (VoicePipelineKotlinFloatArray *)normalizeV:(VoicePipelineKotlinFloatArray *)v __attribute__((swift_name("normalize(v:)")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("KotlinFloatArray")))
@interface VoicePipelineKotlinFloatArray : VoicePipelineBase
+ (instancetype)arrayWithSize:(int32_t)size __attribute__((swift_name("init(size:)")));
+ (instancetype)arrayWithSize:(int32_t)size init:(VoicePipelineFloat *(^)(VoicePipelineInt *))init __attribute__((swift_name("init(size:init:)")));
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (float)getIndex:(int32_t)index __attribute__((swift_name("get(index:)")));
- (VoicePipelineKotlinFloatIterator *)iterator __attribute__((swift_name("iterator()")));
- (void)setIndex:(int32_t)index value:(float)value __attribute__((swift_name("set(index:value:)")));
@property (readonly) int32_t size __attribute__((swift_name("size")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("KotlinEnumCompanion")))
@interface VoicePipelineKotlinEnumCompanion : VoicePipelineBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) VoicePipelineKotlinEnumCompanion *shared __attribute__((swift_name("shared")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("KotlinArray")))
@interface VoicePipelineKotlinArray<T> : VoicePipelineBase
+ (instancetype)arrayWithSize:(int32_t)size init:(T _Nullable (^)(VoicePipelineInt *))init __attribute__((swift_name("init(size:init:)")));
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (T _Nullable)getIndex:(int32_t)index __attribute__((swift_name("get(index:)")));
- (id<VoicePipelineKotlinIterator>)iterator __attribute__((swift_name("iterator()")));
- (void)setIndex:(int32_t)index value:(T _Nullable)value __attribute__((swift_name("set(index:value:)")));
@property (readonly) int32_t size __attribute__((swift_name("size")));
@end

__attribute__((swift_name("Kotlinx_serialization_coreSerializationStrategy")))
@protocol VoicePipelineKotlinx_serialization_coreSerializationStrategy
@required
- (void)serializeEncoder:(id<VoicePipelineKotlinx_serialization_coreEncoder>)encoder value:(id _Nullable)value __attribute__((swift_name("serialize(encoder:value:)")));
@property (readonly) id<VoicePipelineKotlinx_serialization_coreSerialDescriptor> descriptor __attribute__((swift_name("descriptor")));
@end

__attribute__((swift_name("Kotlinx_serialization_coreDeserializationStrategy")))
@protocol VoicePipelineKotlinx_serialization_coreDeserializationStrategy
@required
- (id _Nullable)deserializeDecoder:(id<VoicePipelineKotlinx_serialization_coreDecoder>)decoder __attribute__((swift_name("deserialize(decoder:)")));
@property (readonly) id<VoicePipelineKotlinx_serialization_coreSerialDescriptor> descriptor __attribute__((swift_name("descriptor")));
@end

__attribute__((swift_name("Kotlinx_serialization_coreKSerializer")))
@protocol VoicePipelineKotlinx_serialization_coreKSerializer <VoicePipelineKotlinx_serialization_coreSerializationStrategy, VoicePipelineKotlinx_serialization_coreDeserializationStrategy>
@required
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("KotlinPair")))
@interface VoicePipelineKotlinPair<__covariant A, __covariant B> : VoicePipelineBase
- (instancetype)initWithFirst:(A _Nullable)first second:(B _Nullable)second __attribute__((swift_name("init(first:second:)"))) __attribute__((objc_designated_initializer));
- (VoicePipelineKotlinPair<A, B> *)doCopyFirst:(A _Nullable)first second:(B _Nullable)second __attribute__((swift_name("doCopy(first:second:)")));
- (BOOL)equalsOther:(id _Nullable)other __attribute__((swift_name("equals(other:)")));
- (int32_t)hashCode __attribute__((swift_name("hashCode()")));
- (NSString *)toString __attribute__((swift_name("toString()")));
@property (readonly) A _Nullable first __attribute__((swift_name("first")));
@property (readonly) B _Nullable second __attribute__((swift_name("second")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("KotlinTriple")))
@interface VoicePipelineKotlinTriple<__covariant A, __covariant B, __covariant C> : VoicePipelineBase
- (instancetype)initWithFirst:(A _Nullable)first second:(B _Nullable)second third:(C _Nullable)third __attribute__((swift_name("init(first:second:third:)"))) __attribute__((objc_designated_initializer));
- (VoicePipelineKotlinTriple<A, B, C> *)doCopyFirst:(A _Nullable)first second:(B _Nullable)second third:(C _Nullable)third __attribute__((swift_name("doCopy(first:second:third:)")));
- (BOOL)equalsOther:(id _Nullable)other __attribute__((swift_name("equals(other:)")));
- (int32_t)hashCode __attribute__((swift_name("hashCode()")));
- (NSString *)toString __attribute__((swift_name("toString()")));
@property (readonly) A _Nullable first __attribute__((swift_name("first")));
@property (readonly) B _Nullable second __attribute__((swift_name("second")));
@property (readonly) C _Nullable third __attribute__((swift_name("third")));
@end

__attribute__((swift_name("KotlinIterator")))
@protocol VoicePipelineKotlinIterator
@required
- (BOOL)hasNext __attribute__((swift_name("hasNext()")));
- (id _Nullable)next __attribute__((swift_name("next()")));
@end

__attribute__((swift_name("KotlinFloatIterator")))
@interface VoicePipelineKotlinFloatIterator : VoicePipelineBase <VoicePipelineKotlinIterator>
- (instancetype)init __attribute__((swift_name("init()"))) __attribute__((objc_designated_initializer));
+ (instancetype)new __attribute__((availability(swift, unavailable, message="use object initializers instead")));
- (VoicePipelineFloat *)next __attribute__((swift_name("next()")));
- (float)nextFloat __attribute__((swift_name("nextFloat()")));
@end

__attribute__((swift_name("Kotlinx_serialization_coreEncoder")))
@protocol VoicePipelineKotlinx_serialization_coreEncoder
@required
- (id<VoicePipelineKotlinx_serialization_coreCompositeEncoder>)beginCollectionDescriptor:(id<VoicePipelineKotlinx_serialization_coreSerialDescriptor>)descriptor collectionSize:(int32_t)collectionSize __attribute__((swift_name("beginCollection(descriptor:collectionSize:)")));
- (id<VoicePipelineKotlinx_serialization_coreCompositeEncoder>)beginStructureDescriptor:(id<VoicePipelineKotlinx_serialization_coreSerialDescriptor>)descriptor __attribute__((swift_name("beginStructure(descriptor:)")));
- (void)encodeBooleanValue:(BOOL)value __attribute__((swift_name("encodeBoolean(value:)")));
- (void)encodeByteValue:(int8_t)value __attribute__((swift_name("encodeByte(value:)")));
- (void)encodeCharValue:(unichar)value __attribute__((swift_name("encodeChar(value:)")));
- (void)encodeDoubleValue:(double)value __attribute__((swift_name("encodeDouble(value:)")));
- (void)encodeEnumEnumDescriptor:(id<VoicePipelineKotlinx_serialization_coreSerialDescriptor>)enumDescriptor index:(int32_t)index __attribute__((swift_name("encodeEnum(enumDescriptor:index:)")));
- (void)encodeFloatValue:(float)value __attribute__((swift_name("encodeFloat(value:)")));
- (id<VoicePipelineKotlinx_serialization_coreEncoder>)encodeInlineDescriptor:(id<VoicePipelineKotlinx_serialization_coreSerialDescriptor>)descriptor __attribute__((swift_name("encodeInline(descriptor:)")));
- (void)encodeIntValue:(int32_t)value __attribute__((swift_name("encodeInt(value:)")));
- (void)encodeLongValue:(int64_t)value __attribute__((swift_name("encodeLong(value:)")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (void)encodeNotNullMark __attribute__((swift_name("encodeNotNullMark()")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (void)encodeNull __attribute__((swift_name("encodeNull()")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (void)encodeNullableSerializableValueSerializer:(id<VoicePipelineKotlinx_serialization_coreSerializationStrategy>)serializer value:(id _Nullable)value __attribute__((swift_name("encodeNullableSerializableValue(serializer:value:)")));
- (void)encodeSerializableValueSerializer:(id<VoicePipelineKotlinx_serialization_coreSerializationStrategy>)serializer value:(id _Nullable)value __attribute__((swift_name("encodeSerializableValue(serializer:value:)")));
- (void)encodeShortValue:(int16_t)value __attribute__((swift_name("encodeShort(value:)")));
- (void)encodeStringValue:(NSString *)value __attribute__((swift_name("encodeString(value:)")));
@property (readonly) VoicePipelineKotlinx_serialization_coreSerializersModule *serializersModule __attribute__((swift_name("serializersModule")));
@end

__attribute__((swift_name("Kotlinx_serialization_coreSerialDescriptor")))
@protocol VoicePipelineKotlinx_serialization_coreSerialDescriptor
@required

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (NSArray<id<VoicePipelineKotlinAnnotation>> *)getElementAnnotationsIndex:(int32_t)index __attribute__((swift_name("getElementAnnotations(index:)")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (id<VoicePipelineKotlinx_serialization_coreSerialDescriptor>)getElementDescriptorIndex:(int32_t)index __attribute__((swift_name("getElementDescriptor(index:)")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (int32_t)getElementIndexName:(NSString *)name __attribute__((swift_name("getElementIndex(name:)")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (NSString *)getElementNameIndex:(int32_t)index __attribute__((swift_name("getElementName(index:)")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (BOOL)isElementOptionalIndex:(int32_t)index __attribute__((swift_name("isElementOptional(index:)")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
@property (readonly) NSArray<id<VoicePipelineKotlinAnnotation>> *annotations __attribute__((swift_name("annotations")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
@property (readonly) int32_t elementsCount __attribute__((swift_name("elementsCount")));
@property (readonly) BOOL isInline __attribute__((swift_name("isInline")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
@property (readonly) BOOL isNullable __attribute__((swift_name("isNullable")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
@property (readonly) VoicePipelineKotlinx_serialization_coreSerialKind *kind __attribute__((swift_name("kind")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
@property (readonly) NSString *serialName __attribute__((swift_name("serialName")));
@end

__attribute__((swift_name("Kotlinx_serialization_coreDecoder")))
@protocol VoicePipelineKotlinx_serialization_coreDecoder
@required
- (id<VoicePipelineKotlinx_serialization_coreCompositeDecoder>)beginStructureDescriptor:(id<VoicePipelineKotlinx_serialization_coreSerialDescriptor>)descriptor __attribute__((swift_name("beginStructure(descriptor:)")));
- (BOOL)decodeBoolean __attribute__((swift_name("decodeBoolean()")));
- (int8_t)decodeByte __attribute__((swift_name("decodeByte()")));
- (unichar)decodeChar __attribute__((swift_name("decodeChar()")));
- (double)decodeDouble __attribute__((swift_name("decodeDouble()")));
- (int32_t)decodeEnumEnumDescriptor:(id<VoicePipelineKotlinx_serialization_coreSerialDescriptor>)enumDescriptor __attribute__((swift_name("decodeEnum(enumDescriptor:)")));
- (float)decodeFloat __attribute__((swift_name("decodeFloat()")));
- (id<VoicePipelineKotlinx_serialization_coreDecoder>)decodeInlineDescriptor:(id<VoicePipelineKotlinx_serialization_coreSerialDescriptor>)descriptor __attribute__((swift_name("decodeInline(descriptor:)")));
- (int32_t)decodeInt __attribute__((swift_name("decodeInt()")));
- (int64_t)decodeLong __attribute__((swift_name("decodeLong()")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (BOOL)decodeNotNullMark __attribute__((swift_name("decodeNotNullMark()")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (VoicePipelineKotlinNothing * _Nullable)decodeNull __attribute__((swift_name("decodeNull()")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (id _Nullable)decodeNullableSerializableValueDeserializer:(id<VoicePipelineKotlinx_serialization_coreDeserializationStrategy>)deserializer __attribute__((swift_name("decodeNullableSerializableValue(deserializer:)")));
- (id _Nullable)decodeSerializableValueDeserializer:(id<VoicePipelineKotlinx_serialization_coreDeserializationStrategy>)deserializer __attribute__((swift_name("decodeSerializableValue(deserializer:)")));
- (int16_t)decodeShort __attribute__((swift_name("decodeShort()")));
- (NSString *)decodeString __attribute__((swift_name("decodeString()")));
@property (readonly) VoicePipelineKotlinx_serialization_coreSerializersModule *serializersModule __attribute__((swift_name("serializersModule")));
@end

__attribute__((swift_name("Kotlinx_serialization_coreCompositeEncoder")))
@protocol VoicePipelineKotlinx_serialization_coreCompositeEncoder
@required
- (void)encodeBooleanElementDescriptor:(id<VoicePipelineKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index value:(BOOL)value __attribute__((swift_name("encodeBooleanElement(descriptor:index:value:)")));
- (void)encodeByteElementDescriptor:(id<VoicePipelineKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index value:(int8_t)value __attribute__((swift_name("encodeByteElement(descriptor:index:value:)")));
- (void)encodeCharElementDescriptor:(id<VoicePipelineKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index value:(unichar)value __attribute__((swift_name("encodeCharElement(descriptor:index:value:)")));
- (void)encodeDoubleElementDescriptor:(id<VoicePipelineKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index value:(double)value __attribute__((swift_name("encodeDoubleElement(descriptor:index:value:)")));
- (void)encodeFloatElementDescriptor:(id<VoicePipelineKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index value:(float)value __attribute__((swift_name("encodeFloatElement(descriptor:index:value:)")));
- (id<VoicePipelineKotlinx_serialization_coreEncoder>)encodeInlineElementDescriptor:(id<VoicePipelineKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index __attribute__((swift_name("encodeInlineElement(descriptor:index:)")));
- (void)encodeIntElementDescriptor:(id<VoicePipelineKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index value:(int32_t)value __attribute__((swift_name("encodeIntElement(descriptor:index:value:)")));
- (void)encodeLongElementDescriptor:(id<VoicePipelineKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index value:(int64_t)value __attribute__((swift_name("encodeLongElement(descriptor:index:value:)")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (void)encodeNullableSerializableElementDescriptor:(id<VoicePipelineKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index serializer:(id<VoicePipelineKotlinx_serialization_coreSerializationStrategy>)serializer value:(id _Nullable)value __attribute__((swift_name("encodeNullableSerializableElement(descriptor:index:serializer:value:)")));
- (void)encodeSerializableElementDescriptor:(id<VoicePipelineKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index serializer:(id<VoicePipelineKotlinx_serialization_coreSerializationStrategy>)serializer value:(id _Nullable)value __attribute__((swift_name("encodeSerializableElement(descriptor:index:serializer:value:)")));
- (void)encodeShortElementDescriptor:(id<VoicePipelineKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index value:(int16_t)value __attribute__((swift_name("encodeShortElement(descriptor:index:value:)")));
- (void)encodeStringElementDescriptor:(id<VoicePipelineKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index value:(NSString *)value __attribute__((swift_name("encodeStringElement(descriptor:index:value:)")));
- (void)endStructureDescriptor:(id<VoicePipelineKotlinx_serialization_coreSerialDescriptor>)descriptor __attribute__((swift_name("endStructure(descriptor:)")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (BOOL)shouldEncodeElementDefaultDescriptor:(id<VoicePipelineKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index __attribute__((swift_name("shouldEncodeElementDefault(descriptor:index:)")));
@property (readonly) VoicePipelineKotlinx_serialization_coreSerializersModule *serializersModule __attribute__((swift_name("serializersModule")));
@end

__attribute__((swift_name("Kotlinx_serialization_coreSerializersModule")))
@interface VoicePipelineKotlinx_serialization_coreSerializersModule : VoicePipelineBase

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (void)dumpToCollector:(id<VoicePipelineKotlinx_serialization_coreSerializersModuleCollector>)collector __attribute__((swift_name("dumpTo(collector:)")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (id<VoicePipelineKotlinx_serialization_coreKSerializer> _Nullable)getContextualKClass:(id<VoicePipelineKotlinKClass>)kClass typeArgumentsSerializers:(NSArray<id<VoicePipelineKotlinx_serialization_coreKSerializer>> *)typeArgumentsSerializers __attribute__((swift_name("getContextual(kClass:typeArgumentsSerializers:)")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (id<VoicePipelineKotlinx_serialization_coreSerializationStrategy> _Nullable)getPolymorphicBaseClass:(id<VoicePipelineKotlinKClass>)baseClass value:(id)value __attribute__((swift_name("getPolymorphic(baseClass:value:)")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (id<VoicePipelineKotlinx_serialization_coreDeserializationStrategy> _Nullable)getPolymorphicBaseClass:(id<VoicePipelineKotlinKClass>)baseClass serializedClassName:(NSString * _Nullable)serializedClassName __attribute__((swift_name("getPolymorphic(baseClass:serializedClassName:)")));
@end

__attribute__((swift_name("KotlinAnnotation")))
@protocol VoicePipelineKotlinAnnotation
@required
@end


/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
__attribute__((swift_name("Kotlinx_serialization_coreSerialKind")))
@interface VoicePipelineKotlinx_serialization_coreSerialKind : VoicePipelineBase
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@end

__attribute__((swift_name("Kotlinx_serialization_coreCompositeDecoder")))
@protocol VoicePipelineKotlinx_serialization_coreCompositeDecoder
@required
- (BOOL)decodeBooleanElementDescriptor:(id<VoicePipelineKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index __attribute__((swift_name("decodeBooleanElement(descriptor:index:)")));
- (int8_t)decodeByteElementDescriptor:(id<VoicePipelineKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index __attribute__((swift_name("decodeByteElement(descriptor:index:)")));
- (unichar)decodeCharElementDescriptor:(id<VoicePipelineKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index __attribute__((swift_name("decodeCharElement(descriptor:index:)")));
- (int32_t)decodeCollectionSizeDescriptor:(id<VoicePipelineKotlinx_serialization_coreSerialDescriptor>)descriptor __attribute__((swift_name("decodeCollectionSize(descriptor:)")));
- (double)decodeDoubleElementDescriptor:(id<VoicePipelineKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index __attribute__((swift_name("decodeDoubleElement(descriptor:index:)")));
- (int32_t)decodeElementIndexDescriptor:(id<VoicePipelineKotlinx_serialization_coreSerialDescriptor>)descriptor __attribute__((swift_name("decodeElementIndex(descriptor:)")));
- (float)decodeFloatElementDescriptor:(id<VoicePipelineKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index __attribute__((swift_name("decodeFloatElement(descriptor:index:)")));
- (id<VoicePipelineKotlinx_serialization_coreDecoder>)decodeInlineElementDescriptor:(id<VoicePipelineKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index __attribute__((swift_name("decodeInlineElement(descriptor:index:)")));
- (int32_t)decodeIntElementDescriptor:(id<VoicePipelineKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index __attribute__((swift_name("decodeIntElement(descriptor:index:)")));
- (int64_t)decodeLongElementDescriptor:(id<VoicePipelineKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index __attribute__((swift_name("decodeLongElement(descriptor:index:)")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (id _Nullable)decodeNullableSerializableElementDescriptor:(id<VoicePipelineKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index deserializer:(id<VoicePipelineKotlinx_serialization_coreDeserializationStrategy>)deserializer previousValue:(id _Nullable)previousValue __attribute__((swift_name("decodeNullableSerializableElement(descriptor:index:deserializer:previousValue:)")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (BOOL)decodeSequentially __attribute__((swift_name("decodeSequentially()")));
- (id _Nullable)decodeSerializableElementDescriptor:(id<VoicePipelineKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index deserializer:(id<VoicePipelineKotlinx_serialization_coreDeserializationStrategy>)deserializer previousValue:(id _Nullable)previousValue __attribute__((swift_name("decodeSerializableElement(descriptor:index:deserializer:previousValue:)")));
- (int16_t)decodeShortElementDescriptor:(id<VoicePipelineKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index __attribute__((swift_name("decodeShortElement(descriptor:index:)")));
- (NSString *)decodeStringElementDescriptor:(id<VoicePipelineKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index __attribute__((swift_name("decodeStringElement(descriptor:index:)")));
- (void)endStructureDescriptor:(id<VoicePipelineKotlinx_serialization_coreSerialDescriptor>)descriptor __attribute__((swift_name("endStructure(descriptor:)")));
@property (readonly) VoicePipelineKotlinx_serialization_coreSerializersModule *serializersModule __attribute__((swift_name("serializersModule")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("KotlinNothing")))
@interface VoicePipelineKotlinNothing : VoicePipelineBase
@end


/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
__attribute__((swift_name("Kotlinx_serialization_coreSerializersModuleCollector")))
@protocol VoicePipelineKotlinx_serialization_coreSerializersModuleCollector
@required
- (void)contextualKClass:(id<VoicePipelineKotlinKClass>)kClass provider:(id<VoicePipelineKotlinx_serialization_coreKSerializer> (^)(NSArray<id<VoicePipelineKotlinx_serialization_coreKSerializer>> *))provider __attribute__((swift_name("contextual(kClass:provider:)")));
- (void)contextualKClass:(id<VoicePipelineKotlinKClass>)kClass serializer:(id<VoicePipelineKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("contextual(kClass:serializer:)")));
- (void)polymorphicBaseClass:(id<VoicePipelineKotlinKClass>)baseClass actualClass:(id<VoicePipelineKotlinKClass>)actualClass actualSerializer:(id<VoicePipelineKotlinx_serialization_coreKSerializer>)actualSerializer __attribute__((swift_name("polymorphic(baseClass:actualClass:actualSerializer:)")));
- (void)polymorphicDefaultBaseClass:(id<VoicePipelineKotlinKClass>)baseClass defaultDeserializerProvider:(id<VoicePipelineKotlinx_serialization_coreDeserializationStrategy> _Nullable (^)(NSString * _Nullable))defaultDeserializerProvider __attribute__((swift_name("polymorphicDefault(baseClass:defaultDeserializerProvider:)"))) __attribute__((deprecated("Deprecated in favor of function with more precise name: polymorphicDefaultDeserializer")));
- (void)polymorphicDefaultDeserializerBaseClass:(id<VoicePipelineKotlinKClass>)baseClass defaultDeserializerProvider:(id<VoicePipelineKotlinx_serialization_coreDeserializationStrategy> _Nullable (^)(NSString * _Nullable))defaultDeserializerProvider __attribute__((swift_name("polymorphicDefaultDeserializer(baseClass:defaultDeserializerProvider:)")));
- (void)polymorphicDefaultSerializerBaseClass:(id<VoicePipelineKotlinKClass>)baseClass defaultSerializerProvider:(id<VoicePipelineKotlinx_serialization_coreSerializationStrategy> _Nullable (^)(id))defaultSerializerProvider __attribute__((swift_name("polymorphicDefaultSerializer(baseClass:defaultSerializerProvider:)")));
@end

__attribute__((swift_name("KotlinKDeclarationContainer")))
@protocol VoicePipelineKotlinKDeclarationContainer
@required
@end

__attribute__((swift_name("KotlinKAnnotatedElement")))
@protocol VoicePipelineKotlinKAnnotatedElement
@required
@end


/**
 * @note annotations
 *   kotlin.SinceKotlin(version="1.1")
*/
__attribute__((swift_name("KotlinKClassifier")))
@protocol VoicePipelineKotlinKClassifier
@required
@end

__attribute__((swift_name("KotlinKClass")))
@protocol VoicePipelineKotlinKClass <VoicePipelineKotlinKDeclarationContainer, VoicePipelineKotlinKAnnotatedElement, VoicePipelineKotlinKClassifier>
@required

/**
 * @note annotations
 *   kotlin.SinceKotlin(version="1.1")
*/
- (BOOL)isInstanceValue:(id _Nullable)value __attribute__((swift_name("isInstance(value:)")));
@property (readonly) NSString * _Nullable qualifiedName __attribute__((swift_name("qualifiedName")));
@property (readonly) NSString * _Nullable simpleName __attribute__((swift_name("simpleName")));
@end

#pragma pop_macro("_Nullable_result")
#pragma clang diagnostic pop
NS_ASSUME_NONNULL_END
