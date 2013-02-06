importPackage(java.lang);
importPackage(java.io);
importClass(java.util.Properties);

var buildDir;
var projectDir;
var properties;


function init( that )
{
	buildDir = project.getProperty('basedir');
	projectDir = new File(buildDir).getParent();
	properties = new Properties();
	properties.load(new FileInputStream( buildDir+"/properties/es.xperiments.fdt.compile.gui.properties" ) );


	switch( that.getOwningTarget()+'' )
	{
		case "FileSelector.updateFile":
			updateFiles();
		break;
		case "FileSelector.deleteFiles":
			deleteFiles();
		break;
	}
	
	saveSortedProperties( properties, buildDir+"/properties/es.xperiments.fdt.compile.gui.properties" );	
}


function updateFiles()
{
	var currentIncludedFiles = new Array();
	if( (properties.getProperty('es.xperiments.fdt.compile.IOS.fileselector.includedFiles')+'')!="")
	{
		currentIncludedFiles = ( project.getProperty('es.xperiments.fdt.compile.IOS.fileselector.includedFiles')+'').split(',')
	}
	if( ( project.getProperty('es.xperiments.fdt.compile.IOS.fileselector.includedFiles')+'').indexOf( ( properties.getProperty('es.xperiments.fdt.compile.IOS.fileselector.currentFile')+'') )==-1 )
	{
		currentIncludedFiles.push( properties.getProperty('es.xperiments.fdt.compile.IOS.fileselector.currentFile')+'');
	}
	
	properties.setProperty( 'es.xperiments.fdt.compile.IOS.fileselector.includedFiles', currentIncludedFiles.join(',') );
	properties.setProperty( 'es.xperiments.fdt.compile.IOS.fileselector.fileListDelete', '' );
	properties.setProperty( 'es.xperiments.fdt.compile.IOS.fileselector.currentFile', '' );

	project.setProperty( 'es.xperiments.fdt.compile.IOS.fileselector.includedFiles', currentIncludedFiles.join(',') );
	project.setProperty( 'es.xperiments.fdt.compile.IOS.fileselector.fileListDelete', '' );
	project.setProperty( 'es.xperiments.fdt.compile.IOS.fileselector.currentFile', '' );

}

function deleteFiles()
{


	var toDelete = (properties.getProperty('es.xperiments.fdt.compile.IOS.fileselector.fileListToDelete')+'').split(',');

	var currentFiles = (properties.getProperty('es.xperiments.fdt.compile.IOS.fileselector.includedFiles')+'').split(',');
	var resultFiles = new Array();
	if( toDelete.length == 0 ) return;
	for( var i=0; i<currentFiles.length; i++ )
	{

		var found = false;
		for( var e=0; e<toDelete.length; e++ )
		{
			if( currentFiles[ i ] == toDelete[e] )
			{
				found = true;
			}
		}
		if( !found )
		{
			resultFiles.push( currentFiles[ i ] );
		}
	}
	properties.setProperty( 'es.xperiments.fdt.compile.IOS.fileselector.includedFiles', resultFiles.join(',') );
	properties.setProperty( 'es.xperiments.fdt.compile.IOS.fileselector.fileListToDelete', '' );
	project.setProperty( 'es.xperiments.fdt.compile.IOS.fileselector.includedFiles', resultFiles.join(',') );
	project.setProperty( 'es.xperiments.fdt.compile.IOS.fileselector.fileListToDelete', '' );			
	
}

function saveSortedProperties( prop, filename )
{
	var outputfile = new BufferedWriter(new FileWriter( filename ));
	var sortedProps = sortProperties( prop );
	for( var i=0; i<sortedProps.length; i++ )
	{
		outputfile.write( sortedProps[i].key+'='+sortedProps[i].value );
		outputfile.newLine();
	}
	outputfile.close();			
}

function sortProperties( props )
{
	var outputArray = [];
	var propNames = props.stringPropertyNames().toString().replace('[','').replace(']','').split(', ');
	for( var i=0; i<propNames.length; i++ )
	{
		outputArray.push( { key:propNames[i], value:props.getProperty( propNames[i] ).replace('\n','\\n') } );
	}
	

	outputArray.sortOn = function($key){
		this.sort(function(a, b){
			return (a[$key] > b[$key]) - (a[$key] < b[$key]);
		});
	};

	outputArray.sortOn("key");
	return outputArray;
}
init( self );