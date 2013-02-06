
#import "FileSyncConnection.h"
#import "HTTPMessage.h"
#import "HTTPDataResponse.h"
#import "DDNumber.h"
#import "HTTPLogging.h"

#import "MultipartFormDataParser.h"
#import "MultipartMessageHeaderField.h"
#import "HTTPDynamicFileResponse.h"
#import "HTTPFileResponse.h"
#import "FlashRuntimeExtensions.h"

#import "GRMustache.h"


#import <ifaddrs.h>
#import <arpa/inet.h>


// Log levels : off, error, warn, info, verbose
// Other flags: trace
static const int httpLogLevel = HTTP_LOG_LEVEL_VERBOSE; // | HTTP_LOG_FLAG_TRACE;
static NSString* uploadDir = nil;
static NSString* modificationDateFormat = @"yyyy/MM/dd HH:mm";
static BOOL isDirectoryListingEnabled = FALSE;
static BOOL isUploadDirectoryListingEnabled = FALSE;
static NSMutableArray* enabledActions;
static FREContext ctx;


/**
 * All we have to do is override appropriate methods in HTTPConnection.
 **/

@implementation FileSyncConnection



// STATIC METHODS

/* SET STATIC UPLOAD DIR*/
+(void)setModificationDateFormat:(NSString*)format
{
    modificationDateFormat = format;
}


/* SET STATIC UPLOAD DIR*/
+(void)setEnabledActions:(NSString*)actions
{
    enabledActions = [[NSMutableArray alloc] initWithArray:[actions componentsSeparatedByString:@","] ];
}

/* SET STATIC UPLOAD DIR*/
+(void)setContext:(FREContext)context
{
    ctx = context;
}

/* SET STATIC UPLOAD DIR*/
+(void)setUploadDir:(NSString*)dir
{
    if (uploadDir == nil)
    {
        uploadDir = [[NSString alloc] init];
    }
    uploadDir = dir;
}
/* GET STATIC UPLOAD DIR*/
+(NSString*)getUploadDir
{
    return uploadDir;
    
}
/* ENABLE / DISABLE DIRECTORY LISTING*/
+(void)setDirectoryListingEnabled:(BOOL)enabled
{
    isDirectoryListingEnabled = enabled;
}

/* GET DIRECTORY LISTING STATUS */
+(BOOL)getDirectoryListingEnabled
{
    return isDirectoryListingEnabled;
}


/* ENABLE / DISABLE DIRECTORY LISTING*/
+(void)setUploadDirectoryListingEnabled:(BOOL)enabled
{
    isUploadDirectoryListingEnabled = enabled;
}
/* GET DIRECTORY LISTING STATUS */
+(BOOL)getUploadDirectoryListingEnabled
{
    return isUploadDirectoryListingEnabled;
}


+(NSString *)getIPAddress
{
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    NSString *wifiAddress = nil;
    NSString *cellAddress = nil;
    
    // retrieve the current interfaces - returns 0 on success
    if(!getifaddrs(&interfaces)) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            sa_family_t sa_type = temp_addr->ifa_addr->sa_family;
            if(sa_type == AF_INET || sa_type == AF_INET6) {
                NSString *name = [NSString stringWithUTF8String:temp_addr->ifa_name];
                NSString *addr = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)]; // pdp_ip0
                NSLog(@"NAME: \"%@\" addr: %@", name, addr); // see for yourself
                
                if([name isEqualToString:@"en0"]) {
                    // Interface is the wifi connection on the iPhone
                    wifiAddress = addr;
                } else
                    if([name isEqualToString:@"pdp_ip0"]) {
                        // Interface is the cell connection on the iPhone
                        cellAddress = addr;
                    }
            }
            temp_addr = temp_addr->ifa_next;
        }
        // Free memory
        freeifaddrs(interfaces);
    }
    NSString *addr = wifiAddress ? wifiAddress : cellAddress;
    return addr ? addr : @"0.0.0.0";
}

