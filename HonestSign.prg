// From Z:\Harbour\hb32\tests\ipsvr.prg 
// Проверял: КриптоПро 4.0. ..., РуТокен ЭЦП 2.0
// -	Если нет сертификата из РуТокена в Личных сертификатах - переустановить Драйверы РуТокен с их сайта. Появился.
// -	В КриптоПро можно настроить кэширование PIN ("Безопасность"). Но можно и через KeyPin. Иначе спрашивает каждый раз
// -	Похоже, CAPICOM не умеет делать CADES_BES. Поэтому - CADESCOM.
// -	В oSignedData:Content := ... один раз возникла ошибка "Недопустимые данные" - хз откуда
// -	ThumbPrint сертификата:
//		XP	Пуск - Панель управления - Свойства браузера - Содержание - Сертификаты - Свойства 
//		Win10	Пуск - Параметры - Найти параметр - Серт... - Управление сертификатами пользователей - Личное (certmgr)

// Сработало, наконец (получил  token):
// curl -o curlout0.txt -H "content-type: application/json;charset=UTF-8" --data-binary @curlin0.txt https://ismp.crpt.ru/api/v3/auth/cert/ >errors.txt

// Пример запросов на разагрегирование:
// Из документации
// 1 (MWWRuza): https://ismotp.crptech.ru/private-office-api/private/v2/cis/aggregated?cis=%2801%2904600439935605%2821%29YUrW80L800510000093heav24014422555
// 2 (ИС МОТП): GET https://ismotp.crptech.ru/private-office-api/private/v2/cis/aggregated/{КМ} HTTP/1.1
//	Content-Type: application/json
//	Authorization: Bearer eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiI0MSIsImNuIjoiZm9pdiIsInBpZCI6MTExMSwiaW5uIjoiNzcwNzMyOTE1MiIsInBlcm1zIjoiMDlhMCJ9.0Ju2MwpcGGk_Qtjf9AWGoludQ-mIY760K7aYZtQCeVK6kTDMFfKo6Pr7X8CwEdyWfO2L1kCOC-cJaw1VilbNhQ
// 3(True API): https://ismotp.crptech.ru/api/v3/true-api/cises/aggregated/list?codes=000000462106549OOv1s0XzlzIFDjtcXJjz5cB&codes=(01)00000046210654(21)oFTjHaM&codes=00000046210654QuHCUeP
//	Authorization: Bearer <ТОКЕН>

#include "hbvo.ch"
#include "hbmacro.ch"
#include "hbcurl.ch"

	REQUEST HB_CODEPAGE_RU1251	// только для HBR100

PROCEDURE Main()
	LOCAL i, j, k, a, c, cMark, aMarks, aInt, aDir, cFile, oXml, oldLogging, iAction
	LOCAL cName := "HonestSign"
	LOCAL cVersion := "1.01"
	LOCAL aActions := {	"Получить входящие документы",;
				"Тест списка документов",;
				"Тест агрегации",;
				"Тест разбора документов", ;
				"Тест поиска имен в XML"}
	LOCAL oCrpt
	LOCAL oError

