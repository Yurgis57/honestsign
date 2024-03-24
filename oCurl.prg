//  Wrapper for hbCurl, based on libcurl 'easy' API - Harbour interface.
#include "hbvo.ch"
#include "hbmacro.ch"
#include "hbcurl.ch"

/* NOTE: Harbour requires libcurl 7.17.0 or upper.
         This was the version where curl_easy_setopt() started to
         make copies of passed strings, which we currently require.
         Update: This requirement is now sorted out by local string
                 buffering logic used with pre-7.17.0 versions of
                 libcurl.
         [vszakats] */

//--------------------- iOption CURL_EASY_SETOPT parameter ----------------------------------------
//	---- iOption ----		---- Type ----
//	HB_CURLOPT_VERBOSE:			L		 
//	HB_CURLOPT_HEADER:			L	 
//	HB_CURLOPT_NOPROGRESS:			L	 
//	HB_CURLOPT_NOSIGNAL:			L	 
//	HB_CURLOPT_WILDCARDMATCH:		L	 
//	HB_CURLOPT_FAILONERROR:			L	 
//	HB_CURLOPT_URL:				C	This is the only option that must be set before curl_easy_perform() is called
//	HB_CURLOPT_PROXY:			C	 
//	HB_CURLOPT_PROXYPORT:			N	 
//	HB_CURLOPT_PROXYTYPE:			N	 
//	HB_CURLOPT_HTTPPROXYTUNNEL:		L	 
//	HB_CURLOPT_SOCKS5_RESOLVE_LOCAL:	L	Deleted
//	HB_CURLOPT_INTERFACE:			C	
//	HB_CURLOPT_LOCALPORT:			N	
//	HB_CURLOPT_LOCALPORTRANGE:		N	
//	HB_CURLOPT_DNS_CACHE_TIMEOUT:		N	
//	HB_CURLOPT_DNS_USE_GLOBAL_CACHE:	L	Obsolete
//	HB_CURLOPT_BUFFERSIZE:			N	
//	HB_CURLOPT_PORT:			N	
//	HB_CURLOPT_TCP_NODELAY:			L	Not documented
//	HB_CURLOPT_ADDRESS_SCOPE:		N	 
//	HB_CURLOPT_PROTOCOLS:			N	 
//	HB_CURLOPT_REDIR_PROTOCOLS:		N	 
//	HB_CURLOPT_NOPROXY:			C	 
//	HB_CURLOPT_SOCKS5_GSSAPI_SERVICE:	C	 
//	HB_CURLOPT_SOCKS5_GSSAPI_NEC:		L	 
//	HB_CURLOPT_TCP_KEEPALIVE:		N	 
//	HB_CURLOPT_TCP_KEEPIDLE:		N	 
//	HB_CURLOPT_TCP_KEEPINTVL:		N	 

    /* Names and passwords options (Authentication) */

//	HB_CURLOPT_NETRC:			N	 
//	HB_CURLOPT_NETRC_FILE:			C	 
//	HB_CURLOPT_USERPWD:			C	 
//	HB_CURLOPT_USERNAME:			C	 
//	HB_CURLOPT_PASSWORD:			C	 
//	HB_CURLOPT_PROXYUSERPWD:		C	 
//	HB_CURLOPT_PROXYUSERNAME:		C	 
//	HB_CURLOPT_PROXYPASSWORD:		C	 
//	HB_CURLOPT_HTTPAUTH:			N	 
//	HB_CURLOPT_PROXYAUTH:			N	 

    /* HTTP options */