+(NSString*)getJSONFromDict:(NSDictionary*) dict
{
    NSData* encodedData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:nil];
    return [[NSString alloc] initWithData:encodedData encoding:NSUTF8StringEncoding];
}
+(NSString*)getJSONFromArray:(NSMutableArray*) array
{
    NSData* encodedData = [NSJSONSerialization dataWithJSONObject:array options:0 error:nil];
    return [[NSString alloc] initWithData:encodedData encoding:NSUTF8StringEncoding];
}

+(void)dispatchFlashEvent:(NSString*) event withDictionary:(NSDictionary*) dictionary
{
    FREDispatchStatusEventAsync(ctx, (const uint8_t*)[event UTF8String], (const uint8_t*)[ [FileSyncConnection getJSONFromDict:dictionary] UTF8String ] );
}

+(NSString*)getFileSize:(NSString*)path
{
    NSString *fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:path error: NULL] objectForKey:NSFileSize];
    return fileSize;
}
+(NSArray*)getDirectoryContents:(NSString*)path
{
    return [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
}


// INSTANCE METHODS

- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path
{
	HTTPLogTrace();
	
	// Add support for POST
	
	if ([method isEqualToString:@"POST"])
	{
		if ([path isEqualToString:@"/actions.upload"])
		{
            uploadPath =@"";
            return [enabledActions containsObject: @"/actions.upload"] ? YES:NO;
		}
	}
	
	return [super supportsMethod:method atPath:path];
}

- (BOOL)expectsRequestBodyFromMethod:(NSString *)method atPath:(NSString *)path
{
	HTTPLogTrace();
	
	// Inform HTTP server that we expect a body to accompany a POST request
	
	if([method isEqualToString:@"POST"] && [path isEqualToString:@"/actions.upload"] && [enabledActions containsObject: @"/actions.upload"]) {
        // here we need to make sure, boundary is set in header
        NSString* contentType = [request headerField:@"Content-Type"];
        int paramsSeparator = [contentType rangeOfString:@";"].location;
        if( NSNotFound == paramsSeparator ) {
            return NO;
        }
        if( paramsSeparator >= contentType.length - 1 ) {
            return NO;
        }
        NSString* type = [contentType substringToIndex:paramsSeparator];
        if( ![type isEqualToString:@"multipart/form-data"] ) {
            // we expect multipart/form-data content type
            return NO;
        }
        
		// enumerate all params in content-type, and find boundary there
        NSArray* params = [[contentType substringFromIndex:paramsSeparator + 1] componentsSeparatedByString:@";"];
        for( NSString* param in params ) {
            paramsSeparator = [param rangeOfString:@"="].location;
            if( (NSNotFound == paramsSeparator) || paramsSeparator >= param.length - 1 ) {
                continue;
            }
            NSString* paramName = [param substringWithRange:NSMakeRange(1, paramsSeparator-1)];
            NSString* paramValue = [param substringFromIndex:paramsSeparator+1];
            
            if( [paramName isEqualToString: @"boundary"] ) {
                // let's separate the boundary from content-type, to make it more handy to handle
                [request setHeaderField:@"boundary" value:paramValue];
            }
        }
        // check if boundary specified
        if( nil == [request headerField:@"boundary"] )  {
            return NO;
        }
        return YES;
    }
	return [super expectsRequestBodyFromMethod:method atPath:path];
}



- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
    
    // Accion se produce despues upload
	if ([method isEqualToString:@"POST"] && [path isEqualToString:@"/actions.upload"])
	{
        return [self getActionResultForAction:path withResult:[enabledActions containsObject: @"/actions.upload"]];
	}
    
	if ([method isEqualToString:@"GET"] )
	{
        
        if([path hasPrefix:@"/actions"])
        {
            return [self processAction];
        }
        
        if([path isEqualToString:@"/___templates___"])
        {
            return [self get404];
        }
        
        if( [[[config documentRoot] stringByAppendingPathComponent:path] isEqualToString:uploadDir] && !isUploadDirectoryListingEnabled )
        {
            return [self get404];
        };
		
        NSString* webServiceDir = [config documentRoot];
        
        NSString* requestFilePath =[[NSString alloc] init];
        requestFilePath = [requestFilePath stringByAppendingString:webServiceDir];
        requestFilePath = [requestFilePath stringByAppendingString:path];
        
        
        // FILE EXIST
        if( [self fileExistAtPath: requestFilePath] )
        {
            // IS DIR?
            if( [self fileIsDir:requestFilePath] )
            {
                NSString* indexFile = [requestFilePath stringByAppendingPathComponent:@"index.html"];
                // NO HAS INDEX FILE
                if(![self fileExistAtPath: indexFile] )
                {
                    if( [FileSyncConnection getDirectoryListingEnabled] )
                    {
                        NSDictionary* fileMustacheData = [self getDirectoryListing:requestFilePath basePath:path ];
                        GRMustacheTemplate *template = [GRMustacheTemplate templateFromContentsOfFile:[self getTemplatePathForFile:@"dir.html"] error:NULL];
                        NSString* templateOutput = [template renderObject:fileMustacheData error:NULL];
                        return [ [HTTPDataResponse alloc]  initWithData:[templateOutput dataUsingEncoding:NSUTF8StringEncoding] ];
                    }
                    else
                    {
                        return [self get404];
                    }
                }
                // HAS INDEX FILE
                else
                {
                    return [super httpResponseForMethod:method URI:path];
                }
            }
            // SERVE FILE
            else
            {
                return [super httpResponseForMethod:method URI:path];
            }
        }
        // SHOW ERROR
        else
        {
            return [self get404];
        }
    }
	return [super httpResponseForMethod:method URI:path];
}


