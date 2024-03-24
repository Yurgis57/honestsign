// From Z:\Harbour\hb32\tests\ipsvr.prg 
// ��������: ��������� 4.0. ..., ������� ��� 2.0
// -	���� ��� ����������� �� �������� � ������ ������������ - �������������� �������� ������� � �� �����. ��������.
// -	� ��������� ����� ��������� ����������� PIN ("������������"). �� ����� � ����� KeyPin. ����� ���������� ������ ���
// -	������, CAPICOM �� ����� ������ CADES_BES. ������� - CADESCOM.
// -	� oSignedData:Content := ... ���� ��� �������� ������ "������������ ������" - �� ������
// -	ThumbPrint �����������:
//		XP	���� - ������ ���������� - �������� �������� - ���������� - ����������� - �������� 
//		Win10	���� - ��������� - ����� �������� - ����... - ���������� ������������� ������������� - ������ (certmgr)

// ���������, ������� (�������  token):
// curl -o curlout0.txt -H "content-type: application/json;charset=UTF-8" --data-binary @curlin0.txt https://ismp.crpt.ru/api/v3/auth/cert/ >errors.txt

// ������ �������� �� ����������������:
// �� ������������
// 1 (MWWRuza): https://ismotp.crptech.ru/private-office-api/private/v2/cis/aggregated?cis=%2801%2904600439935605%2821%29YUrW80L800510000093heav24014422555
// 2 (�� ����): GET https://ismotp.crptech.ru/private-office-api/private/v2/cis/aggregated/{��} HTTP/1.1
//	Content-Type: application/json
//	Authorization: Bearer eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiI0MSIsImNuIjoiZm9pdiIsInBpZCI6MTExMSwiaW5uIjoiNzcwNzMyOTE1MiIsInBlcm1zIjoiMDlhMCJ9.0Ju2MwpcGGk_Qtjf9AWGoludQ-mIY760K7aYZtQCeVK6kTDMFfKo6Pr7X8CwEdyWfO2L1kCOC-cJaw1VilbNhQ
// 3(True API): https://ismotp.crptech.ru/api/v3/true-api/cises/aggregated/list?codes=000000462106549OOv1s0XzlzIFDjtcXJjz5cB&codes=(01)00000046210654(21)oFTjHaM&codes=00000046210654QuHCUeP
//	Authorization: Bearer <�����>

#include "hbvo.ch"
#include "hbmacro.ch"
#include "hbcurl.ch"

	REQUEST HB_CODEPAGE_RU1251	// ������ ��� HBR100

PROCEDURE Main()
	LOCAL i, j, k, a, c, cMark, aMarks, aInt, aDir, cFile, oXml, oldLogging, iAction
	LOCAL cName := "HonestSign"
	LOCAL cVersion := "1.01"
	LOCAL aActions := {	"�������� �������� ���������",;
				"���� ������ ����������",;
				"���� ���������",;
				"���� ������� ����������", ;
				"���� ������ ���� � XML"}
	LOCAL oCrpt
	LOCAL oError