//	HB_CURLOPT_AUTOREFERER:			L	 
//	HB_CURLOPT_ACCEPT_ENCODING:		C	 
//	HB_CURLOPT_TRANSFER_ENCODING:		N	 
//	HB_CURLOPT_FOLLOWLOCATION:		L	 
//	HB_CURLOPT_UNRESTRICTED_AUTH:		L	 
//	HB_CURLOPT_MAXREDIRS:			N	 
//	HB_CURLOPT_POSTREDIR:			L	 
//	HB_CURLOPT_PUT:				L	 
//	HB_CURLOPT_POST:			L	 
//	HB_CURLOPT_POSTFIELDS:			C	 
//	HB_CURLOPT_COPYPOSTFIELDS:		C	 
//	HB_CURLOPT_POSTFIELDSIZE:		N	 
//	HB_CURLOPT_POSTFIELDSIZE_LARGE:		HB_CURL_OPT_LARGENUM 
//	HB_CURLOPT_HTTPPOST:			A	 { { FORM_NAME, FORMFILE } }
//	HB_CURLOPT_REFERER:			C	 
//	HB_CURLOPT_USERAGENT:			C	 
//	HB_CURLOPT_HTTPHEADER:			A	 { HTTPHEADER }
//	HB_CURLOPT_HTTP200ALIASES:		A	 { HTTP200ALIASES }
//	HB_CURLOPT_COOKIE:			C	 
//	HB_CURLOPT_COOKIEFILE:			C	 
//	HB_CURLOPT_COOKIEJAR:			C	 
//	HB_CURLOPT_COOKIESESSION:		L	 
//	HB_CURLOPT_COOKIELIST:			C	 
//	HB_CURLOPT_HTTPGET:			L	 
//	HB_CURLOPT_HTTP_VERSION:		N	 
//	HB_CURLOPT_IGNORE_CONTENT_LENGTH:	L	 
//	HB_CURLOPT_HTTP_CONTENT_DECODING:	L	 
//	HB_CURLOPT_HTTP_TRANSFER_DECODING:	L	 

   /* SMTP options */

//	HB_CURLOPT_MAIL_FROM:			C	 
//	HB_CURLOPT_MAIL_RCPT:			A	 { MAIL_RCPT }
//	HB_CURLOPT_MAIL_AUTH:			C	 

   /* TFTP options */

//	HB_CURLOPT_TFTP_BLKSIZE:		N	 

   /* FTP options */

//	HB_CURLOPT_FTPPORT:			C	 
//	HB_CURLOPT_QUOTE:			A	 { QUOTE }
//	HB_CURLOPT_POSTQUOTE:			A	 { POSTQUOTE }
//	HB_CURLOPT_PREQUOTE:			A	 { PREQUOTE }
//	HB_CURLOPT_DIRLISTONLY: 		L	 HB_CURLOPT_FTPLISTONLY
//	HB_CURLOPT_APPEND: 			L	 HB_CURLOPT_FTPAPPEND
//	HB_CURLOPT_FTP_USE_EPRT:		L	 
//	HB_CURLOPT_FTP_USE_EPSV:		L	 
//	HB_CURLOPT_FTP_USE_PRET:		L	 
//	HB_CURLOPT_FTP_CREATE_MISSING_DIRS:	L	 
//	HB_CURLOPT_FTP_RESPONSE_TIMEOUT:	N	 
//	HB_CURLOPT_FTP_ALTERNATIVE_TO_USER:	C	 
//	HB_CURLOPT_FTP_SKIP_PASV_IP:		L	 
//	HB_CURLOPT_USE_SSL:			N	 
//	HB_CURLOPT_FTPSSLAUTH:			N	 
//	HB_CURLOPT_FTP_SSL_CCC:			N	 
//	HB_CURLOPT_FTP_ACCOUNT:			C	 
//	HB_CURLOPT_FTP_FILEMETHOD:		N	 

   /* RTSP */

//	HB_CURLOPT_RTSP_REQUEST:		N	
//	HB_CURLOPT_RTSP_SESSION_ID:		C	 
//	HB_CURLOPT_RTSP_STREAM_URI:		C	 
//	HB_CURLOPT_RTSP_TRANSPORT:		C	 
//	HB_CURLOPT_RTSP_CLIENT_CSEQ:		N	 
//	HB_CURLOPT_RTSP_SERVER_CSEQ:		N	 

   /* Protocol */

//	HB_CURLOPT_TRANSFERTEXT:		L	 
//	HB_CURLOPT_PROXY_TRANSFER_MODE:		L	 
//	HB_CURLOPT_CRLF:			L	 
//	HB_CURLOPT_RANGE:			C	 
//	HB_CURLOPT_RESUME_FROM:			N	 
//	HB_CURLOPT_RESUME_FROM_LARGE:		HB_CURL_OPT_LARGENUM 
//	HB_CURLOPT_CUSTOMREQUEST:		C	 
//	HB_CURLOPT_FILETIME:			N	 
//	HB_CURLOPT_NOBODY:			L	 
//	HB_CURLOPT_INFILESIZE:			N	 
//	HB_CURLOPT_INFILESIZE_LARGE:		HB_CURL_OPT_LARGENUM 
//	HB_CURLOPT_UPLOAD:			L	 
//	HB_CURLOPT_DOWNLOAD: 			! L	 Harbour extension
//	HB_CURLOPT_MAXFILESIZE:			N	 Not documented. GUESS
//	HB_CURLOPT_MAXFILESIZE_LARGE:		HB_CURL_OPT_LARGENUM 
//	HB_CURLOPT_TIMECONDITION:		N	 
//	HB_CURLOPT_TIMEVALUE:			N	 

   /* Connection */