- (NSObject<HTTPResponse> *)processAction
{
    
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSString* action = [[request url ] path];
    NSError* error;
    BOOL actionSuccess = FALSE;
    
    
    NSMutableDictionary *queryObject;
    
    if( ![enabledActions containsObject: action] )
    {
        return [self getActionResultForAction:action withResult:actionSuccess];
    }
    
    if( [action isEqualToString:@"/actions.createDir"] )
    {
        
        queryObject = [self parseQueryStringWithExpectedNumParams:1];
        if( queryObject == nil )
        {
            return [self get404];
        }
        
        NSString* newDirectory = [[config documentRoot] stringByAppendingPathComponent:[queryObject objectForKey:@"dir"] ];
        actionSuccess = [fileManager
                         createDirectoryAtPath:newDirectory
                         withIntermediateDirectories:YES
                         attributes:nil
                         error:&error];
        
        
        NSDictionary* eventData = [NSDictionary dictionaryWithObjectsAndKeys:
                                   newDirectory, @"path",
                                   [NSNumber numberWithBool:actionSuccess], @"result"
                                   , nil];
        
        [FileSyncConnection dispatchFlashEvent:@"createDir" withDictionary:eventData ];
        
        return [self getActionResultForAction:action withResult:actionSuccess];
    }
    
    if( [action isEqualToString:@"/actions.delete"] )
    {
        queryObject = [self parseQueryStringWithExpectedNumParams:1];
        if( queryObject == nil )
        {
            return [self get404];
        }
        NSString* fileToDelete = [[config documentRoot] stringByAppendingPathComponent:[queryObject objectForKey:@"file"]];
        actionSuccess = [fileManager removeItemAtPath:fileToDelete error:&error];
        
        
        NSDictionary* eventData = [NSDictionary dictionaryWithObjectsAndKeys:
                                   fileToDelete, @"path",
                                   [NSNumber numberWithBool:actionSuccess], @"result"
                                   , nil];
        
        [FileSyncConnection dispatchFlashEvent:@"delete" withDictionary:eventData ];
        
        return [self getActionResultForAction:action withResult:actionSuccess];
    }
    
    if( [action isEqualToString:@"/actions.rename"] )
    {
        queryObject = [self parseQueryStringWithExpectedNumParams:2];
        if( queryObject == nil )
        {
            return [self get404];
        }
        
        NSString *fromFile = [[config documentRoot] stringByAppendingPathComponent:[queryObject objectForKey:@"from"]];
        NSString *toFile = [[config documentRoot] stringByAppendingPathComponent:[queryObject objectForKey:@"to"]];
        actionSuccess = [fileManager
                         moveItemAtPath:fromFile
                         toPath:toFile
                         error:&error];
        
        
        NSDictionary* eventData = [NSDictionary dictionaryWithObjectsAndKeys:
                                   fromFile, @"from",
                                   toFile, @"to",
                                   [NSNumber numberWithBool:actionSuccess], @"result"
                                   , nil];
        
        [FileSyncConnection dispatchFlashEvent:@"rename" withDictionary:eventData ];
        
        return [self getActionResultForAction:action withResult:actionSuccess];
    }
    
    if( [action isEqualToString:@"/actions.listDir"] )
    {
        queryObject = [self parseQueryStringWithExpectedNumParams:1];
        if( queryObject == nil )
        {
            return [self get404];
        }
        
        NSString* listDir = [queryObject objectForKey:@"dir"];
        
        return [[HTTPDataResponse alloc] initWithData:[[self getDirectoryJSON:[[config documentRoot] stringByAppendingString:listDir] basePath:listDir] dataUsingEncoding:NSUTF8StringEncoding] ];
        
    }
    
    return [self get404];
}

