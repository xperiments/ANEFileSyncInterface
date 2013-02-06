<extension xmlns="http://ns.adobe.com/air/extension/3.2">
	<id>es.xperiments.ane.filesyncinterface.ANEFileSync</id>
	<versionNumber>@majorVersion@.@minorVersion@.@buildNumber@</versionNumber>
		<platforms> 
			<platform name="iPhone-ARM">
				<applicationDeployment>
					<nativeLibrary>libANEFileSync.a</nativeLibrary>
					<initializer>ANEFileSyncExtensionInitializer</initializer>
					<finalizer>ANEFileSyncExtensionFinalizer</finalizer>
				</applicationDeployment>
			</platform>
			<platform name="iPhone-x86">
				<applicationDeployment>
					<nativeLibrary>libANEFileSync.a</nativeLibrary>
					<initializer>ANEFileSyncExtensionInitializer</initializer>
					<finalizer>ANEFileSyncExtensionFinalizer</finalizer>
				</applicationDeployment>
			</platform>			
	</platforms>
</extension>
			