//	PUBLIC fnc1 := e"\x1D"		// Символ M->fnc1 для GS1/DataMatrix или EAN128

	BEGIN SEQUENCE  WITH {|errobj| ErrMacro(errobj)}

		IF !SetStd(cName, cVersion);	BREAK;	ENDIF
		FErase("crpt.txt")
		oCrpt := oCrpt{}				// Открытие сессии
		IF !oCrpt:OK .OR. !oCrpt:Open();	BREAK "Unable to open session";			ENDIF
		oldLogging := M->pubLogging

		iAction := 1				// По умолчанию - Получить входящие документы

		DO WHILE IsSet(oCrpt:iLog, 64) .OR. (iAction := MENU_ONE(,, aActions, "Выберите функцию")) # 0
			IF LastKey() = 27;	EXIT;	ENDIF
			M->pubLogging := oldLogging
			LowMes()
			IF "Тест" $ aActions[iAction]		// Список тестируемых интерфейсов
				aInt := oCrpt:aInterfaces
				aInt := AskOne(Padr(aInt,10),"Список интерфейсов ",,"@S10")
				IF IsNil(aInt);		EXIT;		ENDIF
				aInt := AllTrim(aInt)
			ENDIF
			DO CASE
				CASE iAction = 1		// Получить входящие документы
					k := 0
					M->pubLogging := _Or(M->pubLogging, 2)		// NO DIALOG
					oCrpt:SetInterface(oCrpt:cMInterface)
					IF oCrpt:Authorize()
						aDir := Directory(oCrpt:cFIDir + "*.xml")
						FOR j:=1 TO Len(aDir)
							cFile := oCrpt:cFIDir + aDir[j,F_NAME]
							IF oCrpt:DParse(cFile)
								FErase(cFile)	// ???
							ENDIF
							k++
						NEXT
					ENDIF
					IF k > 0;	LowMes("Crpt: " + NTrim(k) + " recieved");	ENDIF
				CASE iAction = 2		// Тест списка документов
					FOR i:=1 TO Len(aInt)
						oCrpt:cDInterface := CharPos(aInt, i)
						LogIt("crpt.txt", "Dok Interface: " + oCrpt:cDInterface)

						oCrpt:SetInterface(oCrpt:cDInterface)
						IF oCrpt:Authorize()
							oCrpt:DList("IDList")
							oCrpt:DList("ODList")
						ENDIF
					NEXT
				CASE iAction = 3		// Тест агрегации
					FOR i:=1 TO Len(aInt)
						oCrpt:cMInterface := CharPos(aInt, i)
						LogIt("crpt.txt", "Marks Interface " + oCrpt:cMInterface)
						oCrpt:SetInterface(oCrpt:cMInterface)
						IF oCrpt:Authorize()
							aMarks := hb_ATokens(hb_Memoread("marks.txt"), CRLF)
							FOR j:=1 TO Len(aMarks)
								IF !Empty(cMark := aMarks[j])
									LogIt("crpt.txt", "Marks " + aMarks[j] + ": " + oCrpt:Aggregate(cMark))
								ENDIF
							NEXT
						ENDIF
					NEXT
				CASE iAction = 4		// Тест разбора документов
					FOR i:=1 TO Len(aInt)
						oCrpt:cMInterface := CharPos(aInt, i)
						LogIt("crpt.txt", "Doc parsing " + oCrpt:cMInterface)
						oCrpt:SetInterface(oCrpt:cMInterface)
						IF oCrpt:Authorize()
							aDir := Directory(oCrpt:cFIDir + "*.xml")
							FOR j:=1 TO Len(aDir)
								cFile := oCrpt:cFIDir + aDir[j,F_NAME]
								oCrpt:DParse(cFile)
								FErase(cFile)	// ???
							NEXT
						ENDIF
					NEXT
				CASE iAction = 5		// Тест поиска имен в XML
					c := ""
					DO WHILE !Empty(c := AskOne(Padr(c,100),"Поисковый запрос ",,"@S30"))
						c := AllTrim(c)
						aDir := Directory(oCrpt:cFIDir + "*.xml")
						FOR j:=1 TO Len(aDir)
							cFile := oCrpt:cFIDir + aDir[j,F_NAME]
							LogIt("crpt.txt", "Поиск " + c + " в " + cFile)
							oXml := oXML{,, cFile}
//							a := oXml[c]
							a := oXml:FindNodes(c)		// As value
							IF !(ValType(a) = "A");	a := {a};	ENDIF
							FOR i:=1 TO Len(a)
								LogIt("crpt.txt", "     " + IIF(Empty(a[i]), "Empty", a[i]))
							NEXT

							a := oXml:FindNodes(c, 1)	// As object
							IF !(ValType(a) = "A");	a := {a};	ENDIF
							FOR i:=1 TO Len(a)
								LogIt("crpt.txt", "     " + IIF(Empty(a[i]), "Empty", a[i]:cXmlName))
							NEXT
						NEXT
					ENDDO
			ENDCASE
			IF IsSet(oCrpt:iLog, 64);	EXIT;	ENDIF
		ENDDO

	RECOVER USING oError
		IF !EMPTY(oError);	YesErr(cName, oError);	ENDIF
	END
	IF !Empty(oCrpt);	oCrpt:Close();	ENDIF
	QUIT

//---------- SetStd ------------------------------------------------------------------------------------------------------------
FUNCTION SetStd(cName, cVersion)
        LOCAL i, j, r:=.F., c, s, l1, kTitle, kVert
	LOCAL oError

	DefPub("macro_errb", {|oError| ErrMacro(oError)})
	BEGIN SEQUENCE  WITH {|errobj| ErrMacro(errobj)}

		IF MaxRow() = 299;	hb_Run("mode con cols=80 lines=25");	ENDIF	// Установлен дурацкий буфер экрана по умолчанию 300 строк
		kVert := INT((Maxrow() - 21) / 2)
		hb_cdpSelect(hb_cdpOs())		// По умолчанию

		DefPub("fnc1", e"\x1D")			// Символ M->fnc1 для GS1/DataMatrix или EAN128
		DefPub("pubLogging", 0)			// Режим логов (0 = Можно все), д.б. ЗДЕСЬ
							// 	1	Запрет Логов
							//	2	Запрет Диалогов
							//	4	Запрет клавы
							//	8	Запрет дублирования ошибки в LowMes

		DefPub("pubAds", 1)			// 1 - ADS для cSysCtl, 2 - ADS для прочих
		LogStd(cName + " started")
	        
		SET DELETED ON
		SET WRAP ON
		SET CONFIRM ON
		SET DATE BRITISH
		SET EPOCH TO 1980
		SET( _SET_EVENTMASK, INKEY_ALL) 
		mSetCursor( .T. )
	        