//	HB_CURLOPT_TIMEOUT:			N	 
//	HB_CURLOPT_TIMEOUT_MS:			N	 
//	HB_CURLOPT_LOW_SPEED_LIMIT:		N	 
//	HB_CURLOPT_LOW_SPEED_TIME:		N	 
//	HB_CURLOPT_MAX_SEND_SPEED_LARGE:	HB_CURL_OPT_LARGENUM 
//	HB_CURLOPT_MAX_RECV_SPEED_LARGE:	HB_CURL_OPT_LARGENUM 
//	HB_CURLOPT_MAXCONNECTS:			N	 
//	HB_CURLOPT_CLOSEPOLICY:			N	OBSOLETE, does nothing
//	HB_CURLOPT_FRESH_CONNECT:		L	 
//	HB_CURLOPT_FORBID_REUSE:		L	 
//	HB_CURLOPT_CONNECTTIMEOUT:		N	 
//	HB_CURLOPT_CONNECTTIMEOUT_MS:		N	 
//	HB_CURLOPT_IPRESOLVE:			N 	Not documented. GUESS
//	HB_CURLOPT_CONNECT_ONLY:		L	 
//	HB_CURLOPT_RESOLVE:			A	{ RESOLVE }
//	HB_CURLOPT_DNS_SERVERS:			C	 
//	HB_CURLOPT_ACCEPTTIMEOUT_MS:		N	 

   /* SSL and Security */

//	HB_CURLOPT_SSLCERT:			C	 
//	HB_CURLOPT_SSLCERTTYPE:			C	 
//	HB_CURLOPT_SSLKEY:			C	 
//	HB_CURLOPT_SSLKEYTYPE:			C	 
//	HB_CURLOPT_KEYPASSWD:			C	= CURLOPT_SSLKEYPASSWD, CURLOPT_SSLCERTPASSWD
//	HB_CURLOPT_SSLENGINE:			C	 
//	HB_CURLOPT_SSLENGINE_DEFAULT:		N	 
//	HB_CURLOPT_SSLVERSION:			N	 
//	HB_CURLOPT_SSL_VERIFYPEER:		L	 
//	HB_CURLOPT_CAINFO:			C	 
//	HB_CURLOPT_CAPATH:			C	 
//	HB_CURLOPT_RANDOM_FILE:			C	 
//	HB_CURLOPT_EGDSOCKET:			C	 
//	HB_CURLOPT_SSL_VERIFYHOST:		N	 
//	HB_CURLOPT_SSL_CIPHER_LIST:		C	 
//	HB_CURLOPT_SSL_SESSIONID_CACHE:		L	 
//	HB_CURLOPT_KRBLEVEL: 			C	= HB_CURLOPT_KRB4LEVEL
//	HB_CURLOPT_CRLFILE:			C	 
//	HB_CURLOPT_ISSUERCERT:			C	 
//	HB_CURLOPT_CERTINFO:			L	 
//	HB_CURLOPT_GSSAPI_DELEGATION:		N	 
//	HB_CURLOPT_SSL_OPTIONS:			N	 

   /* SSH options */

//	HB_CURLOPT_SSH_AUTH_TYPES:		N	 
//	HB_CURLOPT_SSH_HOST_PUBLIC_KEY_MD5:	C	 
//	HB_CURLOPT_SSH_PUBLIC_KEYFILE:		C	 
//	HB_CURLOPT_SSH_PRIVATE_KEYFILE:		C	 
//	HB_CURLOPT_SSH_KNOWNHOSTS:		C	 

   /* Other options */

//	HB_CURLOPT_PRIVATE:			hb_parptr 

   /* HB_CURLOPT_SHARE */

//	HB_CURLOPT_NEW_FILE_PERMS:		N	 
//	HB_CURLOPT_NEW_DIRECTORY_PERMS:		N	 

   /* Telnet options */