//	PUBLIC fnc1 := e"\x1D"		// ������ M->fnc1 ��� GS1/DataMatrix ��� EAN128

	BEGIN SEQUENCE  WITH {|errobj| ErrMacro(errobj)}

		IF !SetStd(cName, cVersion);	BREAK;	ENDIF
		FErase("crpt.txt")
		oCrpt := oCrpt{}				// �������� ������
		IF !oCrpt:OK .OR. !oCrpt:Open();	BREAK "Unable to open session";			ENDIF
		oldLogging := M->pubLogging

		iAction := 1				// �� ��������� - �������� �������� ���������

		DO WHILE IsSet(oCrpt:iLog, 64) .OR. (iAction := MENU_ONE(,, aActions, "�������� �������")) # 0
			IF LastKey() = 27;	EXIT;	ENDIF
			M->pubLogging := oldLogging
			LowMes()
			IF "����" $ aActions[iAction]		// ������ ����������� �����������
				aInt := oCrpt:aInterfaces
				aInt := AskOne(Padr(aInt,10),"������ ����������� ",,"@S10")
				IF IsNil(aInt);		EXIT;		ENDIF
				aInt := AllTrim(aInt)
			ENDIF
			DO CASE
				CASE iAction = 1		// �������� �������� ���������
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
				CASE iAction = 2		// ���� ������ ����������
					FOR i:=1 TO Len(aInt)
						oCrpt:cDInterface := CharPos(aInt, i)
						LogIt("crpt.txt", "Dok Interface: " + oCrpt:cDInterface)

						oCrpt:SetInterface(oCrpt:cDInterface)
						IF oCrpt:Authorize()
							oCrpt:DList("IDList")
							oCrpt:DList("ODList")
						ENDIF
					NEXT
				CASE iAction = 3		// ���� ���������
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
				CASE iAction = 4		// ���� ������� ����������
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
				CASE iAction = 5		// ���� ������ ���� � XML
					c := ""
					DO WHILE !Empty(c := AskOne(Padr(c,100),"��������� ������ ",,"@S30"))
						c := AllTrim(c)
						aDir := Directory(oCrpt:cFIDir + "*.xml")
						FOR j:=1 TO Len(aDir)
							cFile := oCrpt:cFIDir + aDir[j,F_NAME]
							LogIt("crpt.txt", "����� " + c + " � " + cFile)
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

		IF MaxRow() = 299;	hb_Run("mode con cols=80 lines=25");	ENDIF	// ���������� �������� ����� ������ �� ��������� 300 �����
		kVert := INT((Maxrow() - 21) / 2)
		hb_cdpSelect(hb_cdpOs())		// �� ���������

		DefPub("fnc1", e"\x1D")			// ������ M->fnc1 ��� GS1/DataMatrix ��� EAN128
		DefPub("pubLogging", 0)			// ����� ����� (0 = ����� ���), �.�. �����
							// 	1	������ �����
							//	2	������ ��������
							//	4	������ �����
							//	8	������ ������������ ������ � LowMes

		DefPub("pubAds", 1)			// 1 - ADS ��� cSysCtl, 2 - ADS ��� ������
		LogStd(cName + " started")
	        
		SET DELETED ON
		SET WRAP ON
		SET CONFIRM ON
		SET DATE BRITISH
		SET EPOCH TO 1980
		SET( _SET_EVENTMASK, INKEY_ALL) 
		mSetCursor( .T. )
	        
// �������� �����
		SETCOLOR("W/B,B/W,,,B/W")
		CLEAR SCREEN
		s := MEMOREAD("title.txt")		
		l1 := INT((Maxcol()-LEN(TRIM(MEMOLINE(s, Maxcol(),1))))/2)
		kTitle := MLCount(s, Maxcol())
		FOR i:=1 TO kTitle
			c := TRIM(MEMOLINE(s, Maxcol(), i))
			IF (j:=At("V.M", c)) > 0
				c := Left(c, j+2) + " " + cVersion + " �� " + DToC(FDate(cName + ".exe"))
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
CLASS oCrpt INHERIT HObject	// ����� ��� ������ � ������� ������
	CLASS VAR aSessions	INIT {}
	PROTECT niSys 		INIT 1			// ������� ������ ���������
	PROTECT niRelease 	INIT 0			// ������� ����� ���������
	PROTECT handle		INIT 0			// Session handle
	PROTECT	aoDS		INIT {}			// oDS List
	PROTECT intCp
	EXPORT	lOpened		INIT .F.		// ������ �������
	PROTECT cLogFile 	INIT "errlog.txt"	// LOG
	PROTECT cPath		INIT ""			// ������� dir
	PROTECT aIni					//{ => } .INI file
	PROTECT selfName 	INIT "HonestSign"
	PROTECT	oCert		INIT NIL		// ������ ����������� ��� �������
	EXPORT	oCurl		INIT NIL		// ������ curl
	EXPORT	token		INIT ""			// token ������
	EXPORT	lCurlExe	INIT .F.		// .T. - curl.exe, .F. - libcurl
	EXPORT	Actions		INIT {"Token", "Auth", "IDList", "ODList", "IDoc", "ODoc", "Marks"}
	EXPORT	hAct		INIT { => }