// Экранная херня
		SETCOLOR("W/B,B/W,,,B/W")
		CLEAR SCREEN
		s := MEMOREAD("title.txt")		
		l1 := INT((Maxcol()-LEN(TRIM(MEMOLINE(s, Maxcol(),1))))/2)
		kTitle := MLCount(s, Maxcol())
		FOR i:=1 TO kTitle
			c := TRIM(MEMOLINE(s, Maxcol(), i))
			IF (j:=At("V.M", c)) > 0
				c := Left(c, j+2) + " " + cVersion + " от " + DToC(FDate(cName + ".exe"))
			ENDIF
			IF (j:=AT("2019-",c)) > 0;	c := STUFF(c, j+5, 4, STR(YEAR(DATE()),4));	ENDIF
			@ i + kVert, l1 SAY c
		NEXT
		r := .T.

	RECOVER USING oError
		IF !EMPTY(oError);	YesErr(cName, oError);	ENDIF
	END
	RETURN r

//---------- oCrpt ------------------------------------------------------------------------------------------------------------
CLASS oCrpt INHERIT HObject	// Класс для работы с Честным знаком
	CLASS VAR aSessions	INIT {}
	PROTECT niSys 		INIT 1			// Текущая версия программы
	PROTECT niRelease 	INIT 0			// Текущий релиз программы
	PROTECT handle		INIT 0			// Session handle
	PROTECT	aoDS		INIT {}			// oDS List
	PROTECT intCp
	EXPORT	lOpened		INIT .F.		// Сессия открыта
	PROTECT cLogFile 	INIT "errlog.txt"	// LOG
	PROTECT cPath		INIT ""			// Базовый dir
	PROTECT aIni					//{ => } .INI file
	PROTECT selfName 	INIT "HonestSign"
	PROTECT	oCert		INIT NIL		// Объект сертификата для подписи
	EXPORT	oCurl		INIT NIL		// Объект curl
	EXPORT	token		INIT ""			// token сессии
	EXPORT	lCurlExe	INIT .F.		// .T. - curl.exe, .F. - libcurl
	EXPORT	Actions		INIT {"Token", "Auth", "IDList", "ODList", "IDoc", "ODoc", "Marks"}
	EXPORT	hAct		INIT { => }

//================= Из .ini файла ===============================================
	EXPORT	iLog 		INIT 7			// /log=	0	Ничего не выводим
							//		1	Ошибки
							//		2	Основной протокол
							//		4	Трассировка важных сообщений
							//		8	Трассировка всех сообщений
							//		16	Сохранение запросов и ответов
							//		32	Игнорировать ошибки в дате
							//		64	Автозапуск гашения без меню
	EXPORT	iMode		INIT 0			// Режим:	1 - Вход в SignText преобразовать в Base64
							//		2 - Выход из SignText преобразовать в Base64
							//		4 - SignText: crptest.exe (иначе CAPICOM/CADESCOM), !!!Path!!!
							//		8 - Отправка токена через curl.exe (иначе libcurl)
							// Отправка токена работает при: 1, 8+1, 8+4
	PROTECT	curlUrl		INIT ""			// Базовый url crpt
	EXPORT	cThumbprint	INIT ""			// Thumbprint сертификата для подписи
	EXPORT	keyPin		INIT ""			// PIN РуТокен
//	PROTECT	cSysCtl		INIT ""			// Путь к БД
	EXPORT	TLScert		INIT "curl-ca-bundle.crt"	// Путь к сертификату TLS/SSL
	PROTECT	Limit		INIT 40			// Суточный лимит гашений
	EXPORT	dOffset		INIT 0			// Последний день гашения = Date() + ::dOffset
	EXPORT	iTimeOut	INIT 600		// TimeOut в сек. ожидания ответа не двойной запрос
	EXPORT	iInterval 	INIT 10			// Интервал в сек. перезапроса ответа на двойной запрос
	EXPORT	cInterface	INIT ""			// Текущая Версия интерфейса с ЦРПТ
	EXPORT	cDInterface	INIT "A"		// Стандартный интерфейс для получения документов
	EXPORT	cMInterface	INIT "A"		// Стандартный интерфейс для агрегирования марок
	EXPORT	aInterfaces	INIT NIL		// Список доступных интерфейсов
	EXPORT	cFIDir		INIT ""			// Директория для входящих файлов документов .xml
	EXPORT	oUtm		INIT NIL