//	HB_CURLOPT_TELNETOPTIONS:		A	{ CURLOPT_TELNETOPTIONS }

   /* Harbour specials */

//	HB_CURLOPT_PROGRESSBLOCK:		B/S
//	HB_CURLOPT_UL_FILE_SETUP:		C	hb_curl_read_file_callback
//	HB_CURLOPT_UL_FHANDLE_SETUP:		I 	CURLOPT_READFUNCTION, CURLOPT_READDATA
//	HB_CURLOPT_UL_FILE_CLOSE:
//	HB_CURLOPT_DL_FILE_SETUP:		C	CURLOPT_WRITEFUNCTION, CURLOPT_WRITEDATA
//	HB_CURLOPT_DL_FHANDLE_SETUP:		I 	CURLOPT_WRITEFUNCTION, CURLOPT_WRITEDATA
//	HB_CURLOPT_DL_FILE_CLOSE:
//	HB_CURLOPT_UL_BUFF_SETUP:		C	CURLOPT_READFUNCTION, CURLOPT_READDATA
//	HB_CURLOPT_DL_BUFF_SETUP:		N	CURLOPT_WRITEFUNCTION, CURLOPT_WRITEDATA
//	HB_CURLOPT_DL_BUFF_GET:			@C 
//	HB_CURLOPT_UL_NULL_SETUP:
//--------------------- End of CURL_EASY_SETOPT parameters --------------------------------------

//--------------------- iType CURL_EASY_GETINFO parameter ----------------------------------------
//	---- iOption ----		---- Type ----
//	HB_CURLINFO_EFFECTIVE_URL:		C
//	HB_CURLINFO_RESPONSE_CODE:		N
//	HB_CURLINFO_HTTP_CONNECTCODE:		N
//	HB_CURLINFO_FILETIME:			N
//	HB_CURLINFO_TOTAL_TIME:			N
//	HB_CURLINFO_NAMELOOKUP_TIME:		N
//	HB_CURLINFO_CONNECT_TIME:		N
//	HB_CURLINFO_PRETRANSFER_TIME:		N
//	HB_CURLINFO_STARTTRANSFER_TIME:		N
//	HB_CURLINFO_REDIRECT_TIME:		N
//	HB_CURLINFO_REDIRECT_COUNT:		N
//	HB_CURLINFO_REDIRECT_URL:		C
//	HB_CURLINFO_SIZE_UPLOAD:		N
//	HB_CURLINFO_SIZE_DOWNLOAD:		N
//	HB_CURLINFO_SPEED_DOWNLOAD:		N
//	HB_CURLINFO_SPEED_UPLOAD:		N
//	HB_CURLINFO_HEADER_SIZE:		N
//	HB_CURLINFO_REQUEST_SIZE:		N
//	HB_CURLINFO_SSL_VERIFYRESULT:		N
//	HB_CURLINFO_SSL_ENGINES:		A
//	HB_CURLINFO_CONTENT_LENGTH_DOWNLOAD:	N
//	HB_CURLINFO_CONTENT_LENGTH_UPLOAD:	N
//	HB_CURLINFO_CONTENT_TYPE:		C
//	HB_CURLINFO_PRIVATE:			Ptr
//	HB_CURLINFO_HTTPAUTH_AVAIL:		N
//	HB_CURLINFO_PROXYAUTH_AVAIL:		N
//	HB_CURLINFO_OS_ERRNO:			N
//	HB_CURLINFO_NUM_CONNECTS:		N
//	HB_CURLINFO_COOKIELIST:			A
//	HB_CURLINFO_LASTSOCKET:			N
//	HB_CURLINFO_FTP_ENTRY_PATH:		C
//	HB_CURLINFO_PRIMARY_IP:			C
//	HB_CURLINFO_APPCONNECT_TIME:		N
//	HB_CURLINFO_CERTINFO:			A
//	HB_CURLINFO_CONDITION_UNMET:		N
//	HB_CURLINFO_RTSP_SESSION_ID:		C
//	HB_CURLINFO_RTSP_CLIENT_CSEQ:		N
//	HB_CURLINFO_RTSP_SERVER_CSEQ:		N
//	HB_CURLINFO_RTSP_CSEQ_RECV:		N
//	HB_CURLINFO_PRIMARY_PORT:		N
//	HB_CURLINFO_LOCAL_IP:			C
//	HB_CURLINFO_LOCAL_PORT:			N
//--------------------- End of iType CURL_EASY_GETINFO parameter ----------------------------------------