//================= �� .ini ����� ===============================================
	EXPORT	iLog 		INIT 7			// /log=	0	������ �� �������
							//		1	������
							//		2	�������� ��������
							//		4	����������� ������ ���������
							//		8	����������� ���� ���������
							//		16	���������� �������� � �������
							//		32	������������ ������ � ����
							//		64	���������� ������� ��� ����
	EXPORT	iMode		INIT 0			// �����:	1 - ���� � SignText ������������� � Base64
							//		2 - ����� �� SignText ������������� � Base64
							//		4 - SignText: crptest.exe (����� CAPICOM/CADESCOM), !!!Path!!!
							//		8 - �������� ������ ����� curl.exe (����� libcurl)
							// �������� ������ �������� ���: 1, 8+1, 8+4
	PROTECT	curlUrl		INIT ""			// ������� url crpt
	EXPORT	cThumbprint	INIT ""			// Thumbprint ����������� ��� �������
	EXPORT	keyPin		INIT ""			// PIN �������
//	PROTECT	cSysCtl		INIT ""			// ���� � ��
	EXPORT	TLScert		INIT "curl-ca-bundle.crt"	// ���� � ����������� TLS/SSL
	PROTECT	Limit		INIT 40			// �������� ����� �������
	EXPORT	dOffset		INIT 0			// ��������� ���� ������� = Date() + ::dOffset
	EXPORT	iTimeOut	INIT 600		// TimeOut � ���. �������� ������ �� ������� ������
	EXPORT	iInterval 	INIT 10			// �������� � ���. ����������� ������ �� ������� ������
	EXPORT	cInterface	INIT ""			// ������� ������ ���������� � ����
	EXPORT	cDInterface	INIT "A"		// ����������� ��������� ��� ��������� ����������
	EXPORT	cMInterface	INIT "A"		// ����������� ��������� ��� ������������� �����
	EXPORT	aInterfaces	INIT NIL		// ������ ��������� �����������
	EXPORT	cFIDir		INIT ""			// ���������� ��� �������� ������ ���������� .xml
	EXPORT	oUtm		INIT NIL

//================= /�� .ini ����� ===============================================

	METHOD Aggregate(cMark, cId, aMarks, aCurl)	// ������ ������������� ����� cMark � �������� ���������� � aMarks
	METHOD Authorize()				// ����������� � CRPT
	METHOD Close()					// Close session
	METHOD DList(cAction)				// ������ ���������� CRPT
	METHOD DParse(cFile)				// ������ ��������� ��������� �� ����� cFile, �������� ������ ����� � ������ � oUTM
	METHOD MAggregate(cMark)			// ������ ������������� ����� cMark
	METHOD New()					// ��������: ��� ����������, �� ������ OLE
	METHOD Open()	// �������������
	METHOD outLog(iFlag, cMsg, cAdd)		// ����� ���������
	METHOD RestInterface(savInterface)		// �������������� ���������� �������� ����������
	METHOD SaveInterface()				// ���������� ���������� �������� ����������
	METHOD SetInterface(cInterface)			// ��������� ��������� ::hAct ��� ������������ ������ ���������� ��� ������ 
	
ENDCLASS

//---------- oCrpt:Aggregate ------------------------------------------------------------------------------------------------------
METHOD Aggregate(cMark, cId, aMarks, aCurl) CLASS oCrpt	// ������ ������������� ����� cMark � �������� ���������� � aMarks
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
		a := NormBar(XML2String(cMark), 1)			// ��������� ������
		cMark := a[1]
		IF Empty(cType := a[2]);	cType := "��";	ENDIF	// �����
		AAdd(aMarks, {cId, cType, cMark, 0, TabMrc(cMark), 0})	// tovId, ��/��, �����, �������������������, ���, err
		jMark := Len(aMarks)

		FOR kReply:=1 TO maxReply
			kErr := 0
			DO CASE
				CASE cType = "��";	aMarks[jMark, 4] := 1		// ��� �����: ������ �� ���������, ���������� = 0
				CASE !Empty(aCurl)					// ��������� ����� ��� ����. ���� ��� - ������ CRPT
				CASE Empty(cCurl:=::MAggregate(cMark));	kErr := 1	// ������ �����
				CASE cCurl = "[]";			kErr := 2	// ����� ����������������, �� �� �����������
				CASE "curl:" $ cCurl;			kErr := 3	// �������� � curl/������
				CASE '"code":404' $ cCurl;		kErr := 4	// ��� �� ������
				CASE "<title>50" $ cCurl;		kErr := 5	// Bad gateway, Service unavailable, Internal error...
				CASE "error" $ Lower(cCurl);		kErr := 6	// ���� ������
				CASE hb_jsonDecode(cCurl, @aCurl, hb_cdpSelect()) = 0
									kErr := 7	// ������ ������� ������
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
		aMarks[jMark,6] := kErr						// ��� ������, ���� ����

		IF !Empty(aCurl)
			aMarks[jMark, 4] := Len(aCurl)			// � ����� ������� ����� �� �������
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
METHOD Authorize() CLASS oCrpt	// ����������� � CRPT
	LOCAL a, r:=.T., cCurl, hCurl, cData, cJson
	LOCAL oError

	BEGIN SEQUENCE WITH {|oError| ErrMacro(oError)}

		::token := NIL
		IF Empty(::oCurl);					BREAK "cUrl �� ��������";	ENDIF
		::oCurl:aDefOptions := {}

