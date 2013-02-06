importPackage(java.lang);
importPackage(java.io);
importClass(java.util.Properties);

var DescriptorLoader = (function(undefined) {
	
	var load = function( file )
	{
		var data = new String(org.apache.tools.ant.util.FileUtils.readFully(new java.io.FileReader( file )));
		if( data.indexOf('<?xml') == 0 )
		{
			var lines = data.match(/[^\r\n]+/g);
				lines.shift();
				lines.shift();
				lines.unshift('<application>');
			return new XML( lines.join('') );
		}
		else
		{
			return new XML( data );
		}
	}
	
	return {
		load:load
	};

})();

var properties;

function init( that )
{
	
	properties = new Properties();
	properties.load(new FileInputStream(  project.getProperty('basedir')+"/properties/es.xperiments.fdt.compile.gui.properties" ) );
	
	switch( that.getOwningTarget()+'' )
	{
		case "SWF.debug.killfdb":
			killFlashDebugger();
		break;
		case "SWF.autoincrementBuild":
			autoVersionNumber();
		break;
	}	
}

function killFlashDebugger()
{
	var buildDir = project.getProperty('basedir');
	var pid = new String(org.apache.tools.ant.util.FileUtils.readFully(new java.io.FileReader( new File(buildDir+'/.pid') )));
	var lines = pid.match(/[^\r\n]+/g);
	var i=0;
	for( i=0; i<lines.length; i++)
	{
		if( lines[i].indexOf('fdb.jar')!=-1)
		{
			var kill = project.createTask("exec");
			kill.setExecutable("kill");
			kill.createArg().setValue(lines[i].split(' ')[0]);
			kill.execute();
		}
	}
}


function autoVersionNumber()
{
	var descriptorFile = project.getProperty('IOS.deployer.currentFile');
	var buildDir = project.getProperty('basedir');
	var projectDir = new File(buildDir).getParent();
	var binDir = projectDir+'/bin';	
	var autoIncrementVersionNumber = getProperty('es.xperiments.fdt.compile.IOS.app.autoversionnumber') == "true";
	var file = binDir +'/'+getProperty('es.xperiments.fdt.compile.IOS.app.name')+'-app.xml';
	var descriptorTemplate = DescriptorLoader.load( file );		
	if( autoIncrementVersionNumber )
	{
		var nextVersion = getNextVersionNumber(getProperty('es.xperiments.fdt.compile.IOS.app.version'));
		descriptorTemplate.versionNumber = nextVersion;
		setProperty( 'es.xperiments.fdt.compile.IOS.app.version' , nextVersion );
		saveDescriptor( descriptorTemplate, file );
		saveSortedProperties( properties, buildDir+"/properties/es.xperiments.fdt.compile.gui.properties" )
	}
	else
	{
		descriptorTemplate.versionNumber = getProperty('es.xperiments.fdt.compile.IOS.app.version');
		saveDescriptor( descriptorTemplate, file );		
	}	
}

function getNextVersionNumber( currentVersion )
{

	var version = parseVersionString( currentVersion );
	version.patch++;
	if( version.patch == 1000 )
	{
		version.patch = 0;
		version.minor++;
	}
	if( version.minor == 1000 )
	{
		version.patch = 0;
		version.minor = 0;
		version.major++;
	}
	return [ version.major, version.minor, version.patch ].join('.');	
}
function parseVersionString (str) {

	var x = (str+'').split('.');


	// parse from string or default to 0 if can't parse
	var maj = parseInt(x[0]);
	var min = parseInt(x[1]);
	var pat = parseInt(x[2]);
	return {
		major: maj,
		minor: min,
		patch: pat
	}
}

function saveDescriptor( descriptorXML, destinationFile )
{
	var outputfile = new BufferedWriter(new FileWriter( destinationFile ));

	var descriptorArray = (descriptorXML+'').split('\n');
		descriptorArray.shift();
		descriptorArray.unshift('<application xmlns="http://ns.adobe.com/air/application/'+getProperty('es.xperiments.fdt.compile.IOS.app.namespace')+'">');
		descriptorArray.unshift('<?xml version="1.0" encoding="utf-8" ?>');

	var finalString = descriptorArray.join('\n').replace(/&lt;/g,'<').replace(/&gt;/g,'>');
	outputfile.write( finalString );
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


function getProperty( name )
{
	return properties.getProperty( name )+'';
}
function setProperty( name , value )
{
	properties.setProperty( name, value );
}
init( self );

