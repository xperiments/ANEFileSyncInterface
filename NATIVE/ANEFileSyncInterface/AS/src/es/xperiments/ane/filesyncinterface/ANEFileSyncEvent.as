package es.xperiments.ane.filesyncinterface
{

	import flash.events.Event;

	public class ANEFileSyncEvent extends Event
	{
		public var data:Object;
		public static const FILE_UPLOADED:String="FILE_UPLOADED";
		public static const FILE_DELETED:String="FILE_DELETED";
		public static const FILE_RENAMED:String="FILE_RENAMED";
		public static const DIRECTORY_CREATED:String="DIRECTORY_CREATED";
		public static const SERVER_STARTED:String="SERVER_STARTED";
		public static const SERVER_STOPED:String="SERVER_STOPED";
		public function ANEFileSyncEvent(type:String, eventData:String ="{}", bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			data = JSON.parse( eventData );
		}
	
	}
	
}