//================= /Из .ini файла ===============================================

	METHOD Aggregate(cMark, cId, aMarks, aCurl)	// Запрос агрегирования марки cMark и внесение результата в aMarks
	METHOD Authorize()				// Авторизация в CRPT
	METHOD Close()					// Close session
	METHOD DList(cAction)				// Список документов CRPT
	METHOD DParse(cFile)				// Разбор входящего документа из файла cFile, создание списка марок и запись в oUTM
	METHOD MAggregate(cMark)			// Запрос агрегирования марки cMark
	METHOD New()					// Создание: Без параметров, на случай OLE
	METHOD Open()	// Инициализация
	METHOD outLog(iFlag, cMsg, cAdd)		// Вывод сообщений
	METHOD RestInterface(savInterface)		// Восстановление параметров текущего интерфейса
	METHOD SaveInterface()				// Сохранение параметров текущего интерфейса
	METHOD SetInterface(cInterface)			// Настройка описателя ::hAct для используемой версии интерфейса для каждой 
	
ENDCLASS

//---------- oCrpt:Aggregate ------------------------------------------------------------------------------------------------------
METHOD Aggregate(cMark, cId, aMarks, aCurl) CLASS oCrpt	// Запрос агрегирования марки cMark и внесение результата в aMarks
	LOCAL i, a, cCurl:="", oError, cType, jMark, kReply, maxReply:=10, iSleep:=60, kErr:=0, cErr
	LOCAL aErr := {	"Empty answer",;
			"No sublevels",;
			"Connection error",;
			"Code not found",;
			"50x error",;
			"Unknown error",;
			"json parsing error"}


	IF IsNil(cId);		cId := "";	ENDIF
	IF IsNil(aMarks);	aMarks := {};	ENDIF
	BEGIN SEQUENCE WITH {|oError| ErrMacro(oError)}
		a := NormBar(XML2String(cMark), 1)			// Скобочный формат
		cMark := a[1]
		IF Empty(cType := a[2]);	cType := "ЯУ";	ENDIF	// Короб
		AAdd(aMarks, {cId, cType, cMark, 0, TabMrc(cMark), 0})	// tovId, ЯБ/ЯТ, Марка, КоличествоВУпаковке, МРЦ, err
		jMark := Len(aMarks)

		FOR kReply:=1 TO maxReply
			kErr := 0
			DO CASE
				CASE cType = "ЯТ";	aMarks[jMark, 4] := 1		// Это пачка: Дальше не разбираем, количество = 0
				CASE !Empty(aCurl)					// Поддерево марок уже есть. Если нет - запрос CRPT
				CASE Empty(cCurl:=::MAggregate(cMark));	kErr := 1	// Пустой ответ
				CASE cCurl = "[]";			kErr := 2	// Марка зарегистрирована, но не разбирается
				CASE "curl:" $ cCurl;			kErr := 3	// Проблема с curl/связью
				CASE '"code":404' $ cCurl;		kErr := 4	// Код не найден
				CASE "<title>50" $ cCurl;		kErr := 5	// Bad gateway, Service unavailable, Internal error...
				CASE "error" $ Lower(cCurl);		kErr := 6	// Иная ошибка
				CASE hb_jsonDecode(cCurl, @aCurl, hb_cdpSelect()) = 0
									kErr := 7	// Ошибка разбора данных
			ENDCASE
			cErr := DTOC(DATE()) + " " + Time() + " Aggregate: " + cMark + "  " + IIF(kErr = 0, "OK", aErr[kErr])
			LowMes(cErr, IIF(kErr = 0, NIL, -2))
			IF AScan({3,5}, kErr) = 0;	EXIT;	ENDIF
			hb_IdleSleep(iSleep)
			FOR i:=1 TO maxReply
				IF ::Authorize();	EXIT;	ENDIF
				hb_IdleSleep(iSleep)
			NEXT
		NEXT
		aMarks[jMark,6] := kErr						// Код ошибки, если есть

		IF !Empty(aCurl)
			aMarks[jMark, 4] := Len(aCurl)			// В марку заносим число ее сыновей
			FOR i:=1 TO Len(aCurl)
				IF ValType (aCurl[i]) # "A";	aCurl[i] := {aCurl[i], {}};	ENDIF
				::Aggregate(aCurl[i,1], cId, aMarks, aCurl[i,2])
			NEXT
		ENDIF

	RECOVER USING oError
		IF !EMPTY(oError);	YesErr("Aggregate", oError);	ENDIF
	END
	RETURN cCurl