CLASS oCurl INHERIT HObject
	EXPORT	aDefOptions	INIT {}				// Default options
	EXPORT	baseUrl		INIT ""				// Базовый url для запросов
	EXPORT	TLScert		INIT "curl-ca-bundle.crt"	// Путь к сертификату TLS/SSL
	EXPORT	lCurlExe	INIT .F.			// .T. - curl.exe, .F. - libcurl
	EXPORT	iLog 		INIT 0			// /log=	0	Ничего не выводим
							//		1	Ошибки
							//		2	Основной протокол
							//		4	Трассировка важных сообщений
							//		8	Трассировка всех сообщений
							//		16	Сохранение запросов и ответов
							//		32	Игнорировать ошибки в дате
							//		64	Автозапуск гашения без меню

	METHOD CleanUp(h)			INLINE CURL_EASY_CLEANUP(h)
	METHOD Close()				INLINE CURL_GLOBAL_CLEANUP()
	METHOD DLBuffGet(h)			INLINE CURL_EASY_DL_BUFF_GET(h)
	METHOD Duplicate(h)			INLINE CURL_EASY_DUPLICATE(h)
	METHOD Escape(h, s)			INLINE CURL_EASY_ESCAPE(h, s)
	METHOD GetDate(d)			INLINE CURL_GETDATE(d)	// This returns the number of seconds since January 1st 1970 in the UTC time zone
	METHOD GetInfo(h, iType, nError)	INLINE CURL_EASY_GETINFO(h, iType, @nError)	// curl_easy_getinfo( curl, x, @nError ) -> xValue
	METHOD Handle()				INLINE CURL_EASY_INIT()
	METHOD New(baseUrl, lCurlExe, TLScert, iLog, aOptions, iGlobalSettings)
	METHOD outLog(iFlag, cMsg, cAdd)							// Вывод сообщений
	METHOD Pause(h, iPause)			INLINE CURL_EASY_PAUSE(h, iPause)
	METHOD Perform(h)			INLINE CURL_EASY_PERFORM(h)
	METHOD Recieve(h, cBuffer)		INLINE CURL_EASY_RECV(h, @cBuffer)		// curl_easy_recv( curl, @cBuffer ) -> nResult
	METHOD Reset(h)				INLINE CURL_EASY_RESET(h)
	METHOD Run(aAct, aOptions, cIn)								// Запрос curl
	METHOD Send(h, cBuffer, nSentBytes)	INLINE CURL_EASY_SEND(h, cBuffer, @nSentBytes)	// curl_easy_send( curl, cBuffer, @nSentBytes ) -> nResult
	METHOD SetOpt(h, iOption, uOption)	INLINE CURL_EASY_SETOPT(h, iOption, uOption)
	METHOD StrError(nError)			INLINE CURL_EASY_STRERROR(nError)
	METHOD UnEscape(h, s)			INLINE CURL_EASY_UNESCAPE(h, s)
	METHOD Version()			INLINE CURL_VERSION()
	METHOD VersionInfo()			INLINE CURL_VERSION_INFO()
ENDCLASS
	
//---------- oCurl:New ------------------------------------------------------------------------------------------------------------
METHOD New(baseUrl, lCurlExe, TLScert, iLog, aOptions, iGlobalSettings) CLASS oCurl
	LOCAL r

	IF !Empty(baseUrl);	::baseUrl := baseUrl;			ENDIF
	IF !IsNil(lCurlExe);	::lCurlExe := lCurlExe;			ENDIF
	IF !Empty(TLScert);	::TLScert := TLScert;			ENDIF
	IF !IsNil(iLog);	::iLog := iLog;				ENDIF
	IF !IsNil(aOptions);	::aDefOptions := AClone(aOptions);	ENDIF
	IF IsNil(iGlobalSettings)
		r := CURL_GLOBAL_INIT()
	ELSE
		r := CURL_GLOBAL_INIT(iGlobalSettings)
	ENDIF
	RETURN IIF(r = 0, SELF, NIL)

