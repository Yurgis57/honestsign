/*--------------------------------------------------------------------------------------------------------------*/
#include "hbvo.ch"
/*---------- UTM: --------------------------------------------------------------02/06/20--------*/
CLASS UTM INHERIT MyServer
	PROTECT lastAdded /*AS LONG*/		// RecNo ��������� ����������� ������ � UTM

	METHOD EdoAppend(cFile, lOut, aInfPol, cTxt)	// ����������� ���������� � ������� UTMJ
	METHOD EdoParse(cFile)				// ������ ����� ����� ���
	METHOD New(cFile, cInd, xRdd, lShared, lRO)
ENDCLASS

/*---------- UTM:EdoParse ---------------------------------------------------02/06/20--------*/
METHOD EdoParse(cFile) CLASS UTM	// ������ ����� ����� ���
			// cFile	����������� ��� �����: ON_NSCHFDOPPRMARK_FromID_ToId_Date_DocID
			// ����������: {	��� ����� eg ON_NSCHFDOPPRMARK,
			//			���� ����� �������� eg 20200514
			// 			ID ��������� (��������� 36 ��������), eg 3440B5E2-B3EA-1EDA-A5BF-7C6818383F02	}
	LOCAL cType:="", cDate:="", cId:=""
	LOCAL cFName := ParseName(cFile, 4)[2]	// ��� �����
	LOCAL aName := hb_aTokens(cFName, "_")

	IF Len(aName) >= 6 .AND. AScan({"ON", "DP"}, aName[1]) > 0
		cType := aName[1] + "_" + aName[2]	// ��� ����� eg ON_NSCHFDOPPRMARK
		cDate := aName[5]			// ���� ����� �������� eg 20200514
		cId   := aName[6]			// ID ��������� (��������� 36 ��������)
	ENDIF
	RETURN {cType, cDate, cId}

/*---------- UTM:EdoAppend ---------------------------------------------------02/06/20--------*/
METHOD EdoAppend(cFile, lOut, aInfPol, cTxt) CLASS UTM	// ����������� ���������� � ������� UTMJ
				// cFile	����������� ��� �����: ON_NSCHFDOPPRMARK_FromID_ToId_Date_DocID
				// lOut		�������/��������
				//// iAns		�������������
				// cTxt		����� ����������� �����, ���� ����
				// aInfPol	{ID ����������, � ������� ��������� ������, ��� �������� ����� �� n_dk}
				// � cCurl:	edo\��\���\����\ID �� �������� �����, ���:
				// 			�� = in/out
				//			��� = ON_NSCHFDOPPRMARK, ...
				//			���� = �������� eg 20200514
				//			ID = ID ��������� (��������� 36 ��������), eg 3440B5E2-B3EA-1EDA-A5BF-7C6818383F02

	LOCAL i, r := .T., cCurl, oError, iN_dk := 0, nFile, cFileO, iUtmNumb, iAns:=0, cRefId, cInfPol
	LOCAL aName := ::EdoParse(cFile)
//	LOCAL oldOrd := ::WhatOrd("utmcomm")	// ����� ������� ����� � �� ����
	LOCAL oldOrd := ::WhatOrd("utmnumb")

	IF IsNil(lOut);			lOut := .F.;		ENDIF
	IF IsNil(aInfPol);		aInfPol := {};		ENDIF
	IF ValType(aInfPol) # "A";	aInfPol := {aInfPol};	ENDIF
//	IF IsNil(iAns);		iAns := 0;	ENDIF	// ans �� ������������ �� ��������� ��� _c3; ����� ��� ���� ����������

	BEGIN SEQUENCE  WITH {|errobj| ErrMacro(errobj)}
		IF Empty(aName[1]);				BREAK "�������� ��� �����: "   ;	ENDIF
		IF !File(cFile);				BREAK "���� �� ������ "        ;	ENDIF
		cRefId := aName[3]
		IF ::SeekOrd(cRefId, "utmcomm");		BREAK "�������� ��� �������� " ;	ENDIF

		cCurl := "edo/" + IIF(lOut, "out/", "in/") + aName[1] + "/" + aName[2] + "/" + cRefId
		FOR i:=1 TO Len(aInfPol)
			cInfPol := ::EdoParse(aInfPol[i])[3]	// ��������� ����� ����� ������� ���������
			IF !Empty(cInfPol) .AND. ::SeekOrd(cInfPol, "utmcomm")