//---------- oCrpt:Authorize ------------------------------------------------------------------------------------------------------
METHOD Authorize() CLASS oCrpt	// Авторизация в CRPT
	LOCAL a, r:=.T., cCurl, hCurl, cData, cJson
	LOCAL oError

	BEGIN SEQUENCE WITH {|oError| ErrMacro(oError)}

		::token := NIL
		IF Empty(::oCurl);					BREAK "cUrl не загружен";	ENDIF
		::oCurl:aDefOptions := {}

// Запрос случайного числа для получения токена
		IF Empty(cCurl := ::oCurl:Run(::hAct["Token"]));	BREAK "Ошибка запроса данных";	ENDIF
		IF hb_jsonDecode(cCurl, @hCurl, hb_cdpSelect()) = 0;	BREAK "Ошибка разбора данных";	ENDIF
		IF IsNil(hb_HGetDef(hCurl, "uuid")) .OR.;
		   IsNil(hb_HGetDef(hCurl, "data"))
			BREAK "Ошибка разбора"
		ENDIF

// Авторизация и запрос токена
		cData := hCurl["data"]
		hCurl["data"] := SignText(hb_strToUTF8(cData), ::oCert, .F., ::keyPin, ::iMode)	// Attached
		cJson := hb_jsonEncode(hCurl)
		IF ::lCurlExe						// Отправка средствами curl.exe
			cCurl := ::oCurl:Run(::hAct["Auth"],, cJson)
		ELSE							// Отправка средствами curl_easy
			a := {	{HB_CURLOPT_HTTPHEADER, {"content-type: application/json;charset=UTF-8"}},;
				{HB_CURLOPT_POST, 1}, ;							// Specify the POST data
				{HB_CURLOPT_POSTFIELDS, cJson}	}
			cCurl := ::oCurl:Run(::hAct["Auth"], a)
		ENDIF
		IF Empty(cCurl);		BREAK "Ошибка токена";		ENDIF
		IF "error" $ Lower(cCurl) .OR. !("token" $ cCurl)
			LogIt("crpt.txt", "Error: " + hb_jsonEncode(hCurl) + CRLF + cCurl)
			BREAK cCurl
		ENDIF
		LogIt("crpt.txt", "OK: " + cCurl)
		IF hb_jsonDecode(cCurl, @hCurl, hb_cdpSelect()) = 0;	BREAK "Ошибка разбора токена";	ENDIF
		::token := hCurl["token"]
		r := !Empty(::token)
	RECOVER USING oError
		IF !EMPTY(oError);	r := YesErr("Authorize", oError);	ENDIF
	END
	RETURN r

//---------- oCrpt:Close ----------------------------------------------------------------------------------------------------------
METHOD Close() CLASS oCrpt		// Close session
	::oCert := NIL			// Sic!!! Без этого, если ::oCert создан, все слетает в ACCESS VIOLATION
	IF !Empty(::oUtm);	::oUtm:Close();		ENDIF
	IF !Empty(::oCurl);	::oCurl:Close();	ENDIF
	::outLog(2, "Session closed")
	::lOpened := .F.
	RETURN SELF

//---------- oCrpt:DokList ------------------------------------------------------------------------------------------------------
METHOD DList(cAction) CLASS oCrpt	// Список входящих документов CRPT
	LOCAL a, cCurl, oError

	BEGIN SEQUENCE WITH {|oError| ErrMacro(oError)}

//curl 'https://ismp.crpt.ru/api/v3/facade/doc/listV2?limit=10&order=DESC
//&orderColumn=docDate&did=623136d3-7a9b-40c9-8ce3-8091e41f83aa&orderedColumnValue=2019-01-28T09:30:40.136Z
//&pageDir=NEXT' -H 'content-type:application/json' -H 'Authorization: Bearer <>'

// curl '<url стенда>/api/v3/true-api/doc/listV2?limit=10&order=DESC&orderColumn=docDate&did=623136d3-7a9b-40c9-8ce3-8091e41f83aa&orderedColumnValue=2019-01-28T09:30:40.136Z&pageDir=NEXT' -H 'content-type: application/json' -H 'Authorization: Bearer <ТОКЕН>'

// https://int.edo.crpt.tech/api/v1/outgoing-documents
// curl --location --request GET 'https://int.edo.crpt.tech/api/v1/outgoing-documents' \ --header 'authorization: Bearer eyJhbGciOiJIUzI1NiIsI...SpRMX7xBW-zJrUMZ7dLhytbcgmTSSI1ZrHorbb8'

		IF IsNil(cAction);	cAction := "IDList";	ENDIF
		IF ::lCurlExe						// Отправка средствами curl.exe
			cCurl := ::oCurl:Run(::hAct[cAction], ::token)
		ELSE							// Отправка средствами curl_easy
			a := {	{HB_CURLOPT_HTTPHEADER, {"content-type: application/json"},;
							{"Authorization: Bearer " + ::token}}}
			cCurl := ::oCurl:Run(::hAct[cAction], a)
		ENDIF
		IF Empty(cCurl);		BREAK "Ошибка запроса";		ENDIF
		IF "error" $ Lower(cCurl)
			LogIt("crpt.txt", "Error: " + CRLF + cCurl)
			BREAK cCurl
		ENDIF
		LogIt("crpt.txt", "OK: " + cCurl)

	RECOVER USING oError
		IF !EMPTY(oError);	YesErr("DList", oError);	cCurl := "";	ENDIF
	END
	RETURN cCurl