-(NSMutableDictionary*)parseQueryStringWithExpectedNumParams:(NSUInteger)expected
{
    NSString* query = [[ request url ] query];
    query = [query stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    if( [query length] == 0 )
    {
        return nil;
    }
    
    NSArray *components = [query componentsSeparatedByString:@"&"];
    if( expected != [components count] )
    {
        return nil;
    }
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    for (NSString *component in components)
    {
        [parameters setObject:[[component componentsSeparatedByString:@"="] objectAtIndex:1] forKey:[[component componentsSeparatedByString:@"="] objectAtIndex:0]];
    }
    return parameters;
}



- (NSObject<HTTPResponse> *)get404
{
    NSString* templatePath = [self getTemplatePathForFile:@"404.html"];
    return [[HTTPDynamicFileResponse alloc] initWithFilePath:templatePath forConnection:self separator:@"%" replacementDictionary:nil];
}

- (NSObject<HTTPResponse> *)getActionResultForAction:(NSString*)action withResult:(BOOL)result
{
    NSDictionary* resultData = [NSDictionary dictionaryWithObjectsAndKeys:
                                action, @"action",
                                [NSNumber numberWithBool:result],    @"result",
                                nil];
    return [ [HTTPDataResponse alloc]  initWithData:[[FileSyncConnection getJSONFromDict:resultData] dataUsingEncoding:NSUTF8StringEncoding] ];
}



-(BOOL)fileExistAtPath:(NSString*)path
{
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}
-(BOOL)fileIsDir:(NSString*)path
{
    return [[[[NSFileManager defaultManager] attributesOfItemAtPath:path error: NULL] objectForKey: NSFileType] isEqualToString:@"NSFileTypeDirectory"];
}

-(NSString*)getFileModificationDate:(NSString*)path
{
    NSDictionary* fileAttribs = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
    NSDate *fileDate = [fileAttribs fileModificationDate]; //or fileModificationDate // fileCreationDate
    
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:modificationDateFormat];
    
    return [format stringFromDate:fileDate];
}

-(NSString*)getPrettySize:(NSString*)size
{
    int intSize = [size intValue];
    float floatSize = intSize;
    
    if (intSize<1023) return([NSString stringWithFormat:@"%i bytes",intSize]);
    floatSize = floatSize / 1024;
    if (floatSize<1023) return([NSString stringWithFormat:@"%1.1f KB",floatSize]);
    floatSize = floatSize / 1024;
    if (floatSize<1023) return([NSString stringWithFormat:@"%1.1f MB",floatSize]);
    floatSize = floatSize / 1024;
    return([NSString stringWithFormat:@"%1.1f GB",floatSize]);
}

