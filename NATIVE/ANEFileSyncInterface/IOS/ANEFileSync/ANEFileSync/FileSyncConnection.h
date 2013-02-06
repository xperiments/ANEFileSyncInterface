
#import "HTTPConnection.h"
#import "FlashRuntimeExtensions.h"
#import "MultipartMessageHeader.h"
@class MultipartFormDataParser;

@interface FileSyncConnection : HTTPConnection  {
    MultipartFormDataParser*        parser;
	NSFileHandle*					storeFile;
    NSString*                       uploadPath;
    NSString*                       currentUploadFilePath;

}
// CLASS

+(void)setEnabledActions:(NSString*)actions;
+(void)setContext:(FREContext)context;
+(void)setUploadDir:(NSString*)dir;
+(NSString*)getUploadDir;
+(void)setDirectoryListingEnabled:(BOOL)enabled;
+(BOOL)getDirectoryListingEnabled;
+(void)setUploadDirectoryListingEnabled:(BOOL)enabled;
+(BOOL)getUploadDirectoryListingEnabled;
+(NSString *)getIPAddress;
+(NSString*)getJSONFromDict:(NSDictionary*) dict;
+(NSString*)getJSONFromArray:(NSMutableArray*) array;
+(void)dispatchFlashEvent:(NSString*) event withDictionary:(NSDictionary*) dictionary;
+(NSString*)getFileSize:(NSString*)path;
+(NSArray*)getDirectoryContents:(NSString*)path;
+(void)setModificationDateFormat:(NSString*)format;

-(BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path;
-(BOOL)expectsRequestBodyFromMethod:(NSString *)method atPath:(NSString *)path;
-(NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path;
-(NSObject<HTTPResponse> *)processAction;
-(NSMutableDictionary*)parseQueryStringWithExpectedNumParams:(NSUInteger)expected;
-(NSObject<HTTPResponse> *)get404;
-(NSObject<HTTPResponse> *)getActionResultForAction:(NSString*)action withResult:(BOOL)result;
-(BOOL)fileExistAtPath:(NSString*)path;
-(BOOL)fileIsDir:(NSString*)path;
-(NSString*)getRootPathForFile:(NSString*)path;
-(NSString*)getTemplatePathForFile:(NSString*)path;
-(NSDictionary*)getDirectoryListing:(NSString*)dirFile basePath:(NSString*)basePath;
-(NSString*)getDirectoryJSON:(NSString*)dirFile basePath:(NSString*)basePath;
-(void)prepareForBodyWithSize:(UInt64)contentLength;
-(void)processBodyData:(NSData *)postDataChunk;
-(void)processStartOfPartWithHeader:(MultipartMessageHeader*) header;
-(void)processContent:(NSData*) data WithHeader:(MultipartMessageHeader*) header;
-(void)processEndOfPartWithHeader:(MultipartMessageHeader*) header;
-(void) processPreambleData:(NSData*) data;
-(void) processEpilogueData:(NSData*) data;

@end
