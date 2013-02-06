importPackage(java.lang);
importPackage(java.io);
importClass(java.util.Properties);

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
var binDir;
var iconsDir;
var properties;

init();

function init()
{
	buildDir = project.getProperty('basedir');
	projectDir = new File(buildDir).getParent();
	binDir = projectDir+'/bin';
	properties = new Properties();
	properties.load(new FileInputStream( buildDir+"/properties/es.xperiments.fdt.compile.gui.properties" ) );
	generateAntDeploy();

}

function generateAntDeploy()
{

	var deployTemplateFile = buildDir+'/templates/IOS-deploy-template.xml';
	var descriptorTemplate = XMLLoader.load( deployTemplateFile );
	var deployTargetNode = descriptorTemplate.target[0];
	var execNode = descriptorTemplate.target.exec;
	var deployTarget = getProperty('es.xperiments.fdt.compile.IOS.deploy.target');
	var useCustomCompilerArguments = getProperty('es.xperiments.fdt.compile.gui.usecustomcompilerarguments')=="true";

	
	/* SET TARGET NAME */
	descriptorTemplate.property.(@name=="IOS.deployer.currentFile")[0].@value = getProperty('es.xperiments.fdt.compile.IOS.deploy.target')+'.xml';
	/* DETERMINE IF USE CUSTOM COMPILER ARGUMENTS */
	
	if( useCustomCompilerArguments )
	{
		descriptorTemplate.target[2]['fdt.launch.application'].@compilerarguments = '${es.xperiments.fdt.compile.gui.customcompilerarguments}';
	}

	/* DETERMINE DEBUG MODE BASED ON DEPLOY TARGET */
	switch( deployTarget )
	{
		case "ipa-test":
		case "ipa-test-interpreter":	
		case "ipa-app-store":	
		case "ipa-ad-hoc":
		case "ipa-test-interpreter-simulator":
			descriptorTemplate.target[2]['fdt.launch.application'].@debug = 'false';
		break;
		
		case "ipa-debug":
		case "ipa-debug-interpreter":
		case "ipa-debug-interpreter-simulator":	
			descriptorTemplate.target[2]['fdt.launch.application'].@debug = 'true';
		break;
	}	
	
	addArg( execNode, "-target" );
	addArg( execNode, "${es.xperiments.fdt.compile.IOS.deploy.target}" );
	switch( deployTarget )
	{

		case 'ipa-debug':
		case 'ipa-debug-interpreter':
		case 'ipa-debug-interpreter-simulator':
			addArg( execNode, "-connect" );
		break;

	}
	/* provisioning type p12 */
	addArg( execNode, "-storetype" );
	addArg( execNode, "pkcs12" );

	/* provisioning type */
	addArg( execNode, "-keystore" );
	addArg( execNode, "${es.xperiments.fdt.compile.IOS.signature.certificate}" );

	/* password */
	addArg( execNode, "-storepass" );
	addArg( execNode, "${es.xperiments.fdt.compile.IOS.signature.password}" );

	/* provisioning file */
	addArg( execNode, "-provisioning-profile" );
	addArg( execNode, "${es.xperiments.fdt.compile.IOS.signature.provisioning}" );

	/* IPA */
	addArg( execNode, "${es.xperiments.fdt.compile.gui.projectname}.ipa" );
	addArg( execNode, "${es.xperiments.fdt.compile.gui.projectname}-app.xml" );
	addArg( execNode, "${es.xperiments.fdt.compile.gui.projectname}.swf" );

	/* INCLUDED ICONS */
	addArg( execNode, "AppIcons" );

	/* INCLUDE SELECTED FILES */
	var includedFilesString = getProperty('es.xperiments.fdt.compile.IOS.fileselector.includedFiles');
	if( includedFilesString !="" )
	{
		var filesToInclude = includedFilesString.split(',');
		System.out.print('INLUUUU=>'+ filesToInclude.length)
		if( filesToInclude.length > 0 )
		{
			for( var i = 0; i<filesToInclude.length; i++ )
			{
				var currentIncludedFiles = getPathParts( filesToInclude[ i ] );
				addArg( execNode, "-C" );
				addArg( execNode, currentIncludedFiles.dir );
				addArg( execNode, currentIncludedFiles.files_and_dirs );
			}
		}
	}

	/* HAS NATIVE EXTENSIONS ? */
	if( findFdtClassPathAnes().length!=0 )
	{
		addArg( execNode, '-extdir' );
		addArg( execNode, projectDir+'/lib' );		
	}

	/* PLATFORM */
	switch( deployTarget )
	{
		case "ipa-test":
		case "ipa-debug":
		case "ipa-app-store":
		case "ipa-ad-hoc":
		case "ipa-debug-interpreter":
		case "ipa-test-interpreter":
			if( getProperty('es.xperiments.fdt.compile.IOS.deploy.platformsdk')!="" )
			{
				addArg( execNode, '-platformsdk' );
				addArg( execNode, '${es.xperiments.fdt.compile.IOS.deploy.platformsdk}' );				
			}
		break;

		case "ipa-test-interpreter-simulator":
		case "ipa-debug-interpreter-simulator":
			if( getProperty('es.xperiments.fdt.compile.IOS.deploy.platformsdksimulator')!="" )
			{
				addArg( execNode, '-platformsdk' );
				addArg( execNode, '${es.xperiments.fdt.compile.IOS.deploy.platformsdksimulator}' );				
			}
			else
			{
				System.out.print('[ ERROR ] Simulator can not be deployed without a SimulatorSDK');
				return;
			}
		break;
	}
	
	/* INSTALL ON DEVICE */
	if( getProperty('es.xperiments.fdt.compile.IOS.deploy.deviceinstall')=="true")
	{
		if( deployTarget.indexOf('simulator')!=-1 )
		{
			deployTargetNode.@depends="SWF.autoincrementBuild,SWF.compile,IOS.package,IPA.deviceinstallSimulator";
		}
		else
		{
			deployTargetNode.@depends="SWF.autoincrementBuild,SWF.compile,IOS.package,IPA.deviceinstallDevice";
		}
		
	}
	

	
	/* RUN DEBUGGER */
	switch( deployTarget )
	{
		case "ipa-debug":
		case "ipa-debug-interpreter":
		case "ipa-debug-interpreter-simulator":
			if( getProperty('es.xperiments.fdt.compile.IOS.debug.autostart')=="true")
			{
				if( getProperty('es.xperiments.fdt.compile.IOS.debug.app') == "FLEX SDK Debugger")
				{
					deployTargetNode.@depends+=',SWF.debug';
				}
				else
				{
					if( getProperty('es.xperiments.fdt.compile.IOS.debug.monsterdebuggerbin')!="" )
					{
						deployTargetNode.@depends+=',SWF.debug.MonsterDebugger';
					}
				}
			}
		break;
		
		default:
			if( getProperty('es.xperiments.fdt.compile.IOS.debug.autostart')=="true")
			{
				if( getProperty('es.xperiments.fdt.compile.IOS.debug.app') != "FLEX SDK Debugger" && getProperty('es.xperiments.fdt.compile.IOS.debug.monsterdebuggerbin')!="" )
				{
					deployTargetNode.@depends+=',SWF.debug.MonsterDebugger';
				}
			}			
		break;
	}	
	

	saveAntDeployer( descriptorTemplate, buildDir +'/builders/'+deployTarget+'.xml');
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

function getPathParts( filePath )
{
	var file = new File( filePath );
	var dir = file.getParent();
	var files_and_dirs = file.getName();

	return { dir:dir, files_and_dirs:files_and_dirs };
}

function addArg( node, value )
{
	node.arg[ node.arg.length() ] = ""; // create empty node;
	node.arg[ node.arg.length()-1 ].@value = value;
}

function saveAntDeployer( descriptorXML, destinationFile )
{
	
	var deployTarget = getProperty('es.xperiments.fdt.compile.IOS.deploy.target')+'';		
	switch( deployTarget )
	{
		case "ipa-test":
		case "ipa-debug":
		case "ipa-app-store":
		case "ipa-ad-hoc":
		case "ipa-debug-interpreter":
		case "ipa-test-interpreter":
			replaceIOSSDK( descriptorXML, '${es.xperiments.fdt.compile.IOS.deploy.platformsdk}');
			deleteSimulatorDeploy( descriptorXML );
		break;

		case "ipa-test-interpreter-simulator":
		case "ipa-debug-interpreter-simulator":
			replaceIOSSDK( descriptorXML, '${es.xperiments.fdt.compile.IOS.deploy.platformsdksimulator}');
		break;
	}		
	
	var outputfile = new BufferedWriter(new FileWriter( destinationFile ));

	var descriptorArray = (descriptorXML+'').split('\n');
		descriptorArray.shift();
		descriptorArray.unshift('<project name="IOS.'+getProperty('es.xperiments.fdt.compile.IOS.deploy.target')+'" basedir="." default="IOS.deploy">');
		descriptorArray.unshift('<?xml version="1.0" encoding="utf-8" ?>');

	var finalString = new String( descriptorArray.join('\n').replace(/&lt;/g,'<').replace(/&gt;/g,'>') );		
	outputfile.write( finalString );
	outputfile.close();

}


/* HELPERS */
function deleteSimulatorDeploy( xml )
{	
	while( true )
	{
		var items = xml.target.java.arg.(@value=="-device");
		if( items.length() == 0 ) break;
		for( var i in items )
		{
			delete items[i];
		}
	}	
	while( true )
	{
		var items = xml.target.java.arg.(@value=="ios-simulator");
		if( items.length() == 0 ) break;
		for( var i in items )
		{
			delete items[i];
		}
	}
	return xml;
}
function replaceIOSSDK( xml, val )
{
	var items = xml.target.java.arg.(@value=="###IOSSDK###");
	for( var i in items )
	{
		items[i].@value = val;
	}
	return xml;
}
function loadFileToString( path )
{
	return new String(org.apache.tools.ant.util.FileUtils.readFully(new java.io.FileReader( new File(path) )));
}
function getProperty( name )
{
	return properties.getProperty( name )+'';
}
function setProperty( name , value )
{
	properties.setProperty( name, value );
}