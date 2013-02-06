# ANEFileSync


A micro http server with FileManagement capabilities.
Based in the CocoaHTTPServer library. https://github.com/robbiehanson/CocoaHTTPServer

It lets you to:

* serve static web pages
* upload files to the device via POST
* actions to rename, delete, create dirs and list dir contents
* list directory contents

## Usage

Include the ANEFileSync.ane to your project.(Get it inside the <a href="https://github.com/xperiments/ANEFileSyncInterface/tree/master/NATIVE/ANEFileSyncInterface/PRODUCTS">NATIVE/ANEFileSyncInterface/PRODUCTS</a> dir ).
Current ANE provides Device & Simulator support.

**There is a known bug in the simulator that prevents to upload files,so the application quits unexpectedly.**

## Avaliable Class Methods

#### isSupported() : Boolean;
    Returns if the native extension is supported or not
#### dispose() : void;
    Disposes the extension
#### getDirectoryListingEnabled() : Boolean;
    Returns the state of the 
#### getDocumentRoot() : File;
    Returns the actual DocumentRoot File
#### getEnabledActions() : String;

    Returns a comma separated string of the active actions
    
#### getInterface() : String;

    Returns the current device ip.
    When no connection is avalible it will return 0.0.0.0
    Also when running in simulator it will return 0.0.0.0 but you can access it locating your current machine ip

#### getModificationDateFormat() : String;

    Returns the current date format.

#### getPort() : uint;
    
    Returns the current listening port

#### getUploadDir() : File;

    Returns the actual Upload dir

#### getUploadDirectoryListingEnabled() : Boolean;

    Returns true if the actual upload dir is browseable otherwise returns false

#### setDirectoryListingEnabled(enabled : Boolean) : void;

    When enabled, if the current directory has no index.html file shows a directory listing

#### setDocumentRoot(directory : File) : void;

    Sets the current webserver root directory

#### setEnabledActions(actions : String) : void;

    Comma separated string to set the avaliable server actions.
    By default all avaliable actions are enabled.

    Avaliable actions are:
    * createDir
    * delete
    * rename
    * listDir
    * upload
    
    e.g: setEnabledActions('createDir,delete');

#### setModificationDateFormat(format : String) : void;

    Sets the current modification date format.
    The default format is yyyy/MM/dd HH:mm
    
#### setPort(port : uint) : void;

    Sets the current listening port

#### setUploadDir(uploadDir : File) : void;

    Sets the current webserver upload directory
    The upload dir can be inside or outside the webserver root directory

#### setUploadDirectoryListingEnabled(enabled : Boolean) : void;

    Lets you hide/show the upload directory when it is inside the webserver root and directory listing is enabled
    
#### start() : Boolean;

    Starts the server.
    Returns true on success otherwise returns false

#### stop() : void;

    Stops the server
    
    
## Avaliable Class Events

ANEFileSyncEvent.FILE_UPLOADED

        Dispatched when a file upload is completed
        event.data.filename     contains the name of the uploaded file
        event.data.path         contains the native path to the uploaded file
        
ANEFileSyncEvent.FILE_DELETED

        Dispatched when a file has been deleted
        event.data.result   contains true if the file has been correctly deleted otherwise contains false
        event.data.path     contains the native path to the deleted file
        
ANEFileSyncEvent.FILE_RENAMED

        Dispatched when a file has been renamed
        event.data.from     contains the original renamed file path
        event.data.to       contains the final renamed file path
        event.data.result   contains true if the file has been correctly renamed otherwise contains false
        
ANEFileSyncEvent.DIRECTORY_CREATED

        Dispatched when a directory has been created
        event.data.result   contains true if the directory has been correctly created otherwise contains false
        event.data.path     contains the native path to the created directory
        
ANEFileSyncEvent.SERVER_STARTED

        Dispatched when the server starts
        event.data.ip       contains the server current ip. ( 0.0.0.0 in Simulator )
        event.data.port     contains the server current port
        
ANEFileSyncEvent.SERVER_STOPED

        Dispatched when the server stops

---

## Minimal contens of DocumentRoot directory


You must include a directory named \_\_\_templates\_\_\_.

Inside this directory **you must provide** a file named **404.html** that will show generic server errors.

Also **if you set DirectoryListingEnabled** you must provide a file named **dir.html** that will be used to show the default Directory Listing

### dir.html templating

dir.html uses mustache templating system to render his contents.

The current avaliable properties passed to the template are:

        {{parent}} The parent dir path
        {{files}} Array containing the current directory files
        
        Use this minimal template to access each file properties:
        
        {{#files}}
            {{type}} // can be file or dir
            {{path}} // full file path
            {{name}} // file name
            {{size}} // file size in bytes
            {{modification}} // modification date
        {{/files}}

Basic Document root example is located at <a href="https://github.com/xperiments/ANEFileSyncInterface/tree/master/BasicDocumentRoot">BasicDocumentRoot directory</a>

Also you can find a working example of DocumentRoot inside the provided <a href="https://github.com/xperiments/ANEFileSyncInterface/tree/master/example/ANEFileSyncExample/bundle">example/bundle</a> dir

---

## Client side javascript methods to interact with the server

A little javascript library to interact with the server actions.

To use it include the IOSFileSync.js to your page.

**All the paths used must be relative to the DocumentsRoot or UploadDir**

The library uses the promise approach to interact with IOSFileSync methods, so you can use it as:

        IOSFileSync.methodXXX().then( success, fail, progress /* only 4 upload */ );

### Avaliable javascript methods

#### IOSFileSync.rename

        IOSFileSync.rename( from , to ).then( success, fail );
        
#### IOSFileSync.deleteFile

        IOSFileSync.deleteFile( file ).then( success, fail );
        
#### IOSFileSync.createDir

        IOSFileSync.createDir( dir ).then( success, fail );
        
#### IOSFileSync.listDir

        var success = function( data )
        {
            // data will contain an array of file objects
           /*
               [
                    {
                        path:'full file path',
                        name:'filename',
                        isDir:'true if file is a directory',
                        size:'the file size in bytes'
                    },...
               ]
           */
        }
        var fail = function( error )
        {
            // error will contain the error description
            // posible errors are 'emptydir' 'notfound' 'serverNotFound'
        }
        IOSFileSync.listDir( dir ).then( success, fail );
        
        
        
#### IOSFileSync.upload

        var progress = function( percentage )
        {
            console.log( 'Uploaded '+percentage+'%');
        }
        
        IOSFileSync.upload(
            file /* File object */,
            path /* you can provide a relative path from the default upload path */
        ).then(
            success,
            fail,
            progresss
        );        
        

## Basic Example

Inside the example folder you can find a minimal example that lets you upload an image to the server.
The image will be shown at the device, after that you can click on "Get upload dir contents" to get a list of the files inside the upload dir.

## License

<!-- Creative Commons License -->
<a rel="license" href="http://creativecommons.org/licenses/by-sa/3.0/"><img alt="Creative Commons License" border="0" src="http://i.creativecommons.org/l/by-sa/3.0/88x31.png" class="cc-button"/></a><div class="cc-info"><span xmlns:cc="http://creativecommons.org/ns#" xmlns:dc="http://purl.org/dc/elements/1.1/"><span id="work_title" property="dc:title">ANEFileSync</span> by <a rel="cc:attributionURL" property="cc:attributionName" href="http://www.xperiments.es">Pedro Casaubon</a> is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-sa/3.0/">Creative Commons Attribution-ShareAlike 3.0 License</a>. <span rel="dc:source" href="https://github.com/xperiments/ANEFileSyncInterface"/></span></div>

