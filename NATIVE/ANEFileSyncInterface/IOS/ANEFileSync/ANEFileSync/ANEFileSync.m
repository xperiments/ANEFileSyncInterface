//
//  ANEFileSync.m
//  ANEFileSync
//
//  Created by ANEBridgeCreator on 28/01/2013.
//  Copyright (c)2013 ANEBridgeCreator. All rights reserved.
//

#import "FlashRuntimeExtensions.h"
#import "HTTPServer.h"
#import "FileSyncConnection.h"

#define DEFINE_ANE_FUNCTION(fn) FREObject (fn)(FREContext context, void* functionData, uint32_t argc, FREObject argv[])
#define DISPATCH_STATUS_EVENT(extensionContext, code, status) FREDispatchStatusEventAsync((extensionContext), (uint8_t*)code, (uint8_t*)status)
#define MAP_FUNCTION(fn, data) { (const uint8_t*)(#fn), (data), &(fn) }

#define ASSERT_ARGC_IS(fn_name, required)																	\
if(argc != (required))																						\
{																											\
DISPATCH_INTERNAL_ERROR(context, #fn_name ": Wrong number of arguments. Expected exactly " #required);	\
return NULL;																							\
}
#define ASSERT_ARGC_AT_LEAST(fn_name, required)																\
if(argc < (required))																						\
{																											\
DISPATCH_INTERNAL_ERROR(context, #fn_name ": Wrong number of arguments. Expected at least " #required);	\
return NULL;																							\
}

HTTPServer* httpServer;



/****************************************************************************************
 *																						*
 *	METHODS BRIDGED																		*
 *																						*
 ****************************************************************************************/


/****************************************************************************************
 * @method:setDocumentRoot( directory:String):void
 ****************************************************************************************/
DEFINE_ANE_FUNCTION( setEnabledActions )
{
	
    
	//  directory:String = argument[0];
    
	uint32_t actionsLength;
	const uint8_t *actions_CString;
	FREGetObjectAsUTF8(argv[0], &actionsLength, &actions_CString);
	NSString *actions = [NSString stringWithUTF8String:(char*)actions_CString];
	
    [FileSyncConnection setEnabledActions:actions ];
    
	return NULL;
}



/****************************************************************************************
 * @method:setDirectoryListingEnabled( enabled:Boolean):void
 ****************************************************************************************/
DEFINE_ANE_FUNCTION( setDirectoryListingEnabled )
{
	
	//  enabled:Boolean = argument[0];
    
	uint32_t enabled_C;
	if( FREGetObjectAsBool(argv[0], &enabled_C) != FRE_OK ) return NULL;
	
    [FileSyncConnection setDirectoryListingEnabled:enabled_C ];
    
	return NULL;
}
/****************************************************************************************
 * @method:setUploadDirectoryListingEnabled( enabled:Boolean):void
 ****************************************************************************************/
DEFINE_ANE_FUNCTION( setUploadDirectoryListingEnabled )
{
	
	uint32_t enabled_C;
	if( FREGetObjectAsBool(argv[0], &enabled_C) != FRE_OK ) return NULL;
	
    [FileSyncConnection setUploadDirectoryListingEnabled:enabled_C ];
    
	return NULL;
}

/****************************************************************************************
 * @method:setDocumentRoot( directory:String):void
 ****************************************************************************************/
DEFINE_ANE_FUNCTION( setDocumentRoot )
{
	
    
	//  directory:String = argument[0];
    
	uint32_t directoryLength;
	const uint8_t *directory_CString;
	FREGetObjectAsUTF8(argv[0], &directoryLength, &directory_CString);
	NSString *directory = [NSString stringWithUTF8String:(char*)directory_CString];
	
    [httpServer setDocumentRoot:directory];
    
	return NULL;
}





/****************************************************************************************
 * @method:setPort( port:uint):void
 ****************************************************************************************/
DEFINE_ANE_FUNCTION( setPort )
{
	
    
    
	//  port:uint = argument[0];
    
	int32_t port_C;
	if( FREGetObjectAsInt32(argv[0], &port_C) != FRE_OK ) return NULL;
	
    [httpServer setPort:port_C];
    
	return NULL;
}


/****************************************************************************************
 * @method:setUploadDir( directory:String):void
 ****************************************************************************************/
DEFINE_ANE_FUNCTION( setUploadDir )
{
	
	//  directory:String = argument[0];
    
	uint32_t directoryLength;
	const uint8_t *directory_CString;
	FREGetObjectAsUTF8(argv[0], &directoryLength, &directory_CString);
	NSString *directory = [NSString stringWithUTF8String:(char*)directory_CString];
	
    [FileSyncConnection setUploadDir:directory ];
    
	return NULL;
}


/****************************************************************************************
 * @method:setUploadDir( directory:String):void
 ****************************************************************************************/
DEFINE_ANE_FUNCTION( setModificationDateFormat )
{
	
	//  directory:String = argument[0];
    
	uint32_t formatLength;
	const uint8_t *format_CString;
	FREGetObjectAsUTF8(argv[0], &formatLength, &format_CString);
	NSString *format = [NSString stringWithUTF8String:(char*)format_CString];
	
    [FileSyncConnection setModificationDateFormat:format ];
    
	return NULL;
}


/****************************************************************************************
 * @method:setUploadDir( directory:String):void
 ****************************************************************************************/
DEFINE_ANE_FUNCTION( getInterface )
{
	
    NSString *interface = [FileSyncConnection getIPAddress];
    
    
    const char *interfaceChar = [interface UTF8String];
    
    FREObject result;
    FRENewObjectFromUTF8(strlen(interfaceChar)+1, (const uint8_t*)interfaceChar, &result);
	return result;
}

/****************************************************************************************
 * @method:start( ):void
 ****************************************************************************************/
DEFINE_ANE_FUNCTION( initialize )
{
    
    httpServer = [[HTTPServer alloc] init];
	[httpServer setType:@"_http._tcp."];
	[httpServer setConnectionClass:[FileSyncConnection class]];
    [FileSyncConnection setContext:context ];
	return NULL;
}

/****************************************************************************************
 * @method:start( ):void
 ****************************************************************************************/
DEFINE_ANE_FUNCTION( start )
{
	
    NSError *error;
    uint32_t success = [httpServer start:&error];
    
    FREObject result;
    FRENewObjectFromBool(success, &result );
	return result;
}


/****************************************************************************************
 * @method:stop( ):void
 ****************************************************************************************/
DEFINE_ANE_FUNCTION( stop )
{
	[httpServer stop];
	return NULL;
}


/****************************************************************************************
 *																						*
 *	EXTENSION & CONTEXT																	*
 *																						*
 ****************************************************************************************/

void ANEFileSyncContextInitializer( void* extData, const uint8_t* ctxType, FREContext ctx, uint32_t* numFunctionsToSet, const FRENamedFunction** functionsToSet )
{

	static FRENamedFunction functionMap[] = {
		// METHODS
		MAP_FUNCTION( setDirectoryListingEnabled, NULL ),
        MAP_FUNCTION( setUploadDirectoryListingEnabled, NULL ),
		MAP_FUNCTION( setDocumentRoot, NULL ),
		MAP_FUNCTION( setPort, NULL ),
		MAP_FUNCTION( setUploadDir, NULL ),
		MAP_FUNCTION( start, NULL ),
		MAP_FUNCTION( stop, NULL ),
        MAP_FUNCTION( initialize, NULL ),
        MAP_FUNCTION( setEnabledActions, NULL ),
        MAP_FUNCTION( setModificationDateFormat, NULL ),
        MAP_FUNCTION( getInterface, NULL )
        
	};
    
	*numFunctionsToSet = sizeof( functionMap ) / sizeof( FRENamedFunction );
	*functionsToSet = functionMap;
}
void ANEFileSyncContextFinalizer( FREContext ctx )
{
	NSLog(@"Entering ANEFileSyncContextFinalizer()");
	NSLog(@"Exiting ANEFileSyncContextFinalizer()");
    
	return;
}
void ANEFileSyncExtensionInitializer( void** extDataToSet, FREContextInitializer* ctxInitializerToSet, FREContextFinalizer* ctxFinalizerToSet )
{
	NSLog(@"Entering ANEFileSyncExtensionInitializer()");
	extDataToSet = NULL;  // This example does not use any extension data.
	*ctxInitializerToSet = &ANEFileSyncContextInitializer;
	*ctxFinalizerToSet = &ANEFileSyncContextFinalizer;
}
void ANEFileSyncExtensionFinalizer()
{
	NSLog(@"Entering ANEFileSyncExtensionFinalizer()");
	return;
}
