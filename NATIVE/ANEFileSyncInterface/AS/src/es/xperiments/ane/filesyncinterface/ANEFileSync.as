//
//  ANEFileSync.as
//
//  Created by ANEBridgeCreator on 28/01/2013.
//  Copyright (c)2013 ANEBridgeCreator. All rights reserved.
//
package es.xperiments.ane.filesyncinterface
{
	import flash.desktop.SystemIdleMode;
	import flash.desktop.NativeApplication;				
	import flash.events.EventDispatcher;
	import flash.events.StatusEvent;
	import flash.events.Event;
	import flash.external.ExtensionContext;
	import flash.filesystem.File;
	import es.xperiments.ane.filesyncinterface.ANEFileSyncEvent;

	public class ANEFileSync extends EventDispatcher
	{
		/**
		 * Declare static context
		 */
		private static var __context:ExtensionContext = null;
		private static var _avaliableActions:Array = [
			"createDir",
			"delete",
			"rename",
			"listDir",
			"upload"
		];

		/**
		 * Declare privates
		 */
		
		 private var _directoryListingEnabled:Boolean = false;
		 private var _uploadDirectoryListingEnabled:Boolean = false;
		 private var _documentRoot:File;
		 private var _uploadDir:File;
		 private var _enabledActions:String = "";
		 private var _port:uint = 0xFFFFFF;
		 private var _isRunning:Boolean = false;
		 private var _modificationDateFormat:String = "yyyy/MM/dd HH:mm";

		/**
		 * ANEFileSync Constructor
		 */
		public function ANEFileSync( )
		{
			if ( !__context )
			{
				__context = ExtensionContext.createExtensionContext("es.xperiments.ane.filesyncinterface.ANEFileSync",null);
				__context.call('initialize');
				__context.addEventListener(StatusEvent.STATUS,onContextStatusEvent);
				setEnabledActions( _avaliableActions.join(',') );
			}
		}

		public function getInterface( ):String
		{
			return __context.call( 'getInterface' ) as String;
		};
		// PORT
		public function setPort( port:uint):void
		{
			if( _isRunning ) return;
			if( _port != port ) __context.call( 'setPort', port) ;
			_port = port;
		};
		public function getPort( ):uint
		{
			return _port;
		};


		// DOC ROOT
		public function setDocumentRoot( directory:File ):void
		{
			if( !directory.exists || !directory.isDirectory ) return;
			if( _isRunning ) return;
			_documentRoot = directory;
			__context.call( 'setDocumentRoot',directory.nativePath) ;
		};
		public function getDocumentRoot( ):File
		{
			return _documentRoot;
		};	

		// UPLOAD DIR
		public function setUploadDir( uploadDir:File ):void
		{
			if( !uploadDir.exists || !uploadDir.isDirectory ) return;
			if( _isRunning ) return;
			if( _uploadDir!=uploadDir ) __context.call( 'setUploadDir',uploadDir.nativePath) ;
			_uploadDir = uploadDir;
			
		};
		public function getUploadDir( ):File
		{
			return _uploadDir;
		};



		// MODIFICATION DATA FORMAT
		public function setModificationDateFormat( format:String ):void
		{
			if( _modificationDateFormat!=format ) __context.call( 'setModificationDateFormat', format) ;
			_modificationDateFormat = format;
			
		};
		public function getModificationDateFormat( ):String
		{
			return _modificationDateFormat;
		};

		// ACTIONS
		public function setEnabledActions( actions:String ):void
		{

			const actionsArray:Array = actions.split(',');
			const actionsOutput:Array=[];
			for( var i:uint=0, total:uint = actionsArray.length; i<total; i++ )
			{
				if( _avaliableActions.indexOf( actionsArray[i] )!=-1 ) actionsOutput.push( "/actions."+actionsArray[i] );
			}
			_enabledActions = actionsOutput.join(',');
			__context.call( 'setEnabledActions', _enabledActions ) ;
		};
		public function getEnabledActions( ):String
		{
			return _enabledActions.split('/actions.').join('');
		};

		// DIR LISTING
		public function setDirectoryListingEnabled( enabled:Boolean ):void
		{
			if( enabled!=_directoryListingEnabled ) __context.call( 'setDirectoryListingEnabled', enabled );
			_directoryListingEnabled = enabled;
			
		};
		public function getDirectoryListingEnabled( ):Boolean
		{
			return _directoryListingEnabled;
		};					

		// DIR LISTING
		public function setUploadDirectoryListingEnabled( enabled:Boolean ):void
		{
			if( enabled!=_uploadDirectoryListingEnabled ) __context.call( 'setUploadDirectoryListingEnabled', enabled );
			_uploadDirectoryListingEnabled = enabled;
			
		};
		public function getUploadDirectoryListingEnabled( ):Boolean
		{
			return _uploadDirectoryListingEnabled;
		};
	
	




		
		// START
		public function start( ):Boolean
		{
			if( _isRunning ) return true;
			if( _documentRoot==null ) return false; // we need a document root
			if( _enabledActions.indexOf('upload') !=-1 && _uploadDir==null ) return false; // if upload enabled we need an uploadDir

			if( _port == 0xFFFFFF ) setPort( 5678 ); // Default port if none specified

			const success:Boolean = __context.call( 'start') as Boolean;
			if( success )
			{
				NativeApplication.nativeApplication.systemIdleMode = SystemIdleMode.KEEP_AWAKE;
				dispatchEvent( new ANEFileSyncEvent( ANEFileSyncEvent.SERVER_STARTED, JSON.stringify({ ip:getInterface(), port:getPort() }) ) );
			}
			_isRunning = success;

			return success;
		};
		
		// STOP
		public function stop( e:Event = null ):void
		{
			if( !_isRunning ) return;
			dispatchEvent( new ANEFileSyncEvent( ANEFileSyncEvent.SERVER_STOPED  ) );
			NativeApplication.nativeApplication.systemIdleMode = SystemIdleMode.NORMAL;
			__context.call('stop');
			_isRunning = false;
		};
		

		
		/**
		 * Check if the extension is supported
		 * @return Boolean
		 */
		public static function get isSupported():Boolean
		{
			return true;
		}
		
		/**
		 * Dispose the ANEFileSync extension
		 */
		public function dispose():void
		{
			if( __context.hasEventListener(StatusEvent.STATUS) ) __context.removeEventListener(StatusEvent.STATUS,onContextStatusEvent);
			__context.dispose();
			__context = null;
		}
		
		/**
		 * Main Native Event Listener
		 */
		private function onContextStatusEvent( e:StatusEvent ):void
		{
			//dispatchEvent( new Event(Event.COMPLETE ) );
			switch( e.code )
			{
				case "createDir":
					dispatchEvent( new ANEFileSyncEvent(ANEFileSyncEvent.DIRECTORY_CREATED, e.level ) );
				break;
				case "delete":
					dispatchEvent( new ANEFileSyncEvent(ANEFileSyncEvent.FILE_DELETED, e.level ) );
				break;
				case "rename":
					dispatchEvent( new ANEFileSyncEvent(ANEFileSyncEvent.FILE_RENAMED, e.level ) );
				break;
				case "uploaded":
					dispatchEvent( new ANEFileSyncEvent(ANEFileSyncEvent.FILE_UPLOADED, e.level ) );
				break;																												
			}
		}
	}
	
}