//				cRefId := aInfPol[i]
				iN_dk := ::n_dk			// ������� �������� ��� ���: ����� �� ���� ��������� �����, n_dk � ans
				IF Empty(iAns);	iAns := ::ans;	ENDIF
				EXIT
			ENDIF
		NEXT

		::GoTo(1)					// ������ ������ - ��������� ����������� ����� ����� �
		IF !::RLOCK();					BREAK "������ ���������� ��� ";		ENDIF
		nFile := Val(AllTrim(::utmin)) + 1
		cFileO := PadL(NTrim(nFile), 8, "0")
		::utmIn := cFileO
		::Unlock()

// ���������� ������
		IF !FCopy(cFile, ::ownPath + cFileO + ".xml");	BREAK "������ ������ ";		ENDIF
		IF !Empty(cTxt);	hb_Memowrit(::ownPath + cFileO + ".txt", cTxt);		ENDIF

// ����� ������
		::WhatOrd("utmnumb")
		::GoBottom()
		iUtmNumb := ::utmNumb + 1

		IF !::Append();					BREAK "������ Append ";		ENDIF
		::utmNumb := iUtmNumb
		IF lOut
			::utmOut := cFileO
		ELSE
			::utmIn := cFileO
		ENDIF
		::utmDate := Date()
		::utmTime := Time()
		::ans := iAns
		::n_dk := iN_dk
		::utmCurl := cCurl
		::utmcomm := cRefId
		::Unlock()
		::lastAdded := ::RecNo

	RECOVER USING oError
		IF ValType(oError) = "C";	oError += cFile;			ENDIF
		IF !EMPTY(oError);		r := YesErr("EdoAppend", oError);	ENDIF
	END
	::SetOrder(oldOrd)
	RETURN r
	
/*---------- UTM:Init ----------------------------------------------------------02/06/20--------*/
METHOD New(cFile, cInd, xRdd, lShared, lRO) CLASS UTM
        LOCAL lNew, cSysCtl := DefPub("cSysCtl", "")
	LOCAL aFields := {	{"ANS","N",5,0,NIL},;				// �������������
				{"UTMNUMB","N",8,0,NIL},;			// ���������� ����� ������
				{"UTMCURL","C",100,0,NIL},;			// ������ Curl
				{"UTMOUT", "C",8,0,NIL},;			// ��� ���������� ����� XML
				{"UTMIN", "C",8,0,NIL},;			// ��� ��������� ����� XML. ��� 1 ������ ����� - ��������� ����������� ����� �����
				{"UTMDATE","D",8,0,NIL},;			// ����
				{"UTMTIME","C",8,0,NIL},;			// �����
				{"UTMCOMM","C",40,0,NIL},;			// �����������
				{"N_DK","N",12,0,NIL},;				// N_DK ���������
				{"UTMSTATE","C",20,0,NIL}	}		// ���������
	LOCAL aIndexes := {"UTMNUMB", "N_DK", "UTMCOMM"}
	
	IF IsNil(cFile) .AND. !Empty(cSysCtl);	cFile := cSysCtl + "utm\utmj.dbf";	ENDIF
	IF !Empty(cFile)
		lNew := !File(cFile)
		dbfCreate(cFile, aFields, aIndexes, 4)	// ��������� ������� � ������� �����������. �� ��������� ����� - ���� SeekOrd
		::Super:New(cFile, cInd, xRdd, lShared, lRO)
		IF lNew .AND. ::Append()
			::utmDate := Date()
			::utmTime := Time()
			::utmState := "�"
			::Unlock()
		ENDIF
	ENDIF
	RETURN SELF