-(NSString*)getRootPathForFile:(NSString*)path
{
    return [[config documentRoot] stringByAppendingPathComponent:path];
}

-(NSString*)getTemplatePathForFile:(NSString*)path
{
    return [[[config documentRoot] stringByAppendingPathComponent:@"___templates___"] stringByAppendingPathComponent:path];
}


-(NSDictionary*)getDirectoryListing:(NSString*)dirFile basePath:(NSString*)basePath
{
    
    NSArray* fileList = [FileSyncConnection getDirectoryContents:dirFile];
    NSMutableArray* mustacheElements = [[NSMutableArray alloc] init ];
    
    if( ![basePath isEqualToString:@"/"] )
    {
        basePath = [ basePath stringByAppendingString:@"/"];
    }
    for( NSString* filePathDir in fileList )
    {
        
        if( ![filePathDir isEqualToString:@"___templates___"] && !( [[[config documentRoot] stringByAppendingPathComponent:filePathDir] isEqualToString:uploadDir] && !isUploadDirectoryListingEnabled ) )
        {
            
            NSString* currentPath = [[config documentRoot] stringByAppendingString:[basePath stringByAppendingString:filePathDir]];
            BOOL isDir = [self fileIsDir:currentPath];
            NSString* fileSize = [FileSyncConnection getFileSize:currentPath];
            
            
            id fileData = @{
            @"path" : [basePath stringByAppendingString:filePathDir],
            @"name" : [filePathDir lastPathComponent],
            @"type" : isDir ? @"dir":@"file",
            @"size" : [self getPrettySize:fileSize],
            @"modification":[self getFileModificationDate: currentPath]
            };
            
            [mustacheElements addObject:fileData];
            
        }
    }
    
    
    return @{ @"files":mustacheElements,@"parent":[basePath stringByDeletingLastPathComponent] };
    
}





-(NSString*)getDirectoryJSON:(NSString*)dirFile basePath:(NSString*)basePath
{
    
    if( ![self fileExistAtPath: dirFile] )
    {
        return [FileSyncConnection getJSONFromDict:[NSDictionary dictionaryWithObjectsAndKeys:@"notfound", @"error", nil] ];
    }
    
    NSArray* fileList = [FileSyncConnection getDirectoryContents:dirFile];
    NSString* directoryContents;
    NSMutableArray* jsonArray = [[NSMutableArray alloc] init];
    
    if( ![basePath isEqualToString:@"/"] )
    {
        basePath = [ basePath stringByAppendingString:@"/"];
    }
    for( NSString* filePathDir in fileList )
    {
        if( ![filePathDir isEqualToString:@"___templates___"] && !( [[[config documentRoot] stringByAppendingPathComponent:filePathDir] isEqualToString:uploadDir] && !isUploadDirectoryListingEnabled ) )
        {
            
            NSString* currentPath = [[config documentRoot] stringByAppendingString:[basePath stringByAppendingString:filePathDir]];
            BOOL isDir = [self fileIsDir:currentPath];
            NSString* fileSize = [FileSyncConnection getFileSize:currentPath];
            
            NSDictionary* currentFileData = [NSDictionary dictionaryWithObjectsAndKeys:
                                             [basePath stringByAppendingString:filePathDir], @"name",
                                             [NSNumber numberWithBool:isDir],    @"isDir",
                                             fileSize,    @"size",
                                             nil];
            
            [jsonArray addObject:currentFileData];
            
        }
    }
    
    if( [jsonArray count] == 0 )
    {
        return [FileSyncConnection getJSONFromDict:[NSDictionary dictionaryWithObjectsAndKeys:@"emptydir", @"error", nil] ];
    }
    
    directoryContents = [FileSyncConnection getJSONFromArray:jsonArray];
    
    return directoryContents;
    
}