//---------- oCrpt:DParse ------------------------------------------------------------------------------------------------------
METHOD DParse(cFile) CLASS oCrpt	// Разбор входящего документа из файла cFile, создание списка марок и запись в oUTM
	LOCAL a, i, j, r:=.T., cMarks := "", oTabl, aTovs, aUpaks, cNomStr, aMarks, oXml, aInfPol, oDopSved, cMark, cType
	LOCAL savInterface, oError

	BEGIN SEQUENCE WITH {|oError| ErrMacro(oError)}
		IF !(Upper(Right(cFile,4)) = ".XML");		cFile += ".xml";		ENDIF
		IF !File(cFile);				BREAK "Нет файла";		ENDIF
		oXml := oXML{,, cFile}
		IF Empty(oXml);					BREAK "Пустой документ";	ENDIF
		IF Empty(oTabl := oXml["...ТаблСчФакт"]);	BREAK "Нет табличной части";	ENDIF
		IF Empty(aTovs := oTabl:GetSons("СведТов"));	BREAK "Нет товаров";		ENDIF
		aInfPol := oXml:FindNodes("ИдФайлИнфПол=")		// Ссылки на ранее полученные файлы
		
		FOR i:=1 TO Len(aTovs)
			aMarks := {}
			cNomStr := aTovs[i,"НомСтр="]
//			IF !Empty(oUpaks := aTovs[i, "...НомСредИдентТов"]) .AND. !Empty(aUpaks := oUpaks:GetSons("НомУпак"))
			IF !Empty(oDopSved := aTovs[i, "ДопСведТов"])
				IF !Empty(aUpaks := oDopSved:FindNodes("НомУпак"))		// Это упаковки маркированной фигни: Подключимся к сервису
					IF IsNil(savInterface)			
						savInterface := ::SaveInterface()
						::SetInterface(::cMInterface)	
						IF !::Authorize();	BREAK "Сервис недоступен";	ENDIF
					ENDIF
					FOR j:=1 TO Len(aUpaks)
						::Aggregate(aUpaks[j], cNomStr, aMarks)
					NEXT
				ENDIF
				IF !Empty(aUpaks := oDopSved:FindNodes("КИЗ"))			// Это единичная маркированная фигня: Не подключаемся к сервису, просто добавляем строку
					FOR j:=1 TO Len(aUpaks)
						a := NormBar(XML2String(aUpaks[j]), 1)			// Скобочный формат
						cMark := a[1]
						cType := a[2]						// Тип марки
						IF Empty(cType) .OR. cType = "ЯБ";	cType := "ЯЛ";	ENDIF	// Стандартная маркировка, Normbar может определить как ЯБ, но блока сигарет в КИЗ быть не может
						AAdd(aMarks, {cNomStr, cType, cMark, 1, TabMrc(cMark), 0})	// tovId, ЯБ/ЯТ, Марка, КоличествоВУпаковке, МРЦ, err
					NEXT
				ENDIF
			ENDIF
			FOR j:=1 TO Len(aMarks)		// {cId, cType, cMark, 0, TabMrc(cMark), 0}) tovId, ЯБ/ЯТ, Марка, КоличествоВУпаковке, МРЦ, err
				cMarks +=	aMarks[j,1] + " " + ;		// tovId
						aMarks[j,2] + " " + ;		// ЯУ/ЯБ/ЯТ
						aMarks[j,3] + " " + ;		// Марка
						NTrim(aMarks[j,4]) + " " + ;	// Число субмарок
						NTrim(aMarks[j,5],2) + " " + ;	// МРЦ
						NTrim(aMarks[j,6]) + CRLF	// Код ошибки (см, Utm:updTov())
			NEXT
		NEXT

// Регистрация в UTM

		IF !Empty(::oUtm)
			IF !::oUtm:EdoAppend(cFile, .F., aInfPol, cMarks);	BREAK "Документ игнорирован";	ENDIF
		ENDIF

	RECOVER USING oError
		IF ValType(oError) = "C";	oError += " " + cFile;		ENDIF
		IF !EMPTY(oError);		r := YesErr("DParse", oError);	ENDIF
	END
	::RestInterface(savInterface)
	RETURN r

