importPackage(java.lang);
importPackage(java.io);
importPackage(java.util.zip);
importClass(java.util.Properties);
importClass(java.util.Scanner);


var XMLLoader = (function(undefined) {
	
	var load = function( file )
	{
		var data = new String(org.apache.tools.ant.util.FileUtils.readFully(new java.io.FileReader( file )));
		if( data.indexOf('<?xml') == 0 )
		{
			var lines = data.match(/[^\r\n]+/g);
				lines.shift();
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

			
var buildDir;
var projectDir;
var workspace;
var binDir;
var iconsDir;
var properties;
var generalProperties;
init();

function init()
{
	buildDir = project.getProperty('basedir');
	projectDir = new File(buildDir).getParent();

	workspace = new File(projectDir).getParent();

	binDir = projectDir+'/bin';
	iconsDir = binDir + '/AppIcons/';	
	properties = new Properties();
	generalProperties = new Properties();
	properties.load(new FileInputStream( buildDir+"/properties/es.xperiments.fdt.compile.gui.properties" ) );
	generalProperties.load(new FileInputStream( workspace+"/.metadata/.plugins/es.xperiments.fdt/fdt.properties" ) );
	// create AppIconsDir
	var appIconsDir = new File( binDir+'/AppIcons');
	if( !appIconsDir.exists() )
	{
		appIconsDir.mkdir();
	}
	saveAntForm();
}

function saveAntForm()
{
	setSDK();
	// process mainclass path
	properties.setProperty('es.xperiments.fdt.compile.gui.mainclass',getRelativeProjectPath( getProperty('es.xperiments.fdt.compile.gui.mainclass') ) );
	//properties.setProperty('es.xperiments.fdt.compile.gui.target',getRelativeProjectPath( getProperty('es.xperiments.fdt.compile.gui.target') )  );
	generateDescriptorFile();
	saveSortedProperties( properties, buildDir+"/properties/es.xperiments.fdt.compile.gui.properties" );

}

function setSDK()
{
	var selectedSDKName = properties.getProperty('es.xperiments.fdt.compile.selectedSDK')+'';
	var namedSDKList = generalProperties.getProperty('es.xperiments.fdt.configuration.avaliableSDKDescriptions')+'';
	var locationSDKList = generalProperties.getProperty('es.xperiments.fdt.configuration.avaliableSDK')+'';
	var namedSDKListArray = namedSDKList.split(',');
	var locationSDKListArray = locationSDKList.split(',');
	
	var sdkLocation="";

	for( var i=0; i<locationSDKListArray.length; i++ )
	{

		if( selectedSDKName == namedSDKListArray[ i ] )
		{
			sdkLocation = locationSDKListArray[i];
		}
	}
	properties.setProperty('es.xperiments.fdt.compile.sdk',sdkLocation );
}

function generateDescriptorFile()
{

	var descriptorFile = buildDir+'/templates/IOS-descriptor-template.xml';
	var descriptorTemplate = XMLLoader.load( descriptorFile );


		descriptorTemplate.id 									= getProperty('es.xperiments.fdt.compile.IOS.app.id');
		descriptorTemplate.filename 							= getProperty('es.xperiments.fdt.compile.gui.projectname');
		descriptorTemplate.name									= getProperty('es.xperiments.fdt.compile.IOS.app.name');
		descriptorTemplate.versionNumber						= getProperty('es.xperiments.fdt.compile.IOS.app.version');
		descriptorTemplate.allowBrowserInvocation				= getProperty('es.xperiments.fdt.compile.IOS.app.allowbrowserinvocation');

		descriptorTemplate.initialWindow.content				= getProperty('es.xperiments.fdt.compile.IOS.app.filename');
		descriptorTemplate.initialWindow.fullScreen				= getProperty('es.xperiments.fdt.compile.IOS.app.fullscreen');
		descriptorTemplate.initialWindow.autoOrients			= getProperty('es.xperiments.fdt.compile.IOS.app.autoorientation');
		descriptorTemplate.initialWindow.aspectRatio			= getProperty('es.xperiments.fdt.compile.IOS.app.aspectratio');
		descriptorTemplate.initialWindow.renderMode				= getProperty('es.xperiments.fdt.compile.IOS.app.rendermode');


		// iPhone Node
		descriptorTemplate.iPhone.requestedDisplayResolution	= getProperty('es.xperiments.fdt.compile.IOS.app.resolution');

		// InfoAdittions
		var deployDevice = getProperty('es.xperiments.fdt.compile.IOS.app.compatibledevices')+'';
		var infoAdittions = "<![CDATA[\n";
		switch( deployDevice )
		{
			case "iPhone only":
				infoAdittions += "\t\t<key>UIDeviceFamily</key>\n\t\t<array>\n\t\t\t<string>1</string>\n\t\t</array>\n";
			break;
			case "iPad only":
				infoAdittions += "\t\t<key>UIDeviceFamily</key>\n\t\t<array>\n\t\t\t<string>2</string>\n\t\t</array>\n";
			break;
			case "iPhone/iPad":
				infoAdittions += "\t\t<key>UIDeviceFamily</key>\n\t\t<array>\n\t\t\t<string>1</string>\n\t\t\t<string>2</string>\n\t\t</array>\n";
			break;
		}
		var hasCustomInfoAdditions = getProperty('es.xperiments.fdt.compile.IOS.app.custominfoadditions') == "true";
		if( hasCustomInfoAdditions )
		{
			var customAdittions = getProperty('es.xperiments.fdt.compile.gui.infoadditions');
			var customAdittionsLines = customAdittions.match(/[^\r\n]+/g);
			for( var i=0; i<customAdittionsLines.length; i++ )
			{
				customAdittionsLines[i]='\t\t'+customAdittionsLines[i];
			}
			infoAdittions+=customAdittionsLines.join('\n');
		}
		infoAdittions+='\n\t]]>';
		descriptorTemplate.iPhone.InfoAdditions = deleteEmptyLines( infoAdittions );

		// PROCESS CUSTOM ENTITLEMENTS
		var hasCustomEntitlements = getProperty('es.xperiments.fdt.compile.IOS.app.customentitlements') == "true";
		if( hasCustomEntitlements )
		{
			var entitlements = "<![CDATA[\n";
			var customEntitlements = getProperty('es.xperiments.fdt.compile.gui.entitlements');
			var customEntitlementsLines = customEntitlements.match(/[^\r\n]+/g);
			for( var i=0; i<customEntitlementsLines.length; i++ )
			{
				customEntitlementsLines[i]='\t\t'+customEntitlementsLines[i];
			}
			entitlements+=customEntitlementsLines.join('\n');
			entitlements+='\n\t]]>';
			descriptorTemplate.iPhone.Entitlements = deleteEmptyLines( entitlements );
		}
		
				
		
		// PROCESS ICONS
		var iconSizes = [29,48,57,72,114,512,1024];
		for( var i=0; i<iconSizes.length; i++ )
		{

			var currentIcon = isValidIcon( 'es.xperiments.fdt.compile.IOS.icons.icon'+iconSizes[i],iconSizes[i]  );
			if( currentIcon!=false )
			{
				descriptorTemplate.icon['image'+iconSizes[i]+'x'+iconSizes[i]] = 'AppIcons/'+currentIcon;
			}

		}
		
		// LANGUAGES
		var lang = getProperty('es.xperiments.fdt.compile.IOS.app.languages');
		if( lang!="")
		{
			var outLang = [];
			var langItems = lang.split(',');
			for( var i=0; i<langItems.length; i++ )
			{
				outLang.push( langItems[i].split(' ')[0]);
			}
			descriptorTemplate.supportedLanguages=outLang.join(' ');
		}
		else
		{
			delete descriptorTemplate.supportedLanguages;
		}
		
		// find and include extensions definitions
		getExtensionsDescription( descriptorTemplate, findFdtClassPathAnes() )

		// Save descriptor
		saveDescriptor( descriptorTemplate, binDir +'/'+getProperty('es.xperiments.fdt.compile.gui.projectname')+'-app.xml' );

		generateFDBinit();

}

/* FDBINIT */
function generateFDBinit()
{

	var deployTarget = getProperty('es.xperiments.fdt.compile.IOS.deploy.target');
	switch( deployTarget )
	{
		case "ipa-debug":
		case "ipa-debug-interpreter":
		case "ipa-debug-interpreter-simulator":
			var outputfile = new BufferedWriter(new FileWriter( buildDir+'/.fdbinit' ) );
			outputfile.write( getProperty('es.xperiments.fdt.compile.IOS.debug.fdbinit') );
			outputfile.close();	
		break;
	}	

}

/* EXTENSIONS UTILS */

function getExtensionId( extensionFile )
{
	var zipFile = new ZipFile( projectDir +'/'+extensionFile );
	
	var extension = zipFile.getEntry('META-INF/ANE/extension.xml');
	var inputStream = zipFile.getInputStream( extension );
	
	var extensionContents = new java.util.Scanner(inputStream).useDelimiter("\\A").next();
	
	// HACK!! remove namespace for easy xml data access
	var lines = extensionContents.match(/[^\r\n]+/g);
		lines.shift();
		lines.unshift('<extension>');
	var xml = new XML( lines.join('') );
	return xml.id+'';
}
function findFdtClassPathAnes()
{
	var fdtClassPaths = XMLLoader.load( projectDir+'/.settings/com.powerflasher.fdt.classpath' );
	var foundAnes = [];
	var currentClassPath;
	for( var i in fdtClassPaths.AS3Classpath )
	{
		currentClassPath = fdtClassPaths.AS3Classpath[ i ];
		if( currentClassPath.indexOf('.ane')!=-1)
		{
			foundAnes.push( currentClassPath );
		}
	}
	return foundAnes;
}
function getExtensionsDescription( xml, anes )
{
	if( anes.length == 0 ) return '';
	xml.appendChild(<extensions/>);
	for( var i=0, total = anes.length; i<total; i++ )
	{
		xml.extensions.appendChild(<extensionID/>);
		xml.extensions.extensionID[ i ] = getExtensionId( anes[i] );
	}

}

/* HELPERS */

function deleteEmptyLines( str )
{
	return str.replace(/^\s*$[\n\r]{1,}/gm, '');
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

function isValidIcon( iconProperty , size )
{
	var icon = getProperty( iconProperty );
	if( icon == null || icon == '') return false;
	var extension = icon.substring( icon.lastIndexOf(".") );
	if( extension != '.png' )
	{
		System.out.print('[ ERROR ] Icon with size '+size+'x'+size+' is not a png image\n');
		setProperty( iconProperty,'' );
		return false;
	}
	else
	{
		var inputFile = new File( icon );
		var image = javax.imageio.ImageIO.read(inputFile);

		if( image.getWidth(null) != size )
		{
			System.out.print('[ ERROR ] Icon with size '+size+'x'+size+' has wrong dimensions\n');
			setProperty( iconProperty,'' );
			return false;
		}			
		copyfile( icon , iconsDir + inputFile.getName() );
	}
	return inputFile.getName();
}

function copyfile(srFile, dtFile)
{
		var f1 = new File(srFile);
		var f2 = new File(dtFile);
		var input = new FileInputStream(f1);
		var output = new FileOutputStream(f2);

		var buf = Packages.java.lang.reflect.Array.newInstance(java.lang.Byte.TYPE, 1024);
		var buflen = 0;
		while ((buflen = input.read(buf)) > 0)
		{
			output.write(buf, 0, buflen);
		}
		input.close();
		output.close();
}
/*
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
}*/

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


function getRelativeProjectPath( path )
{

	if( path.indexOf( projectDir ) !=-1 )
	{
		if( new File( path ).exists() )
		{
			return path.split( projectDir )[1];
		}
		else
		{
			System.out.print('[ ERROR ] File '+ path +' does not exist');
			return "";
		}
	}
	else
	{
		if( new File( projectDir+'/'+path ).exists() )
		{
			return path;
		}
		else
		{
			System.out.print('[ ERROR ] File '+ path +' does not exist');
			return "";
		}
	}
}

function getProperty( name )
{
	return properties.getProperty( name )+'';
}
function setProperty( name , value )
{
	properties.setProperty( name, value );
}