// ������ ���������� ����� ��� ��������� ������
		IF Empty(cCurl := ::oCurl:Run(::hAct["Token"]));	BREAK "������ ������� ������";	ENDIF
		IF hb_jsonDecode(cCurl, @hCurl, hb_cdpSelect()) = 0;	BREAK "������ ������� ������";	ENDIF
		IF IsNil(hb_HGetDef(hCurl, "uuid")) .OR.;
		   IsNil(hb_HGetDef(hCurl, "data"))
			BREAK "������ �������"
		ENDIF

// ����������� � ������ ������
		cData := hCurl["data"]
		hCurl["data"] := SignText(hb_strToUTF8(cData), ::oCert, .F., ::keyPin, ::iMode)	// Attached
		cJson := hb_jsonEncode(hCurl)
		IF ::lCurlExe						// �������� ���������� curl.exe
			cCurl := ::oCurl:Run(::hAct["Auth"],, cJson)
		ELSE							// �������� ���������� curl_easy
			a := {	{HB_CURLOPT_HTTPHEADER, {"content-type: application/json;charset=UTF-8"}},;
				{HB_CURLOPT_POST, 1}, ;							// Specify the POST data
				{HB_CURLOPT_POSTFIELDS, cJson}	}
			cCurl := ::oCurl:Run(::hAct["Auth"], a)
		ENDIF
		IF Empty(cCurl);		BREAK "������ ������";		ENDIF
		IF "error" $ Lower(cCurl) .OR. !("token" $ cCurl)
			LogIt("crpt.txt", "Error: " + hb_jsonEncode(hCurl) + CRLF + cCurl)
			BREAK cCurl
		ENDIF
		LogIt("crpt.txt", "OK: " + cCurl)
		IF hb_jsonDecode(cCurl, @hCurl, hb_cdpSelect()) = 0;	BREAK "������ ������� ������";	ENDIF
		::token := hCurl["token"]
		r := !Empty(::token)
	RECOVER USING oError
		IF !EMPTY(oError);	r := YesErr("Authorize", oError);	ENDIF
	END
	RETURN r

//---------- oCrpt:Close ----------------------------------------------------------------------------------------------------------
METHOD Close() CLASS oCrpt		// Close session
	::oCert := NIL			// Sic!!! ��� �����, ���� ::oCert ������, ��� ������� � ACCESS VIOLATION
	IF !Empty(::oUtm);	::oUtm:Close();		ENDIF
	IF !Empty(::oCurl);	::oCurl:Close();	ENDIF
	::outLog(2, "Session closed")
	::lOpened := .F.
	RETURN SELF

//---------- oCrpt:DokList ------------------------------------------------------------------------------------------------------
METHOD DList(cAction) CLASS oCrpt	// ������ �������� ���������� CRPT
	LOCAL a, cCurl, oError

	BEGIN SEQUENCE WITH {|oError| ErrMacro(oError)}

//curl 'https://ismp.crpt.ru/api/v3/facade/doc/listV2?limit=10&order=DESC
//&orderColumn=docDate&did=623136d3-7a9b-40c9-8ce3-8091e41f83aa&orderedColumnValue=2019-01-28T09:30:40.136Z
//&pageDir=NEXT' -H 'content-type:application/json' -H 'Authorization: Bearer <>'

// curl '<url ������>/api/v3/true-api/doc/listV2?limit=10&order=DESC&orderColumn=docDate&did=623136d3-7a9b-40c9-8ce3-8091e41f83aa&orderedColumnValue=2019-01-28T09:30:40.136Z&pageDir=NEXT' -H 'content-type: application/json' -H 'Authorization: Bearer <�����>'

