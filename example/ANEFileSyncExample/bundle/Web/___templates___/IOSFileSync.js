
IOSFileSync = (function( undefined ) {

	// Promise implementation based on unscriptable's minimalist Promise:
	// https://gist.github.com/814052/
	function Promise () { this._thens = []; }
	Promise.prototype =
	{

		then: function (onResolve, onReject, onProgress)
		{
			this._thens.push({ resolve: onResolve, reject: onReject, progress: onProgress });
		},
		resolve: function (val) { this._complete('resolve', val); },
		reject: function (ex) { this._complete('reject', ex); },
		progress: function(statusObject)
		{
			var i=0, aThen;
			while(aThen = this._thens[i++]) { aThen.progress && aThen.progress(statusObject); }
		},
		_complete: function (which, arg) {
			this.then = which === 'resolve' ?
				function (resolve, reject) { resolve && resolve(arg); } :
				function (resolve, reject) { reject && reject(arg); };

			this.resolve = this.reject = this.progress =
				function () { throw new Error('Promise already completed.'); };

			var i=0, aThen;
			while (aThen = this._thens[i++]) { aThen[which] && aThen[which](arg); }
			delete this._thens;
		}
	};


	// JSON HELPERS

	/************************************************************************/
	var json =function(url, data, success, error )
	{
	   var ajaxRequest = _getAjaxRequest( success, error );
	   ajaxRequest.open("GET", url+'?'+_serialize(data), true);
	   ajaxRequest.setRequestHeader('Content-Type', 'application/json;charset=encoding');   
	   ajaxRequest.send();    
	}
	
	var _getAjaxRequest = function( sucess, error )
	{
	    var xhr = new XMLHttpRequest();
	    xhr.onreadystatechange = function()
	    {
            if ( xhr.readyState == 4 )
            {
            	if( xhr.status == 200 )
            	{      
	           		sucess( JSON.parse( xhr.responseText ) );
	           	}
	           	else
	           	{
	           		error( xhr.status );
	           	}
	        }
	    };
	    return xhr;

	}
	var _serialize = function(obj)
	{
	  var str = [];
	  for(var p in obj) str.push(encodeURIComponent(p) + "=" + encodeURIComponent(obj[p]));
	  return str.join("&");
	}
	/************************************************************************/


	// PUBLIC METHODS


	/************************************************************************/
    var rename = function(from,to)
    {
        var promise = new Promise();
        json(
        	'/actions.rename',
        	{from:from, to:to },
        	function(data){ data.result ? promise.resolve( ):promise.reject( ); },
        	function(data){ promise.reject( ); }
        );
        return promise;
    }   
    var deleteFile = function( file )
    {
        var promise = new Promise();
        json(
        	'/actions.delete',
        	{file:file},
        	function(data){ data.result ? promise.resolve( ):promise.reject( ); },
        	function(data){ promise.reject( ); }
        );
        return promise;
    }    
    var createDir = function( dir )
    {
        var promise = new Promise();
        json(
        	'/actions.createDir',
        	{dir:dir},
        	function(data){ data.result ? promise.resolve( ):promise.reject( ); },
        	function(data){ promise.reject( ); }
        );
        return promise;
    } 
    var listDir = function( dir )
    {
        var promise = new Promise();
        json(
        	'/actions.listDir',
        	{dir:dir},
        	function(data)
	        {
	            if( data.error )
	            {
	                promise.reject( data.error )
	            }
	            else
	            {
	                promise.resolve( data )
	            }
	        },
	        function(data){ promise.reject( 'serverNotFound' ); }
        );
        return promise;
    }

    var upload = function( file, path )
    {

    	path = (typeof path === 'undefined') ? "uploadTo:|" : "uploadTo:"+path.split('/').join('|');

    	var promise = new Promise();
        var uri = "/actions.upload";
        var xhr = new XMLHttpRequest();
        var fd = new FormData();
        
        xhr.open("POST", uri, true);
        xhr.onreadystatechange = function()
        {
            if (xhr.readyState == 4)
            {
            	if( xhr.status == 200 )
            	{
	                // Handle response.
	                var data = JSON.parse( xhr.responseText );
	                if( data.result )
	                {
	                	promise.resolve( );
	                }
	                else
	                {
	                	promise.reject( );
	                }
	            }
	            else
	            {
	            	promise.reject();
	            }
            }
            xhr.upload.removeEventListener("progress", progressHandler, false );
        };

        var progressHandler = function(e)
        {
	        if (e.lengthComputable)
	        {
	        	var percentage = Math.round((e.loaded * 100) / e.total);
	        	promise.progress( percentage );
	        	
	        }
        };
        xhr.upload.addEventListener("progress", progressHandler, false);

        fd.append( path, file );

        xhr.send(fd);

        return promise;
    }


    return {
        rename:rename,
        createDir:createDir,
        deleteFile:deleteFile,
        upload: upload,
        listDir: listDir
    };

})();

