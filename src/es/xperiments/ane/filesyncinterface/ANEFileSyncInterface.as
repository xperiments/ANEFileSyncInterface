package es.xperiments.ane.filesyncinterface
{


	public class ANEFileSyncInterface
	{

		[ANEmbed(arguments="port")]
		public function setPort( port:uint = 12345 )
		{
		

		}

		
		public function stop():void
		{
			
		}

		public function start():void
		{
			
		}
		[ANEmbed(arguments="template")]
		public function setListDisplayItemTemplate(template:String):void
		{
		}

		[ANEmbed(arguments="enabled")]
		public function setDirectoryListingEnabled(boolean:Boolean):void
		{
		}

		[ANEmbed(arguments="directory")]
		public function setUploadDir(string:String):void
		{
		}

		[ANEmbed(arguments="directory")]
		public function setDocumentRoot(string:String):void
		{
		}


	}
}