//---------- oCrpt:MAggregate ------------------------------------------------------------------------------------------------------
METHOD MAggregate(cMark) CLASS oCrpt	// Запрос агрегирования марки cMark
	LOCAL a, cCurl:="", oError, cJson, cAction := "Marks"
	LOCAL lPost := ("POST" $ ::hAct[cAction, 2])

	BEGIN SEQUENCE WITH {|oError| ErrMacro(oError)}
		IF lPost
			cJson := '["' + cMark + '"]'
		ELSE
			cMark := urlEncode(cMark)
		ENDIF
	        
		DO CASE
			CASE ::lCurlExe .AND. lPost				// Отправка средствами curl.exe, POST
				cCurl := ::oCurl:Run(::hAct[cAction], {::token, cMark}, cJson)
	        
			CASE !::lCurlExe .AND. lPost				// Отправка средствами curl_easy, POST
				a := {	{HB_CURLOPT_HTTPHEADER, {"content-type: application/json;charset=UTF-8"},;
								{"Authorization: Bearer " + ::token}},;
					{HB_CURLOPT_POST, 1}, ;			// Specify the POST data
					{HB_CURLOPT_POSTFIELDS, cJson}	}
				cCurl := ::oCurl:Run(::hAct[cAction], a)
	        
			CASE ::lCurlExe .AND. !lPost				// Отправка средствами curl.exe, GET
				cCurl := ::oCurl:Run(::hAct[cAction], {::token, cMark})
	        
			CASE !::lCurlExe .AND. !lPost				// Отправка средствами curl_easy, GET
				cAction := StrTran(::hAct[cAction, 1], "&2", cMark)
				a := {	{HB_CURLOPT_HTTPHEADER, {"content-type: application/json"},;
								{"Authorization: Bearer " + ::token}}}
				cCurl := ::oCurl:Run(cAction, a)
		ENDCASE

//		IF !Empty(cCurl) .AND. ;
//		   !("error" $ Lower(cCurl)) .AND. !("400" $ cCurl) .AND. !("404" $ cCurl)
//			LogIt("crpt.txt", "Error: " + CRLF + cCurl)
//			BREAK cCurl
//		ENDIF
//		LogIt("crpt.txt", "OK: " + cCurl)

	RECOVER USING oError
		IF !EMPTY(oError);	YesErr("MAggregate", oError);	cCurl := "";	ENDIF
	END
	RETURN cCurl

//---------- oCrpt:New ----------------------------------------------------------------------------------------------------------
METHOD New() CLASS oCrpt	// Создание объекта: Без параметров, на случай OLE
	AAdd(::aSessions, SELF)
	::handle := ALen(::aSessions)
	::cPath := hb_dirBase()
	::intCp := hb_cdpOs()
	hb_cdpSelect(::intCp)		// По умолчанию
	LogStd(::selfName + " V.M " + NTrim(::niSys) + "." + NTrim(::niRelease))	
	RETURN SELF

//---------- oCrpt:Open ----------------------------------------------------------------------------------------------------------
METHOD Open() CLASS oCrpt	// Открытие сессии, на случай OLE

	LOCAL cFile, oError

	BEGIN SEQUENCE WITH {|oError| ErrMacro(oError)}

		DefPub("cSysCtl", "")

		IF ::lOpened;				BREAK;				ENDIF
		IF !File(cFile := ::selfName + ".ini");	BREAK cFile + " не найден";	ENDIF
		IF !Empty(::aIni := hb_iniRead(cFile)["MAIN"])
			::iLog		:= Val(hb_HGetDef(::aIni, "iLog",	NTrim(::iLog)))		// Уровень сообщений в Log
			::iMode		:= Val(hb_HGetDef(::aIni, "iMode",	NTrim(::iMode)))	// Режимы работы
			::Limit		:= Val(hb_HGetDef(::aIni, "Limit",	NTrim(::Limit)))	// Суточный лимит гашений
			::dOffset	:= Val(hb_HGetDef(::aIni, "dOffset",	NTrim(::dOffset)))	// Последний день гашения = Date() + ::dOffset
			::iTimeOut	:= Val(hb_HGetDef(::aIni, "iTimeOut",	NTrim(::iTimeOut)))	// TimeOut в сек. ожидания ответа не двойной запрос
			::iInterval	:= Val(hb_HGetDef(::aIni, "iInterval",	NTrim(::iInterval)))	// Интервал в сек. перезапроса ответа на двойной запрос

			::cThumbprint	:= hb_HGetDef(::aIni, "cThumbprint",	::cThumbprint)	// Thumbprint сертификата для подписи
			::keyPin	:= hb_HGetDef(::aIni, "keyPin",		::keyPin)	// PIN РуТокен
			M->cSysCtl	:= hb_HGetDef(::aIni, "cSysCtl",	M->cSysCtl)	// Путь к БД
			::TLScert	:= hb_HGetDef(::aIni, "TLScert",	::TLScert)	// Сертификат TLS/SSL
			::cDInterface	:= hb_HGetDef(::aIni, "cDInterface",	::cDInterface)	// Стандартный интерфейс для получения документов
			::cMInterface	:= hb_HGetDef(::aIni, "cMInterface",	::cMInterface)	// Стандартный интерфейс для агрегирования марок
		ENDIF