//---------- oCurl:outLog ----------------------------------------------------------------------------------------------------------
METHOD outLog(iFlag, cMsg, cAdd) CLASS oCurl		// Вывод сообщений
	IF IsSet(iFlag, ::ILog)
		IF iFlag = 1 .OR. cMsg = "*"
			LogErr(cMsg, cAdd)
		ELSE
			LogStd(cMsg, cAdd)
		ENDIF
		IF IsSet(iFlag, 32)
			? cMsg
		ENDIF
	ENDIF
	RETURN .T.

//---------- oCurl:Run ------------------------------------------------------------------------------------------------------------
METHOD Run(aAct, aOptions, cIn) CLASS oCurl	// Запрос curl
							// aAct:	{Переменная часть url, Шаблон curl.exe}
							// aOptions:	Для curl.exe - список доп. параметров &1, &2...
							//		для libcurl - список для :SetOpt
							// cIn:		Data to POST
	LOCAL j, r, curlHandle, curlErr, cDopUrl, cTempl, cBat, cLog
	LOCAL cToken

	IF ValType(aAct) = "C";		aAct := {aAct, ""};		ENDIF
	IF ValType(aOptions) = "C";	aOptions := {aOptions};		ENDIF
	cDopUrl := aAct[1]
	cTempl  := aAct[2]
	IF !Empty(aOptions);		cToken := aOptions[1];		ENDIF	// Выделение token, чтоб не гнать его в log

	IF !("HTTP" $ Upper(cDopUrl));	cDopUrl := ::baseUrl + cDopUrl;	ENDIF

	DO CASE
		CASE ::lCurlExe						// ----------curl.exe----------
			IF !IsNil(cIn);	hb_Memowrit("curlin.txt", cIn);	ENDIF
			IF !Empty(aOptions)
				FOR j:=1 TO Len(aOptions)
					cTempl  := StrTran(cTempl,  "&" + NTrim(j), aOptions[j])
					cDopUrl := StrTran(cDopUrl, "&" + NTrim(j), aOptions[j])
				NEXT
			ENDIF
			cTempl := StrTran(cTempl, "&url", '"' + cDopUrl + '"')
			cTempl := StrTran(cTempl, "%", "%%")			// This is .bat file !!!
			cTempl := StrTran(cTempl, "&", "^&")			// This is .bat file !!!
			cBat := "curl -o curlout.txt " + cTempl
			cLog := cBat
			IF ValType(cToken) = "C";	cLog := StrTran(cLog, cToken, "<token>");	ENDIF
			::outLog(16, "Request :" + cLog)
			hb_Memowrit("curl.bat", cBat + CRLF)
			hb_Run("curl.bat")
			IF !FWait("curlout.txt")
				ErrMes("Нет ответа от curl " + cTempl)
			ELSE
				r := hb_Memoread("curlout.txt")
			ENDIF

		CASE Empty(curlHandle := ::Handle());	ErrMes("No curl handle")

		OTHERWISE							// ---------libcurl-----------
			FOR j:=1 TO Len(::aDefOptions)				// Default options
				::SetOpt(curlHandle, ::aDefOptions[j,1], ::aDefOptions[j,2])
			NEXT
			::SetOpt(curlHandle, HB_CURLOPT_URL, cDopUrl)		// Set URL
			::SetOpt(curlHandle, HB_CURLOPT_DOWNLOAD)		// Setup response data
//			::SetOpt(curlHandle, HB_CURLOPT_DL_FILE_SETUP, cFile)	// Download to file
			::SetOpt(curlHandle, HB_CURLOPT_DL_BUFF_SETUP)		// Download to buffer
			::SetOpt(curlHandle, HB_CURLOPT_CAINFO, ::TLScert)
		        
			IF !Empty(aOptions)
				FOR j:=1 TO Len(aOptions)			// Parameter options
					IF ::SetOpt(curlHandle, aOptions[j,1], aOptions[j,2]) # 0
						ErrMes("cUrl: Bad parameter " + NTrim(aOptions[j,1]))
					ENDIF
				NEXT
			ENDIF
		        
			::outLog(16, "Request :" + cDopUrl)
			IF Empty(curlErr := ::Perform(curlHandle))		// Do everything
				r := ::DLBuffGet(curlHandle)			// Store response in variable
			ELSE
				ErrMes(::StrError(curlErr))
			ENDIF
			::CleanUp(curlHandle)					// Clean-up libcurl
	ENDCASE
	IF !Empty(r);	::outLog(16, "Responce :" + r);	ENDIF
	RETURN r