// https://int.edo.crpt.tech/api/v1/outgoing-documents
// curl --location --request GET 'https://int.edo.crpt.tech/api/v1/outgoing-documents' \ --header 'authorization: Bearer eyJhbGciOiJIUzI1NiIsI...SpRMX7xBW-zJrUMZ7dLhytbcgmTSSI1ZrHorbb8'

		IF IsNil(cAction);	cAction := "IDList";	ENDIF
		IF ::lCurlExe						// �������� ���������� curl.exe
			cCurl := ::oCurl:Run(::hAct[cAction], ::token)
		ELSE							// �������� ���������� curl_easy
			a := {	{HB_CURLOPT_HTTPHEADER, {"content-type: application/json"},;
							{"Authorization: Bearer " + ::token}}}
			cCurl := ::oCurl:Run(::hAct[cAction], a)
		ENDIF
		IF Empty(cCurl);		BREAK "������ �������";		ENDIF
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
METHOD DParse(cFile) CLASS oCrpt	// ������ ��������� ��������� �� ����� cFile, �������� ������ ����� � ������ � oUTM
	LOCAL a, i, j, r:=.T., cMarks := "", oTabl, aTovs, aUpaks, cNomStr, aMarks, oXml, aInfPol, oDopSved, cMark, cType
	LOCAL savInterface, oError

	BEGIN SEQUENCE WITH {|oError| ErrMacro(oError)}
		IF !(Upper(Right(cFile,4)) = ".XML");		cFile += ".xml";		ENDIF
		IF !File(cFile);				BREAK "��� �����";		ENDIF
		oXml := oXML{,, cFile}
		IF Empty(oXml);					BREAK "������ ��������";	ENDIF
		IF Empty(oTabl := oXml["...����������"]);	BREAK "��� ��������� �����";	ENDIF
		IF Empty(aTovs := oTabl:GetSons("�������"));	BREAK "��� �������";		ENDIF
		aInfPol := oXml:FindNodes("������������=")		// ������ �� ����� ���������� �����
		
		FOR i:=1 TO Len(aTovs)
			aMarks := {}
			cNomStr := aTovs[i,"������="]
//			IF !Empty(oUpaks := aTovs[i, "...���������������"]) .AND. !Empty(aUpaks := oUpaks:GetSons("�������"))
			IF !Empty(oDopSved := aTovs[i, "����������"])
				IF !Empty(aUpaks := oDopSved:FindNodes("�������"))		// ��� �������� ������������� �����: ����������� � �������
					IF IsNil(savInterface)			
						savInterface := ::SaveInterface()
						::SetInterface(::cMInterface)	
						IF !::Authorize();	BREAK "������ ����������";	ENDIF
					ENDIF
					FOR j:=1 TO Len(aUpaks)
						::Aggregate(aUpaks[j], cNomStr, aMarks)
					NEXT
				ENDIF
				IF !Empty(aUpaks := oDopSved:FindNodes("���"))			// ��� ��������� ������������� �����: �� ������������ � �������, ������ ��������� ������
					FOR j:=1 TO Len(aUpaks)
						a := NormBar(XML2String(aUpaks[j]), 1)			// ��������� ������
						cMark := a[1]
						cType := a[2]						// ��� �����
						IF Empty(cType) .OR. cType = "��";	cType := "��";	ENDIF	// ����������� ����������, Normbar ����� ���������� ��� ��, �� ����� ������� � ��� ���� �� �����
						AAdd(aMarks, {cNomStr, cType, cMark, 1, TabMrc(cMark), 0})	// tovId, ��/��, �����, �������������������, ���, err
					NEXT
				ENDIF
			ENDIF
			FOR j:=1 TO Len(aMarks)		// {cId, cType, cMark, 0, TabMrc(cMark), 0}) tovId, ��/��, �����, �������������������, ���, err
				cMarks +=	aMarks[j,1] + " " + ;		// tovId
						aMarks[j,2] + " " + ;		// ��/��/��
						aMarks[j,3] + " " + ;		// �����
						NTrim(aMarks[j,4]) + " " + ;	// ����� ��������
						NTrim(aMarks[j,5],2) + " " + ;	// ���
						NTrim(aMarks[j,6]) + CRLF	// ��� ������ (��, Utm:updTov())
			NEXT
		NEXT