- (void)prepareForBodyWithSize:(UInt64)contentLength
{
	HTTPLogTrace();
	
	// set up mime parser
    NSString* boundary = [request headerField:@"boundary"];
    parser = [[MultipartFormDataParser alloc] initWithBoundary:boundary formEncoding:NSUTF8StringEncoding];
    parser.delegate = self;
    
    
}

- (void)processBodyData:(NSData *)postDataChunk
{
	HTTPLogTrace();
    // append data to the parser. It will invoke callbacks to let us handle
    // parsed data.
    [parser appendData:postDataChunk];
}


//-----------------------------------------------------------------
#pragma mark multipart form data parser delegate


- (void) processStartOfPartWithHeader:(MultipartMessageHeader*) header {
	// in this sample, we are not interested in parts, other then file parts.
	// check content disposition to find out filename
    
    MultipartMessageHeaderField* disposition = [header.fields objectForKey:@"Content-Disposition"];
	NSString* filename = [[disposition.params objectForKey:@"filename"] lastPathComponent];
    NSString* fieldName = [[disposition.params objectForKey:@"name"] lastPathComponent];
    
    
    // HAVE UPLOAD DIR PARAMS?
    NSRange isRange = [fieldName rangeOfString:@"uploadTo:" options:NSCaseInsensitiveSearch];
    NSString *subString;
    
    if( isRange.location != NSNotFound )
    {
        subString = [fieldName substringFromIndex:isRange.location + 9 ];
        subString = [subString stringByReplacingOccurrencesOfString:@"|" withString:@"/"];
        uploadPath = subString;
        
    }
    
    if ( (nil == filename) || [filename isEqualToString: @""] ) {
        // it's either not a file part, or
		// an empty form sent. we won't handle it.
		if( [uploadPath isEqualToString:@""] ) return;
	}
    
    
    NSString* filePath;
    NSString* fileDirPath;
    if( ![uploadPath isEqualToString:@""])
    {
        fileDirPath = [[FileSyncConnection getUploadDir] stringByAppendingPathComponent: uploadPath];
        filePath = [fileDirPath stringByAppendingPathComponent: filename];
        
        if( ![[NSFileManager defaultManager] fileExistsAtPath:fileDirPath] )
        {
            NSError * error = nil;
            [[NSFileManager defaultManager] createDirectoryAtPath:fileDirPath withIntermediateDirectories:YES attributes:nil error:&error];
        }
    }
    else
    {
        filePath = [[FileSyncConnection getUploadDir] stringByAppendingPathComponent: filename];
    }
    /*
     if( [[NSFileManager defaultManager] fileExistsAtPath:filePath] ) {
     storeFile = nil;
     }
     else
     {*/
    [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
    currentUploadFilePath = filePath;
    storeFile = [NSFileHandle fileHandleForWritingAtPath:filePath];
    uploadPath=@"";
    /*
     }*/
}


- (void) processContent:(NSData*) data WithHeader:(MultipartMessageHeader*) header
{
	// here we just write the output from parser to the file.
	if( storeFile ) {
		[storeFile writeData:data];
	}
}

- (void) processEndOfPartWithHeader:(MultipartMessageHeader*) header
{
	// as the file part is over, we close the file.
	[storeFile closeFile];
	
    if( ![currentUploadFilePath isEqualToString:@""] )    {
        
        
        NSDictionary* fileData = [NSDictionary dictionaryWithObjectsAndKeys:
                                  currentUploadFilePath, @"path",
                                  [currentUploadFilePath lastPathComponent], @"filename"
                                  , nil];
        
        [FileSyncConnection dispatchFlashEvent:@"uploaded" withDictionary:fileData ];
        
    }
    currentUploadFilePath=@"";
    storeFile = nil;
}

- (void) processPreambleData:(NSData*) data
{
    // if we are interested in preamble data, we could process it here.
    
}

- (void) processEpilogueData:(NSData*) data 
{
    // if we are interested in epilogue data, we could process it here.
    
}




@end