// DataBase
		IF !Empty(M->cSysCtl)				// Есть БД
			IF Right(M->cSysCtl,1) # "\";	M->cSysCtl += "\";	ENDIF
			SetAds()
			::oUtm := UTM{}
		ENDIF
// Curl
		::lCurlExe := IsSet(::iMode,8)			// libcurl/curl.exe
		::SetInterface()				// Настройка интерфейса ::hAct для используемой версии интерфейса для каждой функции из ::Actions
		IF Empty(::oCurl);	::oCurl := oCurl{::curlUrl, ::lCurlExe, ::TLScert, ::iLog};	ENDIF
		IF Empty(::oCurl);	BREAK "Ошибка загрузки cUrl";		ENDIF

// Проверка сертификата при загрузке
		IF Empty(::oCert := GetCert(::cThumbPrint));		BREAK;	ENDIF		// Сертификат по отпечатку
		IF !(StrTran(::cThumbPrint," ","") == StrTran(::oCert:Thumbprint," ","")) 	// Сертификат обновлен
			::aIni["cThumbprint"] := ::oCert:Thumbprint				// Обновим .ini
			hb_iniWrite(::selfName + ".ini", { "MAIN" => ::aIni })
		ENDIF

		::lOpened := .T.

	RECOVER USING oError
		::lOpened := YesErr(::selfName, oError)
	END

	IF ::lOpened;	::outLog(2, "Session opened");	ENDIF

	RETURN ::lOpened

//---------- oCrpt:outLog ----------------------------------------------------------------------------------------------------------
METHOD outLog(iFlag, cMsg, cAdd) CLASS oCrpt		// Вывод сообщений
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

//---------- oCrpt:RestInterface -------------------------------------------------------------------------------------
METHOD RestInterface(savInterface) CLASS oCrpt	// Восстановление параметров текущего интерфейса
	IF !Empty(savInterface)
		::SetInterface(savInterface[1])
		::token := savInterface[2]
	ENDIF
	RETURN SELF

//---------- oCrpt:SaveInterface -------------------------------------------------------------------------------------
METHOD SaveInterface() CLASS oCrpt	// Сохранение параметров текущего интерфейса
	RETURN {::cInterface, ::token}

//---------- oCrpt:SetInterface -------------------------------------------------------------------------------------
METHOD SetInterface(cInterface) CLASS oCrpt	// Настройка описателя ::hAct для используемой версии интерфейса для 
	LOCAL i, j, c, c2			// каждой функции из ::Actions и создание списка доступных интерфейсов

	IF Empty(cInterface);	cInterface := ::cDInterface;	ENDIF
	IF IsNil(::aInterfaces)
		::aInterfaces := ""			// Список доступных интерфейсов из имеющихся в .ini curlUrlX
		FOR j := Asc("A") TO Asc("Z")
			c := Chr(j)
			IF hb_HHasKey(::aIni, "curlUrl" + c);	::aInterfaces += c;	ENDIF
		NEXT
	ENDIF
	IF !(::cInterface == cInterface)
		::cInterface := cInterface
		::token := ""					// Чтоб не попал с чужого интерфейса
		::cFIDir := hb_HGetDef(::aIni, "cFIDir" + cInterface, "")
		::curlUrl := ::aIni["curlUrl" + cInterface]	// Базовый url версии интерфейса
		IF !Empty(::oCurl)				// Надо также заменить его в oCurl
			::oCurl:baseUrl := ::curlUrl
		ENDIF
		::hAct	  := { => }				// Описатели функций: {{Доп.url, строка curl.exe}}
		FOR i:=1 TO Len(::Actions)
			c := hb_HGetDef(::aIni, "curl" + ::Actions[i] + cInterface)
			IF !IsNil(c)
				c := AllTrim(c)			// Исходный описатель из .ini
				c2 := ""
				IF (j := At(",", c)) > 0
					c2 := AllTrim(Substr(c, j+1))
					c := AllTrim(Left(c, j-1))
				ENDIF
				::hAct[::Actions[i]] := {c, c2}	// Описатель функции: {Доп.url, строка curl.exe}
			ENDIF
		NEXT
	ENDIF
	RETURN .T.