// ����������� � UTM

		IF !Empty(::oUtm)
			IF !::oUtm:EdoAppend(cFile, .F., aInfPol, cMarks);	BREAK "�������� �����������";	ENDIF
		ENDIF

	RECOVER USING oError
		IF ValType(oError) = "C";	oError += " " + cFile;		ENDIF
		IF !EMPTY(oError);		r := YesErr("DParse", oError);	ENDIF
	END
	::RestInterface(savInterface)
	RETURN r

//---------- oCrpt:MAggregate ------------------------------------------------------------------------------------------------------
METHOD MAggregate(cMark) CLASS oCrpt	// ������ ������������� ����� cMark
	LOCAL a, cCurl:="", oError, cJson, cAction := "Marks"
	LOCAL lPost := ("POST" $ ::hAct[cAction, 2])

	BEGIN SEQUENCE WITH {|oError| ErrMacro(oError)}
		IF lPost
			cJson := '["' + cMark + '"]'
		ELSE
			cMark := urlEncode(cMark)
		ENDIF
	        
		DO CASE
			CASE ::lCurlExe .AND. lPost				// �������� ���������� curl.exe, POST
				cCurl := ::oCurl:Run(::hAct[cAction], {::token, cMark}, cJson)
	        
			CASE !::lCurlExe .AND. lPost				// �������� ���������� curl_easy, POST
				a := {	{HB_CURLOPT_HTTPHEADER, {"content-type: application/json;charset=UTF-8"},;
								{"Authorization: Bearer " + ::token}},;
					{HB_CURLOPT_POST, 1}, ;			// Specify the POST data
					{HB_CURLOPT_POSTFIELDS, cJson}	}
				cCurl := ::oCurl:Run(::hAct[cAction], a)
	        
			CASE ::lCurlExe .AND. !lPost				// �������� ���������� curl.exe, GET
				cCurl := ::oCurl:Run(::hAct[cAction], {::token, cMark})
	        
			CASE !::lCurlExe .AND. !lPost				// �������� ���������� curl_easy, GET
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
METHOD New() CLASS oCrpt	// �������� �������: ��� ����������, �� ������ OLE
	AAdd(::aSessions, SELF)
	::handle := ALen(::aSessions)
	::cPath := hb_dirBase()
	::intCp := hb_cdpOs()
	hb_cdpSelect(::intCp)		// �� ���������
	LogStd(::selfName + " V.M " + NTrim(::niSys) + "." + NTrim(::niRelease))	
	RETURN SELF

//---------- oCrpt:Open ----------------------------------------------------------------------------------------------------------
METHOD Open() CLASS oCrpt	// �������� ������, �� ������ OLE

	LOCAL cFile, oError

	BEGIN SEQUENCE WITH {|oError| ErrMacro(oError)}

		DefPub("cSysCtl", "")

		IF ::lOpened;				BREAK;				ENDIF
		IF !File(cFile := ::selfName + ".ini");	BREAK cFile + " �� ������";	ENDIF
		IF !Empty(::aIni := hb_iniRead(cFile)["MAIN"])
			::iLog		:= Val(hb_HGetDef(::aIni, "iLog",	NTrim(::iLog)))		// ������� ��������� � Log
			::iMode		:= Val(hb_HGetDef(::aIni, "iMode",	NTrim(::iMode)))	// ������ ������
			::Limit		:= Val(hb_HGetDef(::aIni, "Limit",	NTrim(::Limit)))	// �������� ����� �������
			::dOffset	:= Val(hb_HGetDef(::aIni, "dOffset",	NTrim(::dOffset)))	// ��������� ���� ������� = Date() + ::dOffset
			::iTimeOut	:= Val(hb_HGetDef(::aIni, "iTimeOut",	NTrim(::iTimeOut)))	// TimeOut � ���. �������� ������ �� ������� ������
			::iInterval	:= Val(hb_HGetDef(::aIni, "iInterval",	NTrim(::iInterval)))	// �������� � ���. ����������� ������ �� ������� ������

			::cThumbprint	:= hb_HGetDef(::aIni, "cThumbprint",	::cThumbprint)	// Thumbprint ����������� ��� �������
			::keyPin	:= hb_HGetDef(::aIni, "keyPin",		::keyPin)	// PIN �������
			M->cSysCtl	:= hb_HGetDef(::aIni, "cSysCtl",	M->cSysCtl)	// ���� � ��
			::TLScert	:= hb_HGetDef(::aIni, "TLScert",	::TLScert)	// ���������� TLS/SSL
			::cDInterface	:= hb_HGetDef(::aIni, "cDInterface",	::cDInterface)	// ����������� ��������� ��� ��������� ����������
			::cMInterface	:= hb_HGetDef(::aIni, "cMInterface",	::cMInterface)	// ����������� ��������� ��� ������������� �����
		ENDIF

