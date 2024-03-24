/*--------------------------------------------------------------------------------------------------------------*/
#include "hbvo.ch"
/*---------- UTM: --------------------------------------------------------------02/06/20--------*/
CLASS UTM INHERIT MyServer
	PROTECT lastAdded /*AS LONG*/		// RecNo последней добавленной записи в UTM

	METHOD EdoAppend(cFile, lOut, aInfPol, cTxt)	// Регистрация транзакции в журнале UTMJ
	METHOD EdoParse(cFile)				// Разбор имени файла ЭДО
	METHOD New(cFile, cInd, xRdd, lShared, lRO)
ENDCLASS

/*---------- UTM:EdoParse ---------------------------------------------------02/06/20--------*/
METHOD EdoParse(cFile) CLASS UTM	// Разбор имени файла ЭДО
			// cFile	Стандартное имя файла: ON_NSCHFDOPPRMARK_FromID_ToId_Date_DocID
			// Возвращает: {	Тип файла eg ON_NSCHFDOPPRMARK,
			//			Дата файла ГГГГММДД eg 20200514
			// 			ID документа (последние 36 символов), eg 3440B5E2-B3EA-1EDA-A5BF-7C6818383F02	}
	LOCAL cType:="", cDate:="", cId:=""
	LOCAL cFName := ParseName(cFile, 4)[2]	// Имя файла
	LOCAL aName := hb_aTokens(cFName, "_")

	IF Len(aName) >= 6 .AND. AScan({"ON", "DP"}, aName[1]) > 0
		cType := aName[1] + "_" + aName[2]	// Тип файла eg ON_NSCHFDOPPRMARK
		cDate := aName[5]			// Дата файла ГГГГММДД eg 20200514
		cId   := aName[6]			// ID документа (последние 36 символов)
	ENDIF
	RETURN {cType, cDate, cId}

/*---------- UTM:EdoAppend ---------------------------------------------------02/06/20--------*/
METHOD EdoAppend(cFile, lOut, aInfPol, cTxt) CLASS UTM	// Регистрация транзакции в журнале UTMJ
				// cFile	Стандартное имя файла: ON_NSCHFDOPPRMARK_FromID_ToId_Date_DocID
				// lOut		Входной/выходной
				//// iAns		Подразделение
				// cTxt		Текст разобранных марок, если есть
				// aInfPol	{ID документов, к которым относится данный, для создания связи по n_dk}
				// В cCurl:	edo\ИО\Тип\Дата\ID из названия файла, где:
				// 			ИО = in/out
				//			Тип = ON_NSCHFDOPPRMARK, ...
				//			Дата = ГГГГММВВ eg 20200514
				//			ID = ID документа (последние 36 символов), eg 3440B5E2-B3EA-1EDA-A5BF-7C6818383F02

	LOCAL i, r := .T., cCurl, oError, iN_dk := 0, nFile, cFileO, iUtmNumb, iAns:=0, cRefId, cInfPol
	LOCAL aName := ::EdoParse(cFile)
//	LOCAL oldOrd := ::WhatOrd("utmcomm")	// Этого Индекса может и не быть
	LOCAL oldOrd := ::WhatOrd("utmnumb")

	IF IsNil(lOut);			lOut := .F.;		ENDIF
	IF IsNil(aInfPol);		aInfPol := {};		ENDIF
	IF ValType(aInfPol) # "A";	aInfPol := {aInfPol};	ENDIF
//	IF IsNil(iAns);		iAns := 0;	ENDIF	// ans не определяется из документа без _c3; Пусть кот этим занимается

	BEGIN SEQUENCE  WITH {|errobj| ErrMacro(errobj)}
		IF Empty(aName[1]);				BREAK "Неверное имя файла: "   ;	ENDIF
		IF !File(cFile);				BREAK "Файл не найден "        ;	ENDIF
		cRefId := aName[3]
		IF ::SeekOrd(cRefId, "utmcomm");		BREAK "Документ уже загружен " ;	ENDIF

		cCurl := "edo/" + IIF(lOut, "out/", "in/") + aName[1] + "/" + aName[2] + "/" + cRefId
		FOR i:=1 TO Len(aInfPol)
			cInfPol := ::EdoParse(aInfPol[i])[3]	// Ссылочный номер ранее бывшего документа
			IF !Empty(cInfPol) .AND. ::SeekOrd(cInfPol, "utmcomm")
//				cRefId := aInfPol[i]
				iN_dk := ::n_dk			// Старший документ уже был: Берем из него ссылочный номер, n_dk и ans
				IF Empty(iAns);	iAns := ::ans;	ENDIF
				EXIT
			ENDIF
		NEXT

		::GoTo(1)					// Первая запись - последний присвоенный номер файла в
		IF !::RLOCK();					BREAK "Ошибка блокировки для ";		ENDIF
		nFile := Val(AllTrim(::utmin)) + 1
		cFileO := PadL(NTrim(nFile), 8, "0")
		::utmIn := cFileO
		::Unlock()

// Сохранение файлов
		IF !FCopy(cFile, ::ownPath + cFileO + ".xml");	BREAK "Ошибка записи ";		ENDIF
		IF !Empty(cTxt);	hb_Memowrit(::ownPath + cFileO + ".txt", cTxt);		ENDIF

// Новая запись
		::WhatOrd("utmnumb")
		::GoBottom()
		iUtmNumb := ::utmNumb + 1

		IF !::Append();					BREAK "Ошибка Append ";		ENDIF
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
	LOCAL aFields := {	{"ANS","N",5,0,NIL},;				// Подразделение
				{"UTMNUMB","N",8,0,NIL},;			// Порядковый номер записи
				{"UTMCURL","C",100,0,NIL},;			// Строка Curl
				{"UTMOUT", "C",8,0,NIL},;			// Имя исходящего файла XML
				{"UTMIN", "C",8,0,NIL},;			// Имя входящего файла XML. Для 1 записи файла - последний присвоенный номер файла
				{"UTMDATE","D",8,0,NIL},;			// Дата
				{"UTMTIME","C",8,0,NIL},;			// Время
				{"UTMCOMM","C",40,0,NIL},;			// Комментарий
				{"N_DK","N",12,0,NIL},;				// N_DK документа
				{"UTMSTATE","C",20,0,NIL}	}		// Состояние
	LOCAL aIndexes := {"UTMNUMB", "N_DK", "UTMCOMM"}
	
	IF IsNil(cFile) .AND. !Empty(cSysCtl);	cFile := cSysCtl + "utm\utmj.dbf";	ENDIF
	IF !Empty(cFile)
		lNew := !File(cFile)
		dbfCreate(cFile, aFields, aIndexes, 4)	// Проверить индексы и создать недостающие. На результат плюем - есть SeekOrd
		::Super:New(cFile, cInd, xRdd, lShared, lRO)
		IF lNew .AND. ::Append()
			::utmDate := Date()
			::utmTime := Time()
			::utmState := "З"
			::Unlock()
		ENDIF
	ENDIF
	RETURN SELF

