package es.xperiments.ane.filesyncexample
{
	import flash.desktop.NativeApplication;
	//es.xperiments.ane.anefilesync.samples.BasicHttpService
	import flash.display.Loader;
	import flash.utils.ByteArray;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.events.MouseEvent;
	import flash.display.Bitmap;
	import es.xperiments.ane.filesyncinterface.ANEFileSyncEvent;
	import flash.text.TextField;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import es.xperiments.ane.filesyncinterface.ANEFileSync;
	import flash.filesystem.File;
	import flash.events.Event;
	import flash.display.Sprite;

	/**
	 * @author xperiments
	 */
	public class ANEFileSyncExampleMain extends Sprite
	{
		private var httpServer:ANEFileSync;
		private var output:TextField;
		private var bitmap:Bitmap;

		public function ANEFileSyncExampleMain()
		{
			addEventListener(Event.ADDED_TO_STAGE, initUI);
		}

		private function initUI(event:Event):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, initUI);

			stage.scaleMode=StageScaleMode.NO_SCALE;
			stage.align=StageAlign.TOP_LEFT;

			// simple log output
			output=new TextField();
			output.width=320;
			output.height=400;
			output.border=true;
			addChild(output);


			// create a bitmap object to show image we upload to the server

			bitmap=new Bitmap();
			bitmap.visible=false;
			bitmap.addEventListener(MouseEvent.CLICK, hideUploadedBitmap);
			addChild(bitmap);
			initService();



		}


		private function initService():void
		{
			// Define server root location
			const bundleServerRoot:File=File.applicationDirectory.resolvePath('Web');
			const documentRootFile:File=File.applicationStorageDirectory.resolvePath('Web');
			bundleServerRoot.copyTo(documentRootFile, true);

			// Define server upload path inside the document root ( but it can be anywhere in the filesystem )
			const uploadDirectory:File=File.applicationStorageDirectory.resolvePath('Web/uploads');
			uploadDirectory.createDirectory();

			// initialize basic server
			httpServer=new ANEFileSync();
			httpServer.setDocumentRoot(documentRootFile); // Set document root location
			httpServer.setDirectoryListingEnabled(true); // Enable directory listing when no index.html file is found
			httpServer.setUploadDir(uploadDirectory); // Set upload file location
			httpServer.setUploadDirectoryListingEnabled(true); // enable upload directory listing, disabled by default

			/*
			 * By default all posible services are enabled
			 * Avaliable service are createDir listDir upload delete rename
			 */
			httpServer.setEnabledActions('listDir,upload'); // For this example we only enable directory listing and upload		
			
			log( httpServer.getEnabledActions() )

			// setup server events
			httpServer.addEventListener(ANEFileSyncEvent.SERVER_STARTED, onServerStarted);
			httpServer.addEventListener(ANEFileSyncEvent.FILE_UPLOADED, onServerFileUploaded);


			// setup background / exit events

			NativeApplication.nativeApplication.addEventListener(Event.EXITING, onDeactivate);
			NativeApplication.nativeApplication.addEventListener(Event.DEACTIVATE, onDeactivate);
			NativeApplication.nativeApplication.addEventListener(Event.ACTIVATE, onActivate);

			// start service
			if (!httpServer.start())
			{
				log('Unable to start server');
			}

		}

		private function onServerFileUploaded(event:ANEFileSyncEvent):void
		{
			// here we receive an event.data object with 2 properties ( path & filename )

			log(['File uploaded: ', event.data.filename].join(''));

			const imageFile:File=new File(event.data.path);
			const imageStream:FileStream=new FileStream();
			const imageByteArray:ByteArray=new ByteArray();
			imageStream.open(imageFile, FileMode.READ);
			imageStream.readBytes(imageByteArray);
			imageStream.close();

			const loader:Loader=new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function():void
			{
				bitmap.bitmapData=(loader.content as Bitmap).bitmapData;
				bitmap.visible=true;
			});
			loader.loadBytes(imageByteArray);

		}



		private function hideUploadedBitmap(event:MouseEvent):void
		{
			bitmap.visible=false;
		}

		private function onServerStarted(event:ANEFileSyncEvent):void
		{
			// here we receive an event.data object with 2 properties ( ip & port )
			log(['Server started at: http://', event.data.ip, ':', event.data.port].join(''));
		}

		private function log(string:String):void
		{
			output.appendText(string + '\n');
		}

		private function onDeactivate(e:Event):void
		{
			httpServer.stop();
		}

		private function onActivate(e:Event):void
		{
			httpServer.start();
		}


	}
}