// DataBase
		IF !Empty(M->cSysCtl)				// ���� ��
			IF Right(M->cSysCtl,1) # "\";	M->cSysCtl += "\";	ENDIF
			SetAds()
			::oUtm := UTM{}
		ENDIF
// Curl
		::lCurlExe := IsSet(::iMode,8)			// libcurl/curl.exe
		::SetInterface()				// ��������� ���������� ::hAct ��� ������������ ������ ���������� ��� ������ ������� �� ::Actions
		IF Empty(::oCurl);	::oCurl := oCurl{::curlUrl, ::lCurlExe, ::TLScert, ::iLog};	ENDIF
		IF Empty(::oCurl);	BREAK "������ �������� cUrl";		ENDIF

// �������� ����������� ��� ��������
		IF Empty(::oCert := GetCert(::cThumbPrint));		BREAK;	ENDIF		// ���������� �� ���������
		IF !(StrTran(::cThumbPrint," ","") == StrTran(::oCert:Thumbprint," ","")) 	// ���������� ��������
			::aIni["cThumbprint"] := ::oCert:Thumbprint				// ������� .ini
			hb_iniWrite(::selfName + ".ini", { "MAIN" => ::aIni })
		ENDIF

		::lOpened := .T.

	RECOVER USING oError
		::lOpened := YesErr(::selfName, oError)
	END

	IF ::lOpened;	::outLog(2, "Session opened");	ENDIF

	RETURN ::lOpened

//---------- oCrpt:outLog ----------------------------------------------------------------------------------------------------------
METHOD outLog(iFlag, cMsg, cAdd) CLASS oCrpt		// ����� ���������
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
METHOD RestInterface(savInterface) CLASS oCrpt	// �������������� ���������� �������� ����������
	IF !Empty(savInterface)
		::SetInterface(savInterface[1])
		::token := savInterface[2]
	ENDIF
	RETURN SELF

//---------- oCrpt:SaveInterface -------------------------------------------------------------------------------------
METHOD SaveInterface() CLASS oCrpt	// ���������� ���������� �������� ����������
	RETURN {::cInterface, ::token}

//---------- oCrpt:SetInterface -------------------------------------------------------------------------------------
METHOD SetInterface(cInterface) CLASS oCrpt	// ��������� ��������� ::hAct ��� ������������ ������ ���������� ��� 
	LOCAL i, j, c, c2			// ������ ������� �� ::Actions � �������� ������ ��������� �����������

	IF Empty(cInterface);	cInterface := ::cDInterface;	ENDIF
	IF IsNil(::aInterfaces)
		::aInterfaces := ""			// ������ ��������� ����������� �� ��������� � .ini curlUrlX
		FOR j := Asc("A") TO Asc("Z")
			c := Chr(j)
			IF hb_HHasKey(::aIni, "curlUrl" + c);	::aInterfaces += c;	ENDIF
		NEXT
	ENDIF
	IF !(::cInterface == cInterface)
		::cInterface := cInterface
		::token := ""					// ���� �� ����� � ������ ����������
		::cFIDir := hb_HGetDef(::aIni, "cFIDir" + cInterface, "")
		::curlUrl := ::aIni["curlUrl" + cInterface]	// ������� url ������ ����������
		IF !Empty(::oCurl)				// ���� ����� �������� ��� � oCurl
			::oCurl:baseUrl := ::curlUrl
		ENDIF
		::hAct	  := { => }				// ��������� �������: {{���.url, ������ curl.exe}}
		FOR i:=1 TO Len(::Actions)
			c := hb_HGetDef(::aIni, "curl" + ::Actions[i] + cInterface)
			IF !IsNil(c)
				c := AllTrim(c)			// �������� ��������� �� .ini
				c2 := ""
				IF (j := At(",", c)) > 0
					c2 := AllTrim(Substr(c, j+1))
					c := AllTrim(Left(c, j-1))
				ENDIF
				::hAct[::Actions[i]] := {c, c2}	// ��������� �������: {���.url, ������ curl.exe}
			ENDIF
		NEXT
	ENDIF
	RETURN .T.

